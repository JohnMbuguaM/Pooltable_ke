import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/utils/constants.dart';

void main() {
  group('AppConstants', () {
    group('ballSequence', () {
      test('has exactly 15 balls', () {
        expect(AppConstants.ballSequence.length, 15);
      });

      test('starts with ball 3', () {
        expect(AppConstants.ballSequence.first, 3);
      });

      test('ends with ball 2', () {
        expect(AppConstants.ballSequence.last, 2);
      });

      test('follows correct order: 3-15, then 1, then 2', () {
        expect(
          AppConstants.ballSequence,
          [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2],
        );
      });

      test('contains all ball numbers 1-15', () {
        final sorted = List<int>.from(AppConstants.ballSequence)..sort();
        expect(sorted, List.generate(15, (i) => i + 1));
      });
    });

    group('allBalls', () {
      test('has exactly 15 balls', () {
        expect(AppConstants.allBalls.length, 15);
      });

      test('contains balls 1-15 in order', () {
        expect(AppConstants.allBalls, List.generate(15, (i) => i + 1));
      });
    });

    group('ballValues', () {
      test('has values for all 15 balls', () {
        expect(AppConstants.ballValues.length, 15);
      });

      test('balls 3-6 are worth 6 points each', () {
        expect(AppConstants.ballValues[3], 6);
        expect(AppConstants.ballValues[4], 6);
        expect(AppConstants.ballValues[5], 6);
        expect(AppConstants.ballValues[6], 6);
      });

      test('balls 7-15 are worth face value', () {
        for (int i = 7; i <= 15; i++) {
          expect(AppConstants.ballValues[i], i,
              reason: 'Ball $i should be worth $i points');
        }
      });

      test('ball 1 is worth 16 points', () {
        expect(AppConstants.ballValues[1], 16);
      });

      test('ball 2 is worth 17 points', () {
        expect(AppConstants.ballValues[2], 17);
      });
    });

    group('getBallValue', () {
      test('returns correct value for each ball', () {
        expect(AppConstants.getBallValue(1), 16);
        expect(AppConstants.getBallValue(2), 17);
        expect(AppConstants.getBallValue(3), 6);
        expect(AppConstants.getBallValue(7), 7);
        expect(AppConstants.getBallValue(15), 15);
      });

      test('returns 0 for invalid ball number', () {
        expect(AppConstants.getBallValue(0), 0);
        expect(AppConstants.getBallValue(16), 0);
        expect(AppConstants.getBallValue(-1), 0);
      });
    });

    group('totalBallPoints', () {
      test('is the sum of all ball values', () {
        // 3+4+5+6 = 6*4 = 24
        // 7+8+9+10+11+12+13+14+15 = 99
        // 1 = 16, 2 = 17
        // Total = 24 + 99 + 16 + 17 = 156
        expect(AppConstants.totalBallPoints, 156);
      });

      test('matches manual sum of ballValues', () {
        final manualSum = AppConstants.ballValues.values.fold(0, (a, b) => a + b);
        expect(AppConstants.totalBallPoints, manualSum);
      });
    });

    group('ballColors', () {
      test('has colors for all 15 balls', () {
        expect(AppConstants.ballColors.length, 15);
        for (int i = 1; i <= 15; i++) {
          expect(AppConstants.ballColors.containsKey(i), true,
              reason: 'Ball $i should have a color');
        }
      });
    });

    group('isStriped / isSolid', () {
      test('balls 1-8 are solid', () {
        for (int i = 1; i <= 8; i++) {
          expect(AppConstants.isSolid(i), true,
              reason: 'Ball $i should be solid');
        }
      });

      test('balls 9-15 are striped', () {
        for (int i = 9; i <= 15; i++) {
          expect(AppConstants.isStriped(i), true,
              reason: 'Ball $i should be striped');
        }
      });

      test('balls 1-8 are not striped', () {
        for (int i = 1; i <= 8; i++) {
          expect(AppConstants.isStriped(i), false,
              reason: 'Ball $i should not be striped');
        }
      });

      test('balls 9-15 are not solid', () {
        for (int i = 9; i <= 15; i++) {
          expect(AppConstants.isSolid(i), false,
              reason: 'Ball $i should not be solid');
        }
      });
    });

    group('database constants', () {
      test('database name is set', () {
        expect(AppConstants.dbName, 'pooltable_ke.db');
      });

      test('database version is 1', () {
        expect(AppConstants.dbVersion, 1);
      });
    });

    group('player limits', () {
      test('minimum players is 2', () {
        expect(AppConstants.minPlayers, 2);
      });

      test('maximum players is 20', () {
        expect(AppConstants.maxPlayers, 20);
      });

      test('min is less than max', () {
        expect(AppConstants.minPlayers, lessThan(AppConstants.maxPlayers));
      });
    });
  });
}
