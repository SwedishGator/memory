import '../mode.dart';
import '../game_state.dart';
import '../../config/config.dart';

// TimedMode: similar to SequenceMatch but intended to be used with an engine
// that supports per-round timers. For now, validation follows sequence order;
// timer enforcement will be handled in the engine when implemented.
class TimedMode extends GameMode {
  @override
  final String id;
  final int timeLimitMs;

  TimedMode({this.id = 'timed', this.timeLimitMs = 5000});

  @override
  GameConfig applyRoundStart(GameState state, GameConfig baseConfig) {
    // TimedMode doesn't change the GameConfig by default. Modes that want
    // to override per-round timings can return a modified GameConfig here.
    return baseConfig;
  }

  @override
  GuessResult validateGuess(GameState state, int position, Set<int> selections) {
    // Use same validation as sequence match.
    if (state.sequence.isEmpty) return GuessResult.incorrect();
    final expectedIndex = state.guessIndex;
    if (expectedIndex < 0 || expectedIndex >= state.sequence.length) return GuessResult.incorrect();
    final expected = state.sequence[expectedIndex];
    final correct = position == expected;
    if (correct) {
      final roundComplete = expectedIndex + 1 >= state.sequence.length;
      var bonus = 0;
      if (roundComplete) {
        // award a time bonus: floor(remainingMs / 100)
        bonus = (state.sessionTimerRemainingMs ~/ 100);
      }
      return GuessResult(correct: true, roundComplete: roundComplete, scoreDelta: 15, mistakesDelta: 0, addToSelection: false, advanceGuessIndex: true, roundCompletionBonus: bonus);
    } else {
      return GuessResult.incorrect();
    }
  }
}
