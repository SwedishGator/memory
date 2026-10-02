// GamePhase describes the current lifecycle phase of a round.
enum GamePhase { idle, revealing, guessing, roundResult, finished, paused }

// GameResult describes the outcome of a round or evaluation.
class GameResult {
  final bool continueGame;
  final bool success;

  GameResult({required this.continueGame, this.success = false});
}

// Immutable GameState representing the engine's snapshot consumed by UI.
class GameState {
  final int roundIndex; // current round (0-based)
  final int gridSize; // N for N x N grid
  final List<int> sequence; // positions to reveal this round
  final int highlightedIndex; // currently highlighted tile (-1 none)
  final int guessIndex; // next expected guess index
  final int mistakes; // total mistakes so far
  final int score; // accumulated score
  final GamePhase phase; // current phase
  final int revealDurationMs; // ms used for reveals (effective)
  final int sessionTimerRemainingMs; // session-wide timer visible to UI (ms)

  const GameState({
    this.roundIndex = 0,
    this.gridSize = 3,
    this.sequence = const [],
    this.highlightedIndex = -1,
    this.guessIndex = 0,
    this.mistakes = 0,
    this.score = 0,
    this.phase = GamePhase.idle,
    this.revealDurationMs = 1500,
    this.sessionTimerRemainingMs = 0,
  });

  GameState copyWith({
    int? roundIndex,
    int? gridSize,
    List<int>? sequence,
    int? highlightedIndex,
    int? guessIndex,
    int? mistakes,
    int? score,
    GamePhase? phase,
    int? revealDurationMs,
    int? sessionTimerRemainingMs,
  }) {
    return GameState(
      roundIndex: roundIndex ?? this.roundIndex,
      gridSize: gridSize ?? this.gridSize,
      sequence: sequence ?? this.sequence,
      highlightedIndex: highlightedIndex ?? this.highlightedIndex,
      guessIndex: guessIndex ?? this.guessIndex,
      mistakes: mistakes ?? this.mistakes,
      score: score ?? this.score,
      phase: phase ?? this.phase,
      revealDurationMs: revealDurationMs ?? this.revealDurationMs,
      sessionTimerRemainingMs: sessionTimerRemainingMs ?? this.sessionTimerRemainingMs,
    );
  }
}
