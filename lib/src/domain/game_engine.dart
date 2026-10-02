import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config.dart';
import 'game_state.dart';
import 'mode.dart';

// GameEngine implemented as a StateNotifier so it integrates cleanly with
// Riverpod. It manages round sequencing, reveal timing, guess validation,
// scoring, and delegates continuation logic to a GameMode strategy.
class GameEngine extends StateNotifier<GameState> {
  final GameConfig baseConfig;
  final GameMode mode;
  GameConfig? _lastEffectiveConfig;
  Timer? _sessionTicker;
  int _sessionRemainingMs = 0;

  // Internal sequence and guess tracking
  List<int> _currentSequence = [];
  int _currentGuessIndex = 0;
  Set<int> _currentSelection = {};
  bool _isRevealing = false;

  GameEngine({required this.baseConfig, required this.mode})
      : super(GameState(
          roundIndex: 0,
          gridSize: baseConfig.startGridSize,
          revealDurationMs: baseConfig.revealDurationMs,
          phase: GamePhase.idle,
        ));

  // Start a full game session.
  Future<void> startGame() async {
    state = state.copyWith(
      roundIndex: 0,
      gridSize: baseConfig.startGridSize,
      mistakes: 0,
      score: 0,
      phase: GamePhase.idle,
      guessIndex: 0,
    );
    // Initialize session timer only if the current mode enables it.
    final ms = mode.sessionTimeLimitMs(baseConfig);
    if (ms != null && ms > 0) {
      _sessionRemainingMs = ms;
      state = state.copyWith(sessionTimerRemainingMs: _sessionRemainingMs);
      _startSessionTicker();
    } else {
      _sessionRemainingMs = 0;
      state = state.copyWith(sessionTimerRemainingMs: 0);
      _sessionTicker?.cancel();
    }
    await startRound();
  }

  void _startSessionTicker() {
    _sessionTicker?.cancel();
    // Ticker granularity of 200ms for UI responsiveness.
    _sessionTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (state.phase == GamePhase.guessing) {
        _sessionRemainingMs = (_sessionRemainingMs - 200).clamp(0, 1 << 31);
        state = state.copyWith(sessionTimerRemainingMs: _sessionRemainingMs);
        if (_sessionRemainingMs <= 0) {
          // Session time expired — end current round as failure.
          _onRoundComplete(success: false);
        }
      }
    });
  }

  // Start a single round: generate sequence, reveal it, then switch to guessing.
  Future<void> startRound() async {
    final effectiveConfig = mode.applyRoundStart(state, baseConfig);
    _lastEffectiveConfig = effectiveConfig;

    // Determine grid size for this round. Modes can override `startGridSize`
    // and `gridIncrement` via the returned effectiveConfig. Grid grows by
    // `gridIncrement` per successful round index.
    final gridSizeForRound = (effectiveConfig.startGridSize + (state.roundIndex * effectiveConfig.gridIncrement)).clamp(effectiveConfig.startGridSize, effectiveConfig.maxGridSize);
    final gridCells = gridSizeForRound * gridSizeForRound;

    // Sequence length grows with roundIndex using effectiveConfig.
    final seqLen = effectiveConfig.startGridSize + state.roundIndex * effectiveConfig.gridIncrement;
    _currentSequence = _generateSequence(seqLen, gridCells);
    _currentGuessIndex = 0;
    _currentSelection = {};

    // Update state with new sequence, grid size and reveal duration
    state = state.copyWith(
      sequence: List<int>.from(_currentSequence),
      guessIndex: 0,
      phase: GamePhase.revealing,
      revealDurationMs: effectiveConfig.revealDurationMs,
      gridSize: gridSizeForRound,
    );

    // Reveal sequence to player
    await _revealSequence(_currentSequence, effectiveConfig.revealDurationMs);

    // After revealing, switch to guessing phase — but if the user paused
    // during the reveal, respect the paused state and do not override it.
    if (state.phase != GamePhase.paused) {
      state = state.copyWith(phase: GamePhase.guessing, highlightedIndex: -1);
    } else {
      // Ensure UI doesn't show a lingering highlight while paused.
      state = state.copyWith(highlightedIndex: -1);
    }
  }

  // Generate a random sequence of unique positions (no duplicates).
  List<int> _generateSequence(int length, int gridCells) {
    final rand = Random();
    final available = List<int>.generate(gridCells, (i) => i);
    final seq = <int>[];
    for (int i = 0; i < length && available.isNotEmpty; i++) {
      final idx = rand.nextInt(available.length);
      seq.add(available.removeAt(idx));
    }
    return seq;
  }

  // Reveal each index with delays; updates `highlightedIndex` in state.
  Future<void> _revealSequence(List<int> sequence, int revealMs) async {
    _isRevealing = true;
    for (final idx in sequence) {
      if (!_isRevealing) break;
      state = state.copyWith(highlightedIndex: idx);
      await Future.delayed(Duration(milliseconds: revealMs));
      state = state.copyWith(highlightedIndex: -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _isRevealing = false;
  }

  // Handle a player's guess; returns true if guess was correct.
  bool handleGuess(int position) {
    if (state.phase != GamePhase.guessing) return false;
    // Delegate validation to the active mode.
    final result = mode.validateGuess(state, position, _currentSelection);

    // Apply score and mistakes deltas.
    var newScore = state.score + result.scoreDelta;
    var newMistakes = state.mistakes + result.mistakesDelta;

    // Update selection or guess index depending on mode instructions.
    if (result.addToSelection) {
      _currentSelection = Set<int>.from(_currentSelection)..add(position);
    }
    if (result.advanceGuessIndex && result.correct) {
      _currentGuessIndex++;
    }

    // If the round completes, include any round completion bonus.
    var finalScore = newScore;
    if (result.roundComplete) {
      finalScore = finalScore + result.roundCompletionBonus;
    }

    state = state.copyWith(score: finalScore, mistakes: newMistakes, guessIndex: _currentGuessIndex);

    // If the mode reports the round complete, notify accordingly.
    if (result.roundComplete) {
      _onRoundComplete(success: result.correct);
    } else if (!result.correct) {
      // If incorrect and mode decides game should stop, end round.
      final modeResult = mode.onRoundEnd(state);
      if (!modeResult.continueGame) {
        _onRoundComplete(success: false);
      }
    }

    return result.correct;
  }

  // Called when round completes to advance or finish the game.
  Future<void> _onRoundComplete({required bool success}) async {
    state = state.copyWith(phase: GamePhase.roundResult);
    final result = mode.onRoundEnd(state);
    if (!result.continueGame) {
      state = state.copyWith(phase: GamePhase.finished);
      _sessionTicker?.cancel();
      return;
    }

    // Prepare next round: increase roundIndex and maybe grid size.
    final nextRound = state.roundIndex + 1;
    var nextGrid = state.gridSize;
    final cfg = _lastEffectiveConfig ?? baseConfig;
    if (success) {
      nextGrid = (state.gridSize + cfg.gridIncrement).clamp(cfg.startGridSize, cfg.maxGridSize);
    }

    state = state.copyWith(
      roundIndex: nextRound,
      gridSize: nextGrid,
      phase: GamePhase.idle,
      guessIndex: 0,
    );

    // small delay before starting the next round automatically
    await Future.delayed(const Duration(milliseconds: 600));
    await startRound();
  }

  // Stop any active reveal and mark finished.
  void stop() {
    _isRevealing = false;
    state = state.copyWith(phase: GamePhase.finished, highlightedIndex: -1);
    _sessionTicker?.cancel();
  }

  // Pause the game (preserves state so it can be resumed).
  void pause() {
    if (state.phase == GamePhase.guessing || state.phase == GamePhase.revealing) {
      _isRevealing = false;
      state = state.copyWith(phase: GamePhase.paused);
    }
  }

  // Resume a paused game.
  void resume() {
    if (state.phase == GamePhase.paused) {
      // If we paused during revealing, resume revealing; otherwise go back to guessing.
      // For simplicity, resume to guessing if sequence exists.
      state = state.copyWith(phase: _currentSequence.isNotEmpty ? GamePhase.guessing : GamePhase.revealing);
    }
  }

  // Restart the current round from scratch (does not reset the entire session).
  void restartRound() async {
    // Stop any reveal/tickers and start the same round again.
    _isRevealing = false;
    _sessionTicker?.cancel();
    // Reinitialize session timer if mode enables it.
    final ms = mode.sessionTimeLimitMs(baseConfig);
    if (ms != null && ms > 0) {
      // Keep remaining ms if already running, otherwise set to default.
      _sessionRemainingMs = _sessionRemainingMs > 0 ? _sessionRemainingMs : ms;
      state = state.copyWith(sessionTimerRemainingMs: _sessionRemainingMs);
      _startSessionTicker();
    }
    // Restart the round by starting it anew but preserving roundIndex.
    await startRound();
  }

  @override
  void dispose() {
    _isRevealing = false;
    _sessionTicker?.cancel();
    super.dispose();
  }
}
