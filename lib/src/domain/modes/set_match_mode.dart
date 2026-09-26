import '../mode.dart';
import '../game_state.dart';

// SetMatchMode: the player must select the set of tiles revealed (order
// doesn't matter). The mode uses the `selections` parameter to determine
// progress.
class SetMatchMode extends GameMode {
  @override
  final String id;

  SetMatchMode({this.id = 'set_match'});

  @override
  GuessResult validateGuess(GameState state, int position, Set<int> selections) {
    // If tapped tile is not part of the target sequence, it's incorrect.
    final target = state.sequence.toSet();
    if (!target.contains(position)) return GuessResult.incorrect();

    // If already selected, ignore (not a mistake), but return incorrect=false
    if (selections.contains(position)) return const GuessResult(correct: false, roundComplete: false, scoreDelta: 0, mistakesDelta: 0, addToSelection: false, advanceGuessIndex: false);

    // Valid selection: ask engine to add it to the selection set and award points.
    final newSelections = Set<int>.from(selections)..add(position);
    final roundComplete = newSelections.length >= target.length;
    return GuessResult(correct: true, roundComplete: roundComplete, scoreDelta: 10, mistakesDelta: 0, addToSelection: true, advanceGuessIndex: false);
  }
}
