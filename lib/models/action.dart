enum ActionType {
  successfulPocket,
  combinationShot,
  neutralShot,
  wrongBallContact,
  cueBallScratch,
  ballTouched,
  ballJumpedOff,
  cueBallJumpedOff,
  bothJumpedOff,
  carryBall,
  handicapAdjustment,
  miss,
}

extension ActionTypeExtension on ActionType {
  String get label {
    switch (this) {
      case ActionType.successfulPocket:
        return 'Pocket';
      case ActionType.combinationShot:
        return 'Combo';
      case ActionType.neutralShot:
        return 'Neutral';
      case ActionType.wrongBallContact:
        return 'Wrong Ball';
      case ActionType.cueBallScratch:
        return 'Scratch';
      case ActionType.ballTouched:
        return 'Touch Foul';
      case ActionType.ballJumpedOff:
        return 'Ball Off';
      case ActionType.cueBallJumpedOff:
        return 'Cue Off';
      case ActionType.bothJumpedOff:
        return 'Both Off';
      case ActionType.carryBall:
        return 'Carry';
      case ActionType.handicapAdjustment:
        return 'Handicap';
      case ActionType.miss:
        return 'Miss';
    }
  }

  String get description {
    switch (this) {
      case ActionType.successfulPocket:
        return 'Ball pocketed successfully';
      case ActionType.combinationShot:
        return 'Combination shot - different ball pocketed';
      case ActionType.neutralShot:
        return 'Target + cue ball pocketed or both jumped off';
      case ActionType.wrongBallContact:
        return 'Cue ball hit wrong ball first';
      case ActionType.cueBallScratch:
        return 'Cue ball pocketed';
      case ActionType.ballTouched:
        return 'Hand/body touched a ball';
      case ActionType.ballJumpedOff:
        return 'Ball jumped off the table';
      case ActionType.cueBallJumpedOff:
        return 'Cue ball jumped off the table';
      case ActionType.bothJumpedOff:
        return 'Both target and cue ball jumped off';
      case ActionType.carryBall:
        return 'Ball was carried (pushed twice)';
      case ActionType.handicapAdjustment:
        return 'Points deducted from leader (handicap)';
      case ActionType.miss:
        return 'Missed the target ball';
    }
  }

  bool get isPositive =>
      this == ActionType.successfulPocket || this == ActionType.combinationShot;

  bool get isNeutral =>
      this == ActionType.neutralShot || this == ActionType.bothJumpedOff;

  bool get isNegative => !isPositive && !isNeutral;

  String get iconName {
    switch (this) {
      case ActionType.successfulPocket:
        return 'check_circle';
      case ActionType.combinationShot:
        return 'auto_awesome';
      case ActionType.neutralShot:
        return 'remove_circle_outline';
      case ActionType.wrongBallContact:
        return 'error';
      case ActionType.cueBallScratch:
        return 'cancel';
      case ActionType.ballTouched:
        return 'pan_tool';
      case ActionType.ballJumpedOff:
        return 'arrow_upward';
      case ActionType.cueBallJumpedOff:
        return 'arrow_upward';
      case ActionType.bothJumpedOff:
        return 'unfold_more';
      case ActionType.carryBall:
        return 'swipe';
      case ActionType.handicapAdjustment:
        return 'balance';
      case ActionType.miss:
        return 'close';
    }
  }
}

class GameAction {
  final String id;
  final String gameId;
  final String playerId;
  final ActionType type;
  final int? ballNumber;
  final int pointsChange;
  final DateTime timestamp;
  final String? description;

  // For undo: store the game state snapshot before action
  final int? previousScore;
  final int? previousCurrentBallIndex;
  final List<int>? previousRemainingBalls;
  final List<int>? previousPocketedBalls;
  final bool? previousIsEliminated;

  GameAction({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.type,
    this.ballNumber,
    required this.pointsChange,
    required this.timestamp,
    this.description,
    this.previousScore,
    this.previousCurrentBallIndex,
    this.previousRemainingBalls,
    this.previousPocketedBalls,
    this.previousIsEliminated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'game_id': gameId,
      'player_id': playerId,
      'type': type.index,
      'ball_number': ballNumber,
      'points_change': pointsChange,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'previous_score': previousScore,
      'previous_current_ball_index': previousCurrentBallIndex,
      'previous_remaining_balls': previousRemainingBalls?.join(','),
      'previous_pocketed_balls': previousPocketedBalls?.join(','),
      'previous_is_eliminated': previousIsEliminated == true ? 1 : 0,
    };
  }

  factory GameAction.fromMap(Map<String, dynamic> map) {
    return GameAction(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      playerId: map['player_id'] as String,
      type: ActionType.values[map['type'] as int],
      ballNumber: map['ball_number'] as int?,
      pointsChange: map['points_change'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String?,
      previousScore: map['previous_score'] as int?,
      previousCurrentBallIndex: map['previous_current_ball_index'] as int?,
      previousRemainingBalls: (map['previous_remaining_balls'] as String?)
          ?.split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      previousPocketedBalls: (map['previous_pocketed_balls'] as String?)
          ?.split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .toList(),
      previousIsEliminated: map['previous_is_eliminated'] == 1,
    );
  }
}
