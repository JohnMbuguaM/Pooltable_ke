class GameRules {
  final Map<int, int> ballValues;
  final int wrongBallPenalty;
  final int scratchPenalty;
  final int carryBallPenalty;
  final int ballTouchedPenalty;
  final int ballJumpedOffPenalty;
  final int cueBallJumpedOffPenalty;

  const GameRules({
    required this.ballValues,
    required this.wrongBallPenalty,
    required this.scratchPenalty,
    required this.carryBallPenalty,
    required this.ballTouchedPenalty,
    required this.ballJumpedOffPenalty,
    required this.cueBallJumpedOffPenalty,
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
      wrongBallPenalty: 6,
      scratchPenalty: 6,
      carryBallPenalty: 6,
      ballTouchedPenalty: 6,
      ballJumpedOffPenalty: 6,
      cueBallJumpedOffPenalty: 6,
    );
  }

  // Create from JSON
  factory GameRules.fromJson(Map<String, dynamic> json) {
    return GameRules(
      ballValues: (json['ballValues'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(int.parse(key), value as int),
      ),
      wrongBallPenalty: json['wrongBallPenalty'] as int,
      scratchPenalty: json['scratchPenalty'] as int,
      carryBallPenalty: json['carryBallPenalty'] as int,
      ballTouchedPenalty: json['ballTouchedPenalty'] as int,
      ballJumpedOffPenalty: json['ballJumpedOffPenalty'] as int,
      cueBallJumpedOffPenalty: json['cueBallJumpedOffPenalty'] as int,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'ballValues': ballValues.map((key, value) => MapEntry(key.toString(), value)),
      'wrongBallPenalty': wrongBallPenalty,
      'scratchPenalty': scratchPenalty,
      'carryBallPenalty': carryBallPenalty,
      'ballTouchedPenalty': ballTouchedPenalty,
      'ballJumpedOffPenalty': ballJumpedOffPenalty,
      'cueBallJumpedOffPenalty': cueBallJumpedOffPenalty,
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
    int? wrongBallPenalty,
    int? scratchPenalty,
    int? carryBallPenalty,
    int? ballTouchedPenalty,
    int? ballJumpedOffPenalty,
    int? cueBallJumpedOffPenalty,
  }) {
    return GameRules(
      ballValues: ballValues ?? this.ballValues,
      wrongBallPenalty: wrongBallPenalty ?? this.wrongBallPenalty,
      scratchPenalty: scratchPenalty ?? this.scratchPenalty,
      carryBallPenalty: carryBallPenalty ?? this.carryBallPenalty,
      ballTouchedPenalty: ballTouchedPenalty ?? this.ballTouchedPenalty,
      ballJumpedOffPenalty: ballJumpedOffPenalty ?? this.ballJumpedOffPenalty,
      cueBallJumpedOffPenalty: cueBallJumpedOffPenalty ?? this.cueBallJumpedOffPenalty,
    );
  }

  // Reset to defaults
  factory GameRules.reset() => GameRules.defaults();
}
