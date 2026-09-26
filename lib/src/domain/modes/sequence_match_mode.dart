import '../mode.dart';
import '../game_state.dart';

// SequenceMatchMode: classic mode where the player must tap tiles in the
// exact revealed order. Simple scoring: +10 per correct tap.
class SequenceMatchMode extends GameMode {
  @override
  final String id;

  SequenceMatchMode({this.id = 'sequence_match'});

  @override
  GuessResult validateGuess(GameState state, int position, Set<int> selections) {
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
