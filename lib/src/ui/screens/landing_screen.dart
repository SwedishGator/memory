// LandingScreen: allows selecting mode and basic difficulty/customization
// before starting a game.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/modes/fixed_rounds_mode.dart';
import '../../domain/modes/endless_mode.dart';
import '../../domain/modes/sequence_match_mode.dart';
import '../../domain/modes/set_match_mode.dart';
import '../../domain/modes/timed_mode.dart';
import '../../domain/mode.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  String _selectedMode = 'fixed';
  int _rounds = 5;

  @override
  Widget build(BuildContext context) {
    final Widget roundsWidget = _selectedMode == 'fixed'
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rounds'),
              const SizedBox(height: 8),
              Slider(value: _rounds.toDouble(), min: 1, max: 10, divisions: 9, label: '$_rounds', onChanged: (d) => setState(() => _rounds = d.toInt())),
            ],
          )
        : const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Game')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Text('Select Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _selectedMode,
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('Fixed Rounds')),
                DropdownMenuItem(value: 'endless', child: Text('Endless')),
                DropdownMenuItem(value: 'sequence', child: Text('Sequence Match')),
                DropdownMenuItem(value: 'set', child: Text('Set Match')),
                DropdownMenuItem(value: 'timed', child: Text('Timed Mode')),
              ],
              onChanged: (v) => setState(() => _selectedMode = v ?? 'fixed'),
            ),
            const SizedBox(height: 12),
            roundsWidget,
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                GameMode mode;
                switch (_selectedMode) {
                  case 'fixed':
                    mode = FixedRoundsMode(rounds: _rounds);
                    break;
                  case 'endless':
                    mode = EndlessMode(allowedMistakes: 0);
                    break;
                  case 'sequence':
                    mode = SequenceMatchMode();
                    break;
                  case 'set':
                    mode = SetMatchMode();
                    break;
                  case 'timed':
                    mode = TimedMode();
                    break;
                  default:
                    mode = FixedRoundsMode(rounds: _rounds);
                }
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(mode: mode)));
              },
              child: const Text('Start Game'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: const Text('Settings'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}
