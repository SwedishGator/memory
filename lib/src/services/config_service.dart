import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

// ConfigService: responsible for loading defaults, applying persisted
// overrides, and saving user changes. This keeps storage concerns out of
// the game logic.
class ConfigService {
  static const _prefsKey = 'game_config_overrides';

  // Load defaults from asset and merge with persisted overrides.
  Future<GameConfig> loadConfig() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/config/defaults.json');
      final Map<String, dynamic> defaults = json.decode(jsonStr);
      GameConfig config = GameConfig.fromJson(defaults);

      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefsKey)) {
        final overrideStr = prefs.getString(_prefsKey)!;
        final Map<String, dynamic> overrides = json.decode(overrideStr);
        final overrideConfig = GameConfig.fromJson(overrides);
        // Merge overrides by copying fields that differ (simple approach)
        config = config.copyWith(
          startGridSize: overrideConfig.startGridSize,
          maxGridSize: overrideConfig.maxGridSize,
          gridIncrement: overrideConfig.gridIncrement,
          revealDurationMs: overrideConfig.revealDurationMs,
          initialDifficulty: overrideConfig.initialDifficulty,
          allowedMistakes: overrideConfig.allowedMistakes,
          mistakeHandling: overrideConfig.mistakeHandling,
        );
      }

      return config;
    } catch (e) {
      // On any failure, fall back to built-in defaults.
      return GameConfig.defaults();
    }
  }

  // Persist user overrides as JSON.
  Future<void> saveOverrides(GameConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(config.toJson()));
  }

  // Clear persisted overrides.
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
