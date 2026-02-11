import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/action.dart';

void main() {
  group('ActionType', () {
    group('label', () {
      test('returns correct label for each type', () {
        expect(ActionType.successfulPocket.label, 'Pocket');
        expect(ActionType.combinationShot.label, 'Combo');
        expect(ActionType.neutralShot.label, 'Neutral');
        expect(ActionType.wrongBallContact.label, 'Wrong Ball');
        expect(ActionType.cueBallScratch.label, 'Scratch');
        expect(ActionType.ballTouched.label, 'Touch Foul');
        expect(ActionType.ballJumpedOff.label, 'Ball Off');
        expect(ActionType.cueBallJumpedOff.label, 'Cue Off');
        expect(ActionType.bothJumpedOff.label, 'Both Off');
        expect(ActionType.carryBall.label, 'Carry');
        expect(ActionType.handicapAdjustment.label, 'Handicap');
      });
    });

    group('description', () {
      test('returns non-empty description for each type', () {
        for (final type in ActionType.values) {
          expect(type.description, isNotEmpty,
              reason: '${type.name} should have a description');
        }
      });
    });

    group('isPositive', () {
      test('successfulPocket is positive', () {
        expect(ActionType.successfulPocket.isPositive, true);
      });

      test('combinationShot is positive', () {
        expect(ActionType.combinationShot.isPositive, true);
      });

      test('penalties are not positive', () {
        expect(ActionType.wrongBallContact.isPositive, false);
        expect(ActionType.cueBallScratch.isPositive, false);
        expect(ActionType.ballTouched.isPositive, false);
        expect(ActionType.ballJumpedOff.isPositive, false);
        expect(ActionType.carryBall.isPositive, false);
      });

      test('neutral types are not positive', () {
        expect(ActionType.neutralShot.isPositive, false);
        expect(ActionType.bothJumpedOff.isPositive, false);
      });
    });

    group('isNeutral', () {
      test('neutralShot is neutral', () {
        expect(ActionType.neutralShot.isNeutral, true);
      });

      test('bothJumpedOff is neutral', () {
        expect(ActionType.bothJumpedOff.isNeutral, true);
      });

      test('positive types are not neutral', () {
        expect(ActionType.successfulPocket.isNeutral, false);
        expect(ActionType.combinationShot.isNeutral, false);
      });

      test('penalties are not neutral', () {
        expect(ActionType.wrongBallContact.isNeutral, false);
        expect(ActionType.cueBallScratch.isNeutral, false);
      });
    });

    group('isNegative', () {
      test('penalty types are negative', () {
        expect(ActionType.wrongBallContact.isNegative, true);
        expect(ActionType.cueBallScratch.isNegative, true);
        expect(ActionType.ballTouched.isNegative, true);
        expect(ActionType.ballJumpedOff.isNegative, true);
        expect(ActionType.cueBallJumpedOff.isNegative, true);
        expect(ActionType.carryBall.isNegative, true);
        expect(ActionType.handicapAdjustment.isNegative, true);
      });

      test('positive types are not negative', () {
        expect(ActionType.successfulPocket.isNegative, false);
        expect(ActionType.combinationShot.isNegative, false);
      });

      test('neutral types are not negative', () {
        expect(ActionType.neutralShot.isNegative, false);
        expect(ActionType.bothJumpedOff.isNegative, false);
      });
    });

    group('iconName', () {
      test('returns non-empty icon name for every type', () {
        for (final type in ActionType.values) {
          expect(type.iconName, isNotEmpty,
              reason: '${type.name} should have an icon name');
        }
      });
    });

    group('classification completeness', () {
      test('every action type is exactly one of positive, neutral, or negative',
          () {
        for (final type in ActionType.values) {
          final classifications = [
            type.isPositive,
            type.isNeutral,
            type.isNegative,
          ].where((b) => b).length;

          expect(classifications, 1,
              reason:
                  '${type.name} should be exactly one of positive/neutral/negative');
        }
      });
    });
  });

  group('GameAction', () {
    final timestamp = DateTime(2025, 6, 15, 14, 30, 0);

    group('constructor', () {
      test('creates action with required fields', () {
        final action = GameAction(
          id: 'a1',
          gameId: 'g1',
          playerId: 'p1',
          type: ActionType.successfulPocket,
          pointsChange: 6,
          timestamp: timestamp,
        );

        expect(action.id, 'a1');
        expect(action.gameId, 'g1');
        expect(action.playerId, 'p1');
        expect(action.type, ActionType.successfulPocket);
        expect(action.pointsChange, 6);
        expect(action.ballNumber, isNull);
        expect(action.description, isNull);
        expect(action.previousScore, isNull);
      });

      test('creates action with all optional fields', () {
        final action = GameAction(
          id: 'a1',
          gameId: 'g1',
          playerId: 'p1',
          type: ActionType.successfulPocket,
          ballNumber: 7,
          pointsChange: 7,
          timestamp: timestamp,
          description: 'Test pocket',
          previousScore: 10,
          previousCurrentBallIndex: 2,
          previousRemainingBalls: [3, 4, 5],
          previousPocketedBalls: [6, 7],
          previousIsEliminated: false,
        );

        expect(action.ballNumber, 7);
        expect(action.description, 'Test pocket');
        expect(action.previousScore, 10);
        expect(action.previousCurrentBallIndex, 2);
        expect(action.previousRemainingBalls, [3, 4, 5]);
        expect(action.previousPocketedBalls, [6, 7]);
        expect(action.previousIsEliminated, false);
      });
    });

    group('toMap / fromMap', () {
      test('serializes action correctly', () {
        final action = GameAction(
          id: 'a1',
          gameId: 'g1',
          playerId: 'p1',
          type: ActionType.successfulPocket,
          ballNumber: 7,
          pointsChange: 7,
          timestamp: timestamp,
          description: 'Pocketed ball 7',
          previousScore: 10,
          previousCurrentBallIndex: 4,
          previousRemainingBalls: [7, 8, 9, 10],
          previousPocketedBalls: [3, 4, 5, 6],
          previousIsEliminated: false,
        );

        final map = action.toMap();

        expect(map['id'], 'a1');
        expect(map['game_id'], 'g1');
        expect(map['player_id'], 'p1');
        expect(map['type'], ActionType.successfulPocket.index);
        expect(map['ball_number'], 7);
        expect(map['points_change'], 7);
        expect(map['timestamp'], timestamp.toIso8601String());
        expect(map['description'], 'Pocketed ball 7');
        expect(map['previous_score'], 10);
        expect(map['previous_current_ball_index'], 4);
        expect(map['previous_remaining_balls'], '7,8,9,10');
        expect(map['previous_pocketed_balls'], '3,4,5,6');
        expect(map['previous_is_eliminated'], 0);
      });

      test('serializes null optional fields correctly', () {
        final action = GameAction(
          id: 'a1',
          gameId: 'g1',
          playerId: 'p1',
          type: ActionType.neutralShot,
          pointsChange: 0,
          timestamp: timestamp,
        );

        final map = action.toMap();
        expect(map['ball_number'], isNull);
        expect(map['description'], isNull);
        expect(map['previous_score'], isNull);
        expect(map['previous_remaining_balls'], isNull);
        expect(map['previous_pocketed_balls'], isNull);
      });

      test('deserializes action correctly', () {
        final map = {
          'id': 'a1',
          'game_id': 'g1',
          'player_id': 'p1',
          'type': ActionType.wrongBallContact.index,
          'ball_number': null,
          'points_change': -5,
          'timestamp': timestamp.toIso8601String(),
          'description': 'Wrong ball',
          'previous_score': 20,
          'previous_current_ball_index': 3,
          'previous_remaining_balls': '7,8,9',
          'previous_pocketed_balls': '3,4,5,6',
          'previous_is_eliminated': 0,
        };

        final action = GameAction.fromMap(map);

        expect(action.id, 'a1');
        expect(action.type, ActionType.wrongBallContact);
        expect(action.pointsChange, -5);
        expect(action.previousScore, 20);
        expect(action.previousRemainingBalls, [7, 8, 9]);
        expect(action.previousPocketedBalls, [3, 4, 5, 6]);
        expect(action.previousIsEliminated, false);
      });

      test('deserializes empty ball lists correctly', () {
        final map = {
          'id': 'a1',
          'game_id': 'g1',
          'player_id': 'p1',
          'type': 0,
          'points_change': 0,
          'timestamp': timestamp.toIso8601String(),
          'previous_remaining_balls': '',
          'previous_pocketed_balls': '',
          'previous_is_eliminated': 1,
        };

        final action = GameAction.fromMap(map);
        expect(action.previousRemainingBalls, isEmpty);
        expect(action.previousPocketedBalls, isEmpty);
        expect(action.previousIsEliminated, true);
      });

      test('roundtrip serialization preserves data', () {
        final original = GameAction(
          id: 'a1',
          gameId: 'g1',
          playerId: 'p1',
          type: ActionType.combinationShot,
          ballNumber: 12,
          pointsChange: 12,
          timestamp: timestamp,
          description: 'Combo shot',
          previousScore: 30,
          previousCurrentBallIndex: 5,
          previousRemainingBalls: [10, 11, 12, 13, 14, 15, 1, 2],
          previousPocketedBalls: [3, 4, 5, 6, 7, 8, 9],
          previousIsEliminated: false,
        );

        final restored = GameAction.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.gameId, original.gameId);
        expect(restored.playerId, original.playerId);
        expect(restored.type, original.type);
        expect(restored.ballNumber, original.ballNumber);
        expect(restored.pointsChange, original.pointsChange);
        expect(restored.description, original.description);
        expect(restored.previousScore, original.previousScore);
        expect(
            restored.previousRemainingBalls, original.previousRemainingBalls);
        expect(
            restored.previousPocketedBalls, original.previousPocketedBalls);
      });
    });
  });
}
