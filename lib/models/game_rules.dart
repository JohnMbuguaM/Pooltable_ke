/// Determines how a ball-jumped-off foul affects the fouling player's score.
enum BallJumpOffMode {
  /// Deduct points equal to the jumped ball's value (default).
  deduct,

  /// No score change — neutral event.
  neutral,

  /// Add points equal to the jumped ball's value.
  add,
}

class GameRules {
  final Map<int, int> ballValues;
  final int startingBall; // Which ball the game starts from
  final BallJumpOffMode ballJumpOffMode;

  // Kept for JSON backward-compatibility only — no longer shown in UI.
  final int wrongBallPenalty;
  final int scratchPenalty;
  final int carryBallPenalty;
  final int ballTouchedPenalty;
  final int ballJumpedOffPenalty;
  final int cueBallJumpedOffPenalty;

  const GameRules({
    required this.ballValues,
    this.startingBall = 3,
    this.ballJumpOffMode = BallJumpOffMode.deduct,
    this.wrongBallPenalty = 0,
    this.scratchPenalty = 0,
    this.carryBallPenalty = 0,
    this.ballTouchedPenalty = 0,
    this.ballJumpedOffPenalty = 0,
    this.cueBallJumpedOffPenalty = 0,
  });

  // Default rules (standard pool scoring)
  factory GameRules.defaults() {
    return const GameRules(
      ballValues: {
        1: 16,
        2: 17,
        3: 6,
        4: 6,
        5: 6,
        6: 6,
        7: 7,
        8: 8,
        9: 9,
        10: 10,
        11: 11,
        12: 12,
        13: 13,
        14: 14,
        15: 15,
      },
      startingBall: 3,
      ballJumpOffMode: BallJumpOffMode.deduct,
    );
  }

  /// Generate ball sequence based on starting ball.
  /// Starts from startingBall, goes up to 15, then wraps 1,2,...,startingBall-1
  List<int> get ballSequence {
    final sequence = <int>[];
    for (int i = startingBall; i <= 15; i++) {
      sequence.add(i);
    }
    for (int i = 1; i < startingBall; i++) {
      sequence.add(i);
    }
    return sequence;
  }

  // Create from JSON
  factory GameRules.fromJson(Map<String, dynamic> json) {
    BallJumpOffMode mode = BallJumpOffMode.deduct;
    if (json['ballJumpOffMode'] != null) {
      mode = BallJumpOffMode.values.firstWhere(
        (e) => e.name == json['ballJumpOffMode'],
        orElse: () => BallJumpOffMode.deduct,
      );
    }
    return GameRules(
      ballValues: (json['ballValues'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
      startingBall: json['startingBall'] as int? ?? 3,
      ballJumpOffMode: mode,
      // Legacy fields — parsed for backward compatibility but ignored in logic.
      wrongBallPenalty: json['wrongBallPenalty'] as int? ?? 0,
      scratchPenalty: json['scratchPenalty'] as int? ?? 0,
      carryBallPenalty: json['carryBallPenalty'] as int? ?? 0,
      ballTouchedPenalty: json['ballTouchedPenalty'] as int? ?? 0,
      ballJumpedOffPenalty: json['ballJumpedOffPenalty'] as int? ?? 0,
      cueBallJumpedOffPenalty: json['cueBallJumpedOffPenalty'] as int? ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'ballValues': ballValues.map((key, value) => MapEntry(key.toString(), value)),
      'startingBall': startingBall,
      'ballJumpOffMode': ballJumpOffMode.name,
    };
  }

  // Get ball value
  int getBallValue(int ballNumber) {
    return ballValues[ballNumber] ?? 0;
  }

  // Total points of all balls
  int get totalBallPoints {
    return ballValues.values.fold(0, (sum, v) => sum + v);
  }

  // Copy with
  GameRules copyWith({
    Map<int, int>? ballValues,
    int? startingBall,
    BallJumpOffMode? ballJumpOffMode,
    // Legacy fields kept so existing callers don't break.
    int? wrongBallPenalty,
    int? scratchPenalty,
    int? carryBallPenalty,
    int? ballTouchedPenalty,
    int? ballJumpedOffPenalty,
    int? cueBallJumpedOffPenalty,
  }) {
    return GameRules(
      ballValues: ballValues ?? this.ballValues,
      startingBall: startingBall ?? this.startingBall,
      ballJumpOffMode: ballJumpOffMode ?? this.ballJumpOffMode,
      wrongBallPenalty: wrongBallPenalty ?? this.wrongBallPenalty,
      scratchPenalty: scratchPenalty ?? this.scratchPenalty,
      carryBallPenalty: carryBallPenalty ?? this.carryBallPenalty,
      ballTouchedPenalty: ballTouchedPenalty ?? this.ballTouchedPenalty,
      ballJumpedOffPenalty: ballJumpedOffPenalty ?? this.ballJumpedOffPenalty,
      cueBallJumpedOffPenalty:
          cueBallJumpedOffPenalty ?? this.cueBallJumpedOffPenalty,
    );
  }

  // Reset to defaults
  factory GameRules.reset() => GameRules.defaults();
}
