// GameScreen: top-level UI for playing a single game session.
// It wires the `GameEngine` StateNotifier to the visible grid and
// provides controls to start/stop the game.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../providers/game_providers.dart';
import '../../domain/mode.dart';
//import '../../domain/modes/fixed_rounds_mode.dart';
import '../../domain/game_state.dart';
import '../widgets/grid_widget.dart';
import 'settings_screen.dart';

// We use a FixedRoundsMode for this screen as an example.
class GameScreen extends ConsumerWidget {
  final GameMode mode;

  const GameScreen({Key? key, required this.mode}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the engine state for this mode. UI will rebuild when state changes.
    final gameState = ref.watch(gameEngineProvider(mode));

    // Access the engine notifier to send commands (startGame, handleGuess, stop).
    final engine = ref.read(gameEngineProvider(mode).notifier);

    // Conditionally show session timer widget
    final Widget sessionTimerWidget = gameState.sessionTimerRemainingMs > 0
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 6),
              Text('${(gameState.sessionTimerRemainingMs / 1000).toStringAsFixed(1)}s'),
            ],
          )
        : const SizedBox.shrink();

    // Build pause overlay widget to show when the game is paused.
    final Widget pauseOverlay = gameState.phase == GamePhase.paused
        ? Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Paused', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => engine.resume(),
                      child: const Text('Resume'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => engine.restartRound(),
                      child: const Text('Restart Round'),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Game over overlay shown when the session finishes.
    final Widget gameOverOverlay = gameState.phase == GamePhase.finished
        ? Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Game Over', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Score: ${gameState.score}', style: const TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                            engine.startGame();
                          },
                          child: const Text('Play Again'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    // Temporarily keep WillPopScope to preserve existing behavior.
    // The widget was deprecated in newer Flutter; replace with `PopScope`
    // once we confirm the target SDK and callback signature.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memory Game'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Round: ${gameState.roundIndex + 1}'),
                        Text('Score: ${gameState.score}'),
                        Text('Mistakes: ${gameState.mistakes}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    sessionTimerWidget,
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridWidget(
                        state: gameState,
                        onTileTap: (index) => engine.handleGuess(index),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                if (gameState.phase == GamePhase.idle || gameState.phase == GamePhase.finished) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                                      engine.startGame();
                                    },
                                    child: const Text('Start'),
                                  );
                                } else if (gameState.phase == GamePhase.paused) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                                      engine.resume();
                                    },
                                    child: const Text('Resume'),
                                  );
                                } else {
                                  return ElevatedButton(
                                    onPressed: () => engine.pause(),
                                    child: const Text('Pause'),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (gameState.phase == GamePhase.paused) {
                                  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                                  engine.restartRound();
                                } else {
                                  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                  engine.stop();
                                }
                              },
                              child: Text(gameState.phase == GamePhase.paused ? 'Restart' : 'Stop'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pauseOverlay,
                gameOverOverlay,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
