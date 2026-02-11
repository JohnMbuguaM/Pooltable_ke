import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/game.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/utils/constants.dart';

void main() {
  Player makePlayer(String id, String name, {int score = 0, bool eliminated = false}) {
    return Player(id: id, name: name, score: score, isEliminated: eliminated);
  }

  Game makeGame({
    List<Player>? players,
    int currentPlayerIndex = 0,
    int currentBallSequenceIndex = 0,
    List<int>? remainingBalls,
    List<int>? pocketedBalls,
  }) {
    return Game(
      id: 'game1',
      players: players ?? [makePlayer('p1', 'Alice'), makePlayer('p2', 'Bob')],
      currentPlayerIndex: currentPlayerIndex,
      currentBallSequenceIndex: currentBallSequenceIndex,
      remainingBalls: remainingBalls,
      pocketedBalls: pocketedBalls,
    );
  }

  group('Game', () {
    group('constructor defaults', () {
      test('initializes with all 15 balls remaining', () {
        final game = makeGame();

        expect(game.remainingBalls.length, 15);
        expect(game.remainingBalls, containsAll(AppConstants.allBalls));
      });

      test('initializes with empty pocketed balls', () {
        final game = makeGame();
        expect(game.pocketedBalls, isEmpty);
      });

      test('initializes with active status', () {
        final game = makeGame();
        expect(game.status, GameStatus.active);
        expect(game.isGameOver, false);
      });

      test('initializes at first player', () {
        final game = makeGame();
        expect(game.currentPlayerIndex, 0);
      });

      test('initializes at first ball in sequence (ball 3)', () {
        final game = makeGame();
        expect(game.currentBallSequenceIndex, 0);
      });

      test('initializes with round 1', () {
        final game = makeGame();
        expect(game.roundNumber, 1);
      });

      test('initializes with no winner', () {
        final game = makeGame();
        expect(game.winnerId, isNull);
        expect(game.completedAt, isNull);
      });

      test('initializes with empty actions list', () {
        final game = makeGame();
        expect(game.actions, isEmpty);
      });

      test('sets createdAt to approximately now', () {
        final before = DateTime.now();
        final game = makeGame();
        final after = DateTime.now();

        expect(game.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(game.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });
    });

    group('currentTargetBall', () {
      test('returns ball 3 at start of game', () {
        final game = makeGame();
        expect(game.currentTargetBall, 3);
      });

      test('returns ball 4 when sequence index is 1', () {
        final game = makeGame(currentBallSequenceIndex: 1);
        expect(game.currentTargetBall, 4);
      });

      test('skips pocketed balls', () {
        // Ball 3 is pocketed, so target should be ball 4
        final game = makeGame(
          remainingBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [3],
          currentBallSequenceIndex: 0,
        );
        expect(game.currentTargetBall, 4);
      });

      test('skips multiple pocketed balls', () {
        // Balls 3,4,5 pocketed, target should be 6
        final game = makeGame(
          remainingBalls: [1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [3, 4, 5],
          currentBallSequenceIndex: 0,
        );
        expect(game.currentTargetBall, 6);
      });

      test('wraps around from 15 to 1', () {
        // Only balls 1 and 2 remaining, sequence at 15's index (12)
        final game = makeGame(
          remainingBalls: [1, 2],
          pocketedBalls: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 12, // Position of ball 15 in sequence
        );
        // After 15 in sequence comes 1, then 2
        // Ball 15 is pocketed so it skips to 1
        expect(game.currentTargetBall, 1);
      });

      test('returns ball 1 when only 1 and 2 remain (at start of sequence)', () {
        final game = makeGame(
          remainingBalls: [1, 2],
          pocketedBalls: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 13, // Index of ball 1 in sequence
        );
        expect(game.currentTargetBall, 1);
      });

      test('returns -1 when no balls remain', () {
        final game = makeGame(
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
        );
        expect(game.currentTargetBall, -1);
      });
    });

    group('currentPlayer', () {
      test('returns first player when index is 0', () {
        final players = [makePlayer('p1', 'Alice'), makePlayer('p2', 'Bob')];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        expect(game.currentPlayer.id, 'p1');
      });

      test('returns second player when index is 1', () {
        final players = [makePlayer('p1', 'Alice'), makePlayer('p2', 'Bob')];
        final game = makeGame(players: players, currentPlayerIndex: 1);
        expect(game.currentPlayer.id, 'p2');
      });
    });

    group('activePlayers', () {
      test('returns all players when none eliminated', () {
        final game = makeGame();
        expect(game.activePlayers.length, 2);
      });

      test('excludes eliminated players', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie'),
        ];
        final game = makeGame(players: players);
        expect(game.activePlayers.length, 2);
        expect(game.activePlayers.map((p) => p.name), ['Alice', 'Charlie']);
      });

      test('returns empty when all eliminated', () {
        final players = [
          makePlayer('p1', 'Alice', eliminated: true),
          makePlayer('p2', 'Bob', eliminated: true),
        ];
        final game = makeGame(players: players);
        expect(game.activePlayers, isEmpty);
      });
    });

    group('eliminatedPlayers', () {
      test('returns empty when none eliminated', () {
        final game = makeGame();
        expect(game.eliminatedPlayers, isEmpty);
      });

      test('returns eliminated players only', () {
        final players = [
          makePlayer('p1', 'Alice', eliminated: true),
          makePlayer('p2', 'Bob'),
          makePlayer('p3', 'Charlie', eliminated: true),
        ];
        final game = makeGame(players: players);
        expect(game.eliminatedPlayers.length, 2);
      });
    });

    group('remainingBallsValue', () {
      test('calculates total value of all balls at start', () {
        final game = makeGame();
        expect(game.remainingBallsValue, AppConstants.totalBallPoints);
      });

      test('calculates correctly after some balls pocketed', () {
        // Remove ball 3 (value 6) and ball 7 (value 7)
        final game = makeGame(
          remainingBalls: [1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [3, 7],
        );
        expect(game.remainingBallsValue, AppConstants.totalBallPoints - 6 - 7);
      });

      test('returns 0 when no balls remaining', () {
        final game = makeGame(remainingBalls: [], pocketedBalls: AppConstants.allBalls);
        expect(game.remainingBallsValue, 0);
      });

      test('returns correct value for single ball', () {
        final game = makeGame(remainingBalls: [2], pocketedBalls: [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
        expect(game.remainingBallsValue, 17); // Ball 2 = 17 points
      });
    });

    group('leader', () {
      test('returns player with highest score', () {
        final players = [
          makePlayer('p1', 'Alice', score: 10),
          makePlayer('p2', 'Bob', score: 25),
          makePlayer('p3', 'Charlie', score: 15),
        ];
        final game = makeGame(players: players);
        expect(game.leader!.name, 'Bob');
      });

      test('returns first player when tied', () {
        final players = [
          makePlayer('p1', 'Alice', score: 20),
          makePlayer('p2', 'Bob', score: 20),
        ];
        final game = makeGame(players: players);
        // reduce uses >= so first with max wins
        expect(game.leader!.name, 'Alice');
      });

      test('ignores eliminated players', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50, eliminated: true),
          makePlayer('p2', 'Bob', score: 10),
        ];
        final game = makeGame(players: players);
        expect(game.leader!.name, 'Bob');
      });

      test('returns null when all players eliminated', () {
        final players = [
          makePlayer('p1', 'Alice', eliminated: true),
          makePlayer('p2', 'Bob', eliminated: true),
        ];
        final game = makeGame(players: players);
        expect(game.leader, isNull);
      });
    });

    group('isGameOver', () {
      test('returns false for active game', () {
        final game = makeGame();
        expect(game.isGameOver, false);
      });

      test('returns true for completed game', () {
        final game = makeGame();
        game.status = GameStatus.completed;
        expect(game.isGameOver, true);
      });

      test('returns true for abandoned game', () {
        final game = makeGame();
        game.status = GameStatus.abandoned;
        expect(game.isGameOver, true);
      });
    });

    group('toMap / fromMap', () {
      test('serializes game state correctly', () {
        final game = makeGame(
          currentPlayerIndex: 1,
          currentBallSequenceIndex: 5,
        );
        game.roundNumber = 3;

        final map = game.toMap();

        expect(map['id'], 'game1');
        expect(map['current_player_index'], 1);
        expect(map['current_ball_sequence_index'], 5);
        expect(map['status'], GameStatus.active.index);
        expect(map['round_number'], 3);
        expect(map['winner_id'], isNull);
        expect(map['completed_at'], isNull);
      });

      test('serializes remaining balls as comma-separated string', () {
        final game = makeGame(remainingBalls: [1, 5, 10]);
        final map = game.toMap();
        expect(map['remaining_balls'], '1,5,10');
      });

      test('serializes pocketed balls as comma-separated string', () {
        final game = makeGame(pocketedBalls: [3, 7, 12]);
        final map = game.toMap();
        expect(map['pocketed_balls'], '3,7,12');
      });

      test('deserializes game correctly', () {
        final now = DateTime.now();
        final map = {
          'id': 'game1',
          'current_player_index': 2,
          'current_ball_sequence_index': 7,
          'remaining_balls': '8,9,10,11,12,13,14,15,1,2',
          'pocketed_balls': '3,4,5,6,7',
          'created_at': now.toIso8601String(),
          'completed_at': null,
          'status': 0,
          'winner_id': null,
          'round_number': 2,
        };

        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob'),
          makePlayer('p3', 'Charlie'),
        ];

        final game = Game.fromMap(map, players: players);

        expect(game.id, 'game1');
        expect(game.currentPlayerIndex, 2);
        expect(game.currentBallSequenceIndex, 7);
        expect(game.remainingBalls, [8, 9, 10, 11, 12, 13, 14, 15, 1, 2]);
        expect(game.pocketedBalls, [3, 4, 5, 6, 7]);
        expect(game.players.length, 3);
        expect(game.status, GameStatus.active);
        expect(game.roundNumber, 2);
      });

      test('roundtrip serialization preserves data', () {
        final game = makeGame(
          currentPlayerIndex: 1,
          currentBallSequenceIndex: 3,
          remainingBalls: [6, 7, 8, 9, 10],
          pocketedBalls: [1, 2, 3, 4, 5, 11, 12, 13, 14, 15],
        );
        game.roundNumber = 4;

        final map = game.toMap();
        final restored = Game.fromMap(map, players: game.players);

        expect(restored.id, game.id);
        expect(restored.currentPlayerIndex, game.currentPlayerIndex);
        expect(restored.currentBallSequenceIndex, game.currentBallSequenceIndex);
        expect(restored.remainingBalls, game.remainingBalls);
        expect(restored.pocketedBalls, game.pocketedBalls);
        expect(restored.roundNumber, game.roundNumber);
      });
    });

    group('GameStatus', () {
      test('has all three expected values', () {
        expect(GameStatus.values.length, 3);
        expect(GameStatus.values, contains(GameStatus.active));
        expect(GameStatus.values, contains(GameStatus.completed));
        expect(GameStatus.values, contains(GameStatus.abandoned));
      });
    });
  });
}
