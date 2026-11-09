import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/src/config/config.dart';
import 'package:memory_app/src/domain/game_engine.dart';
import 'package:memory_app/src/domain/game_state.dart';
import 'package:memory_app/src/domain/modes/fixed_rounds_mode.dart';

void main() {
  test('startGame waits for explicit round start', () async {
    final engine = GameEngine(
      baseConfig: GameConfig.defaults(),
      mode: FixedRoundsMode(rounds: 3),
    );

    await engine.startGame();

    expect(engine.state.phase, GamePhase.idle);
    expect(engine.state.sequence, isEmpty);

    engine.beginRound();
    expect(engine.state.phase, GamePhase.revealing);
  });

  test('fixed rounds mode ends after the last round', () {
    final mode = FixedRoundsMode(rounds: 1);
    final result = mode.onRoundEnd(GameState(roundIndex: 0));

    expect(result.continueGame, isFalse);
  });
}
