import '../config/config.dart';
import 'game_state.dart';

// GameMode: strategy interface describing mode-specific behavior.
abstract class GameMode {
  // Optional human-readable id
  String get id;

  // Called before a round starts; can return a per-round config override.
  // Allow modes to tweak per-round effective `GameConfig`. The default
  // implementation returns the provided config unchanged.
  GameConfig applyRoundStart(GameState state, GameConfig baseConfig) => baseConfig;

  // Called after a round ends so the mode can compute results or side-effects.
  GameResult onRoundEnd(GameState state) => GameResult(continueGame: true);

  // Whether the engine should continue after the latest state.
  bool shouldContinue(GameState state) => true;

  // Optional per-mode session time limit (ms). Return null for no session
  // timer. `TimedMode` will override this to enable a session timer.
  int? sessionTimeLimitMs(GameConfig baseConfig) => null;

  // Result of validating a player's guess. Modes return this to instruct
  // the engine how to update score, selections, and whether the round
  // is complete.
  // - `correct`: whether the guess was correct
  // - `roundComplete`: whether this guess completes the round
  // - `scoreDelta`: points to add (can be 0)
  // - `mistakesDelta`: mistakes to add (0 or 1)
  // - `addToSelection`: for set-match modes, whether the engine should
  //   add the tapped tile to the selected set
  // - `advanceGuessIndex`: for order-match modes, whether engine should
  //   advance the internal guess index
  GuessResult validateGuess(GameState state, int position, Set<int> selections) {
    // Default behavior: sequence order match (classic mode).
    if (state.sequence.isEmpty) return GuessResult.incorrect();
    final expectedIndex = state.guessIndex;
    if (expectedIndex < 0 || expectedIndex >= state.sequence.length) return GuessResult.incorrect();
    final expected = state.sequence[expectedIndex];
    final correct = position == expected;
    if (correct) {
      final roundComplete = expectedIndex + 1 >= state.sequence.length;
      return GuessResult(correct: true, roundComplete: roundComplete, scoreDelta: 10, mistakesDelta: 0, addToSelection: false, advanceGuessIndex: true);
    } else {
      return GuessResult.incorrect();
    }
  }
}

// A small class describing the outcome of a guess validation.
class GuessResult {
  final bool correct;
  final bool roundComplete;
  final int scoreDelta;
  final int mistakesDelta;
  final bool addToSelection;
  final bool advanceGuessIndex;
  // Optional bonus to apply when the round completes (e.g., time bonus).
  final int roundCompletionBonus;

  const GuessResult({required this.correct, required this.roundComplete, this.scoreDelta = 0, this.mistakesDelta = 0, this.addToSelection = false, this.advanceGuessIndex = false, this.roundCompletionBonus = 0});

  factory GuessResult.incorrect() => const GuessResult(correct: false, roundComplete: false, scoreDelta: 0, mistakesDelta: 1, addToSelection: false, advanceGuessIndex: false, roundCompletionBonus: 0);
}
