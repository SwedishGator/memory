// GameConfig: holds tunable parameters for the game and supports
// JSON (de)serialization so defaults can live in assets and users'
// overrides can be persisted.
class GameConfig {
  final int startGridSize; // starting N for an N x N grid
  final int maxGridSize; // maximum allowed grid size
  final int gridIncrement; // how much grid increases per successful round
  final int revealDurationMs; // how long tiles are revealed (ms)
  final String initialDifficulty; // e.g. 'easy', 'medium', 'hard'
  final int allowedMistakes; // mistakes allowed in modes that support it
  final String controlsPosition; // 'bottom', 'top', 'floating'
  final int sessionTimeLimitMs; // session-wide time limit used by TimedMode
  final MistakeHandling mistakeHandling; // how mistakes are shown/handled in UI

  const GameConfig({
    required this.startGridSize,
    required this.maxGridSize,
    required this.gridIncrement,
    required this.revealDurationMs,
    required this.initialDifficulty,
    required this.allowedMistakes,
    required this.controlsPosition,
    required this.sessionTimeLimitMs,
    required this.mistakeHandling,
  });

  factory GameConfig.defaults() => const GameConfig(
        startGridSize: 3,
        maxGridSize: 6,
        gridIncrement: 1,
        revealDurationMs: 1500,
        initialDifficulty: 'easy',
        allowedMistakes: 0,
      controlsPosition: 'bottom',
        sessionTimeLimitMs: 100000,
        mistakeHandling: MistakeHandling.none,
      );

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        startGridSize: json['startGridSize'] as int? ?? 3,
        maxGridSize: json['maxGridSize'] as int? ?? 6,
        gridIncrement: json['gridIncrement'] as int? ?? 1,
        revealDurationMs: json['revealDurationMs'] as int? ?? 1500,
        initialDifficulty: json['initialDifficulty'] as String? ?? 'easy',
        allowedMistakes: json['allowedMistakes'] as int? ?? 0,
      controlsPosition: json['controlsPosition'] as String? ?? 'bottom',
        sessionTimeLimitMs: json['sessionTimeLimitMs'] as int? ?? 100000,
        mistakeHandling: _parseMistakeHandling(json['mistakeHandling'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'startGridSize': startGridSize,
        'maxGridSize': maxGridSize,
        'gridIncrement': gridIncrement,
        'revealDurationMs': revealDurationMs,
        'initialDifficulty': initialDifficulty,
        'allowedMistakes': allowedMistakes,
        'controlsPosition': controlsPosition,
        'sessionTimeLimitMs': sessionTimeLimitMs,
        'mistakeHandling': mistakeHandling.name,
      };

  GameConfig copyWith({
    int? startGridSize,
    int? maxGridSize,
    int? gridIncrement,
    int? revealDurationMs,
    String? initialDifficulty,
    int? allowedMistakes,
      String? controlsPosition,
    int? sessionTimeLimitMs,
    MistakeHandling? mistakeHandling,
  }) {
    return GameConfig(
      startGridSize: startGridSize ?? this.startGridSize,
      maxGridSize: maxGridSize ?? this.maxGridSize,
      gridIncrement: gridIncrement ?? this.gridIncrement,
      revealDurationMs: revealDurationMs ?? this.revealDurationMs,
      initialDifficulty: initialDifficulty ?? this.initialDifficulty,
      allowedMistakes: allowedMistakes ?? this.allowedMistakes,
        controlsPosition: controlsPosition ?? this.controlsPosition,
        sessionTimeLimitMs: sessionTimeLimitMs ?? this.sessionTimeLimitMs,
        mistakeHandling: mistakeHandling ?? this.mistakeHandling,
    );
  }
}

  enum MistakeHandling { none, markRed, markRedDisableTap }

  MistakeHandling _parseMistakeHandling(String? s) {
    if (s == null) return MistakeHandling.none;
    return MistakeHandling.values.firstWhere((e) => e.name == s, orElse: () => MistakeHandling.none);
  }
