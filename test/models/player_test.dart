import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/player.dart';

void main() {
  group('Player', () {
    group('constructor', () {
      test('creates player with required fields and defaults', () {
        final player = Player(id: 'p1', name: 'Alice');

        expect(player.id, 'p1');
        expect(player.name, 'Alice');
        expect(player.score, 0);
        expect(player.isEliminated, false);
        expect(player.rank, 0);
        expect(player.eliminatedAtRound, isNull);
      });

      test('creates player with all fields specified', () {
        final player = Player(
          id: 'p2',
          name: 'Bob',
          score: 42,
          isEliminated: true,
          rank: 3,
          eliminatedAtRound: 5,
        );

        expect(player.id, 'p2');
        expect(player.name, 'Bob');
        expect(player.score, 42);
        expect(player.isEliminated, true);
        expect(player.rank, 3);
        expect(player.eliminatedAtRound, 5);
      });
    });

    group('copyWith', () {
      test('copies with no changes returns equivalent player', () {
        final original = Player(id: 'p1', name: 'Alice', score: 10);
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.score, original.score);
      });

      test('copies with changed name', () {
        final original = Player(id: 'p1', name: 'Alice');
        final copy = original.copyWith(name: 'Bob');

        expect(copy.name, 'Bob');
        expect(copy.id, 'p1');
      });

      test('copies with changed score', () {
        final original = Player(id: 'p1', name: 'Alice', score: 10);
        final copy = original.copyWith(score: 25);

        expect(copy.score, 25);
        expect(copy.name, 'Alice');
      });

      test('copies with changed elimination status', () {
        final original = Player(id: 'p1', name: 'Alice');
        final copy = original.copyWith(isEliminated: true, eliminatedAtRound: 3);

        expect(copy.isEliminated, true);
        expect(copy.eliminatedAtRound, 3);
      });
    });

    group('toMap / fromMap', () {
      test('serializes to map correctly', () {
        final player = Player(
          id: 'p1',
          name: 'Alice',
          score: 42,
          isEliminated: true,
          rank: 2,
          eliminatedAtRound: 3,
        );

        final map = player.toMap();

        expect(map['id'], 'p1');
        expect(map['name'], 'Alice');
        expect(map['score'], 42);
        expect(map['is_eliminated'], 1);
        expect(map['rank'], 2);
        expect(map['eliminated_at_round'], 3);
      });

      test('serializes non-eliminated player correctly', () {
        final player = Player(id: 'p1', name: 'Bob');
        final map = player.toMap();

        expect(map['is_eliminated'], 0);
        expect(map['score'], 0);
        expect(map['eliminated_at_round'], isNull);
      });

      test('deserializes from map correctly', () {
        final map = {
          'id': 'p1',
          'name': 'Alice',
          'score': 42,
          'is_eliminated': 1,
          'rank': 2,
          'eliminated_at_round': 3,
        };

        final player = Player.fromMap(map);

        expect(player.id, 'p1');
        expect(player.name, 'Alice');
        expect(player.score, 42);
        expect(player.isEliminated, true);
        expect(player.rank, 2);
        expect(player.eliminatedAtRound, 3);
      });

      test('deserializes with null/missing optional fields', () {
        final map = {
          'id': 'p1',
          'name': 'Bob',
          'is_eliminated': 0,
        };

        final player = Player.fromMap(map);

        expect(player.score, 0);
        expect(player.isEliminated, false);
        expect(player.rank, 0);
        expect(player.eliminatedAtRound, isNull);
      });

      test('roundtrip serialization preserves data', () {
        final original = Player(
          id: 'p1',
          name: 'Test Player',
          score: -15,
          isEliminated: false,
          rank: 1,
        );

        final restored = Player.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.score, original.score);
        expect(restored.isEliminated, original.isEliminated);
        expect(restored.rank, original.rank);
      });
    });

    group('toString', () {
      test('formats correctly', () {
        final player = Player(id: 'p1', name: 'Alice', score: 10);
        expect(player.toString(), 'Player(Alice, score: 10, eliminated: false)');
      });

      test('formats eliminated player correctly', () {
        final player =
            Player(id: 'p1', name: 'Bob', score: -5, isEliminated: true);
        expect(player.toString(), 'Player(Bob, score: -5, eliminated: true)');
      });
    });

    group('mutable fields', () {
      test('score can be modified', () {
        final player = Player(id: 'p1', name: 'Alice');
        player.score = 50;
        expect(player.score, 50);
      });

      test('score can go negative', () {
        final player = Player(id: 'p1', name: 'Alice');
        player.score = -25;
        expect(player.score, -25);
      });

      test('elimination status can be modified', () {
        final player = Player(id: 'p1', name: 'Alice');
        player.isEliminated = true;
        player.eliminatedAtRound = 2;
        expect(player.isEliminated, true);
        expect(player.eliminatedAtRound, 2);
      });

      test('name can be modified', () {
        final player = Player(id: 'p1', name: 'Alice');
        player.name = 'Bob';
        expect(player.name, 'Bob');
      });
    });
  });
}
