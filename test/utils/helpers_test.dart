import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/utils/helpers.dart';

void main() {
  group('Helpers', () {
    group('formatDateTime', () {
      test('formats date and time correctly', () {
        final dt = DateTime(2025, 6, 15, 14, 30);
        final result = Helpers.formatDateTime(dt);
        expect(result, contains('Jun'));
        expect(result, contains('15'));
        expect(result, contains('2025'));
      });
    });

    group('formatDate', () {
      test('formats date correctly', () {
        final dt = DateTime(2025, 1, 5);
        final result = Helpers.formatDate(dt);
        expect(result, contains('Jan'));
        expect(result, contains('5'));
        expect(result, contains('2025'));
      });
    });

    group('formatTime', () {
      test('formats time correctly', () {
        final dt = DateTime(2025, 1, 1, 14, 30);
        final result = Helpers.formatTime(dt);
        expect(result, contains('2'));
        expect(result, contains('30'));
        expect(result, contains('PM'));
      });

      test('formats morning time correctly', () {
        final dt = DateTime(2025, 1, 1, 9, 5);
        final result = Helpers.formatTime(dt);
        expect(result, contains('9'));
        expect(result, contains('05'));
        expect(result, contains('AM'));
      });
    });

    group('formatDuration', () {
      test('formats hours and minutes', () {
        expect(Helpers.formatDuration(const Duration(hours: 2, minutes: 30)),
            '2h 30m');
      });

      test('formats minutes and seconds', () {
        expect(
            Helpers.formatDuration(const Duration(minutes: 5, seconds: 42)),
            '5m 42s');
      });

      test('formats seconds only', () {
        expect(Helpers.formatDuration(const Duration(seconds: 15)), '15s');
      });

      test('formats zero seconds', () {
        expect(Helpers.formatDuration(Duration.zero), '0s');
      });

      test('formats exactly 1 hour', () {
        expect(Helpers.formatDuration(const Duration(hours: 1)), '1h 0m');
      });

      test('formats exactly 1 minute', () {
        expect(Helpers.formatDuration(const Duration(minutes: 1)), '1m 0s');
      });

      test('handles large durations', () {
        expect(
            Helpers.formatDuration(const Duration(hours: 10, minutes: 45)),
            '10h 45m');
      });
    });

    group('getOrdinal', () {
      test('1st', () => expect(Helpers.getOrdinal(1), '1st'));
      test('2nd', () => expect(Helpers.getOrdinal(2), '2nd'));
      test('3rd', () => expect(Helpers.getOrdinal(3), '3rd'));
      test('4th', () => expect(Helpers.getOrdinal(4), '4th'));
      test('5th', () => expect(Helpers.getOrdinal(5), '5th'));
      test('10th', () => expect(Helpers.getOrdinal(10), '10th'));

      test('11th (special case)', () {
        expect(Helpers.getOrdinal(11), '11th');
      });

      test('12th (special case)', () {
        expect(Helpers.getOrdinal(12), '12th');
      });

      test('13th (special case)', () {
        expect(Helpers.getOrdinal(13), '13th');
      });

      test('21st', () => expect(Helpers.getOrdinal(21), '21st'));
      test('22nd', () => expect(Helpers.getOrdinal(22), '22nd'));
      test('23rd', () => expect(Helpers.getOrdinal(23), '23rd'));
      test('100th', () => expect(Helpers.getOrdinal(100), '100th'));
      test('101st', () => expect(Helpers.getOrdinal(101), '101st'));
      test('111th', () => expect(Helpers.getOrdinal(111), '111th'));
      test('112th', () => expect(Helpers.getOrdinal(112), '112th'));
      test('113th', () => expect(Helpers.getOrdinal(113), '113th'));
    });

    group('getPlayerInitials', () {
      test('returns two initials for full name', () {
        expect(Helpers.getPlayerInitials('Alice Wonderland'), 'AW');
      });

      test('returns first two chars for single name', () {
        expect(Helpers.getPlayerInitials('Alice'), 'AL');
      });

      test('returns single char for single char name', () {
        expect(Helpers.getPlayerInitials('A'), 'A');
      });

      test('handles extra spaces', () {
        expect(Helpers.getPlayerInitials('  Alice   Bob  '), 'AB');
      });

      test('returns uppercase initials', () {
        expect(Helpers.getPlayerInitials('alice wonderland'), 'AW');
      });

      test('handles three-part names (uses first two)', () {
        expect(Helpers.getPlayerInitials('John Paul Jones'), 'JP');
      });

      test('handles lowercase single name', () {
        expect(Helpers.getPlayerInitials('bob'), 'BO');
      });
    });
  });
}
