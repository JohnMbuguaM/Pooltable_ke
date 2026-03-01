import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/game.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/services/game_logic_service.dart';
import 'package:pooltable_ke/utils/constants.dart';

void main() {
  // ===================== HELPERS =====================

  Player makePlayer(String id, String name, {int score = 0}) {
    return Player(id: id, name: name, score: score);
  }

  /// Creates a game with all balls already pocketed (board empty).
  /// [players] have whatever scores you set — draw/win is determined by scores.
  Game makeFinishedGame({required List<Player> players}) {
    return Game(
      id: 'test-game',
      players: players,
      remainingBalls: [], // board is empty
      pocketedBalls: List.from(AppConstants.allBalls),
    );
  }

  /// Creates a game with ONE ball left on the table.
  Game makeOneRemainingGame({required List<Player> players, int lastBall = 1}) {
    return Game(
      id: 'test-game',
      players: players,
      remainingBalls: [lastBall],
      pocketedBalls:
          AppConstants.allBalls.where((b) => b != lastBall).toList(),
    );
  }

  // ===================== TESTS =====================

  group('Draw Functionality', () {
    // --------------------------------------------------
    // 1. checkGameOver — draw detection
    // --------------------------------------------------
    group('checkGameOver - draw detection', () {
      test('sets draw status when two players have equal top score', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final game = makeFinishedGame(players: [alice, bob]);

        final result = GameLogicService.checkGameOver(game);

        expect(result, isTrue, reason: 'checkGameOver should return true');
        expect(game.status, equals(GameStatus.draw));
        expect(game.winnerId, isNull, reason: 'Draw has no single winner');
        expect(game.drawPlayerIds, isNotNull);
        expect(game.drawPlayerIds, containsAll(['p1', 'p2']));
        expect(game.completedAt, isNotNull);
      });

      test('sets completed status when one player has a higher score', () {
        final alice = makePlayer('p1', 'Alice', score: 60);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final game = makeFinishedGame(players: [alice, bob]);

        final result = GameLogicService.checkGameOver(game);

        expect(result, isTrue);
        expect(game.status, equals(GameStatus.completed));
        expect(game.winnerId, equals('p1'));
        expect(game.drawPlayerIds, isNull);
      });

      test('three-way draw when three players share the top score', () {
        final alice = makePlayer('p1', 'Alice', score: 40);
        final bob = makePlayer('p2', 'Bob', score: 40);
        final charlie = makePlayer('p3', 'Charlie', score: 40);
        final game = makeFinishedGame(players: [alice, bob, charlie]);

        GameLogicService.checkGameOver(game);

        expect(game.status, equals(GameStatus.draw));
        expect(game.drawPlayerIds, hasLength(3));
        expect(game.drawPlayerIds, containsAll(['p1', 'p2', 'p3']));
        expect(game.winnerId, isNull);
      });

      test('partial draw — two tied leaders, third player behind', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final charlie = makePlayer('p3', 'Charlie', score: 30);
        final game = makeFinishedGame(players: [alice, bob, charlie]);

        GameLogicService.checkGameOver(game);

        expect(game.status, equals(GameStatus.draw));
        expect(game.drawPlayerIds, hasLength(2));
        expect(game.drawPlayerIds, containsAll(['p1', 'p2']));
        expect(game.drawPlayerIds, isNot(contains('p3')));
      });

      test('returns false and does NOT change status when balls remain', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final game = Game(
          id: 'g',
          players: [alice, bob],
          remainingBalls: [1, 2, 3],
        );

        final result = GameLogicService.checkGameOver(game);

        expect(result, isFalse);
        expect(game.status, equals(GameStatus.active));
        expect(game.drawPlayerIds, isNull);
        expect(game.winnerId, isNull);
      });
    });

    // --------------------------------------------------
    // 2. assignRankings — tied players share rank
    // --------------------------------------------------
    group('assignRankings - tied ranks', () {
      test('two tied players both get rank 1', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final game = makeFinishedGame(players: [alice, bob]);

        GameLogicService.checkGameOver(game);
        GameLogicService.assignRankings(game);

        expect(alice.rank, equals(1));
        expect(bob.rank, equals(1));
      });

      test('winner gets rank 1, loser gets rank 2', () {
        final alice = makePlayer('p1', 'Alice', score: 60);
        final bob = makePlayer('p2', 'Bob', score: 40);
        final game = makeFinishedGame(players: [alice, bob]);

        GameLogicService.checkGameOver(game);
        GameLogicService.assignRankings(game);

        expect(alice.rank, equals(1));
        expect(bob.rank, equals(2));
      });

      test('three-way tie — all get rank 1', () {
        final alice = makePlayer('p1', 'Alice', score: 40);
        final bob = makePlayer('p2', 'Bob', score: 40);
        final charlie = makePlayer('p3', 'Charlie', score: 40);
        final game = makeFinishedGame(players: [alice, bob, charlie]);

        GameLogicService.assignRankings(game);

        expect(alice.rank, equals(1));
        expect(bob.rank, equals(1));
        expect(charlie.rank, equals(1));
      });

      test('top two tied at rank 1, third player gets rank 3', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final charlie = makePlayer('p3', 'Charlie', score: 30);
        final game = makeFinishedGame(players: [alice, bob, charlie]);

        GameLogicService.assignRankings(game);

        expect(alice.rank, equals(1));
        expect(bob.rank, equals(1));
        // Charlie is 3rd (two players above her share rank 1, so next is 3)
        expect(charlie.rank, equals(3));
      });
    });

    // --------------------------------------------------
    // 3. undoLastAction — restores draw to active
    // --------------------------------------------------
    group('undoLastAction - draw state restoration', () {
      test('undo after draw resets status to active', () {
        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: 0);

        // Game with last ball remaining; current player is Alice
        final lastBall = AppConstants.ballSequence.last;
        final lastBallValue = AppConstants.getBallValue(lastBall);

        // Give Alice enough score so that pocketing the last ball ties with Bob
        // Bob's score = lastBallValue (pre-set)
        // Alice's score = 0 → after pocket = lastBallValue → tie
        bob.score = lastBallValue;
        alice.score = 0;

        final game = makeOneRemainingGame(
          players: [alice, bob],
          lastBall: lastBall,
        );
        game.currentPlayerIndex = 0; // Alice's turn

        // Pocket the last ball (creates a draw)
        GameLogicService.applySuccessfulPocket(game);
        GameLogicService.checkGameOver(game);
        GameLogicService.assignRankings(game);

        expect(game.status, equals(GameStatus.draw),
            reason: 'Should be a draw after pocket');
        expect(game.drawPlayerIds, isNotNull);

        // Now undo
        final undone = GameLogicService.undoLastAction(game);

        expect(undone, isTrue);
        expect(game.status, equals(GameStatus.active),
            reason: 'Status must revert to active after undo');
        expect(game.winnerId, isNull);
        expect(game.drawPlayerIds, isNull,
            reason: 'drawPlayerIds must be cleared after undo');
        expect(game.completedAt, isNull);
        // Alice's score should be back to 0
        expect(alice.score, equals(0));
        // Ball should be back on the table
        expect(game.remainingBalls, contains(lastBall));
      });

      test('undo after regular win also resets correctly', () {
        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: 0);

        // Alice will pocket more than Bob has → clear win
        final lastBall = AppConstants.ballSequence.last;

        // Bob has 0, Alice pockets lastBall → Alice wins
        alice.score = 0;
        bob.score = 0;

        final game = makeOneRemainingGame(
          players: [alice, bob],
          lastBall: lastBall,
        );
        game.currentPlayerIndex = 0;

        GameLogicService.applySuccessfulPocket(game);
        GameLogicService.checkGameOver(game);

        expect(game.status, equals(GameStatus.completed));
        expect(game.winnerId, equals('p1'));

        GameLogicService.undoLastAction(game);

        expect(game.status, equals(GameStatus.active));
        expect(game.winnerId, isNull);
        expect(game.drawPlayerIds, isNull);
      });
    });

    // --------------------------------------------------
    // 4. Draw only happens when all balls are pocketed
    // --------------------------------------------------
    group('Draw only on board-clear', () {
      test('equal scores mid-game does NOT produce a draw', () {
        final alice = makePlayer('p1', 'Alice', score: 30);
        final bob = makePlayer('p2', 'Bob', score: 30);
        // balls still remaining
        final game = Game(
          id: 'g',
          players: [alice, bob],
          remainingBalls: [5, 9, 15],
        );

        GameLogicService.checkGameOver(game);

        expect(game.status, equals(GameStatus.active),
            reason: 'Equal scores mid-game should NOT trigger draw');
      });

      test('early win logic is unaffected by draw — still a single winner', () {
        // Alice is so far ahead that Bob cannot catch up even with all remaining
        final alice = makePlayer('p1', 'Alice', score: 200);
        final bob = makePlayer('p2', 'Bob', score: 10);
        final game = Game(
          id: 'g',
          players: [alice, bob],
          remainingBalls: [1], // ball 1 = 1 pt, not enough for Bob to catch up
        );

        final earlyWin = GameLogicService.checkEarlyWin(game);

        expect(earlyWin, isTrue);
        expect(game.status, equals(GameStatus.completed));
        expect(game.winnerId, equals('p1'));
        expect(game.drawPlayerIds, isNull);
      });
    });

    // --------------------------------------------------
    // 5. checkDrawBallPlayers — pre-pocket draw warning
    // --------------------------------------------------
    group('checkDrawBallPlayers - draw ball notification', () {
      test('returns draw partners when last ball creates a tie', () {
        final lastBall = AppConstants.ballSequence.last;
        final lastBallValue = AppConstants.getBallValue(lastBall);

        // Alice has 0, Bob has lastBallValue → pocketing last ball ties them
        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: lastBallValue);

        final game = makeOneRemainingGame(
          players: [alice, bob],
          lastBall: lastBall,
        );
        game.currentPlayerIndex = 0; // Alice's turn

        final drawPartners =
            GameLogicService.checkDrawBallPlayers(game);

        expect(drawPartners, hasLength(1));
        expect(drawPartners.first.id, equals('p2'));
      });

      test('returns empty when last ball gives current player a win (not tie)', () {
        final lastBall = AppConstants.ballSequence.last;

        // Alice 0, Bob 0 → Alice pockets → Alice wins (Bob still 0)
        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: 0);

        final game = makeOneRemainingGame(
          players: [alice, bob],
          lastBall: lastBall,
        );
        game.currentPlayerIndex = 0;

        final drawPartners =
            GameLogicService.checkDrawBallPlayers(game);

        expect(drawPartners, isEmpty,
            reason: 'Alice wins outright — no draw warning needed');
      });

      test('returns empty when more than one ball remains', () {
        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: 10);

        // Two balls left — no draw possible from this pocket alone
        final game = Game(
          id: 'g',
          players: [alice, bob],
          remainingBalls: [1, 2],
        );

        final drawPartners =
            GameLogicService.checkDrawBallPlayers(game);

        expect(drawPartners, isEmpty);
      });

      test('three-way draw — returns two draw partners', () {
        final lastBall = AppConstants.ballSequence.last;
        final lastBallValue = AppConstants.getBallValue(lastBall);

        final alice = makePlayer('p1', 'Alice', score: 0);
        final bob = makePlayer('p2', 'Bob', score: lastBallValue);
        final charlie = makePlayer('p3', 'Charlie', score: lastBallValue);

        final game = makeOneRemainingGame(
          players: [alice, bob, charlie],
          lastBall: lastBall,
        );
        game.currentPlayerIndex = 0; // Alice pockets → ties with both

        final drawPartners =
            GameLogicService.checkDrawBallPlayers(game);

        expect(drawPartners, hasLength(2));
        expect(drawPartners.map((p) => p.id),
            containsAll(['p2', 'p3']));
      });
    });

    // --------------------------------------------------
    // 6. Game model — draw persistence round-trip
    // --------------------------------------------------
    group('Game model draw serialisation', () {
      test('toMap / fromMap preserves draw status and drawPlayerIds', () {
        final alice = makePlayer('p1', 'Alice', score: 50);
        final bob = makePlayer('p2', 'Bob', score: 50);
        final game = makeFinishedGame(players: [alice, bob]);
        GameLogicService.checkGameOver(game);

        expect(game.status, equals(GameStatus.draw));

        final map = game.toMap();

        // status index 3 = draw
        expect(map['status'], equals(GameStatus.draw.index));
        expect(map['winner_id'], isNull);
        expect(map['draw_player_ids'], isNotNull);
        final ids = (map['draw_player_ids'] as String).split(',');
        expect(ids, containsAll(['p1', 'p2']));
      });

      test('fromMap with status 3 (draw) and draw_player_ids restores draw', () {
        final map = {
          'id': 'g1',
          'current_player_index': 0,
          'current_ball_sequence_index': 0,
          'remaining_balls': '',
          'pocketed_balls': '1,2,3',
          'created_at': DateTime.now().toIso8601String(),
          'completed_at': DateTime.now().toIso8601String(),
          'status': GameStatus.draw.index, // 3
          'winner_id': null,
          'draw_player_ids': 'p1,p2',
          'round_number': 1,
        };

        final game = Game.fromMap(map);

        expect(game.status, equals(GameStatus.draw));
        expect(game.winnerId, isNull);
        expect(game.drawPlayerIds, containsAll(['p1', 'p2']));
      });

      test('isGameOver is true for draw status', () {
        final game = Game(
          id: 'g',
          players: [],
          status: GameStatus.draw,
        );
        expect(game.isGameOver, isTrue);
      });

      test('isGameOver is false for active status', () {
        final game = Game(id: 'g', players: []);
        expect(game.isGameOver, isFalse);
      });
    });
  });
}
