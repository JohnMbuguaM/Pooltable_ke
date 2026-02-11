import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/game.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/models/action.dart';
import 'package:pooltable_ke/services/game_logic_service.dart';
import 'package:pooltable_ke/utils/constants.dart';

void main() {
  // ===================== TEST HELPERS =====================

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

  // ===================== TESTS =====================

  group('GameLogicService', () {
    // ==========================================
    //  getNextTargetBall
    // ==========================================
    group('getNextTargetBall', () {
      test('returns ball 3 at start of game', () {
        final game = makeGame();
        expect(GameLogicService.getNextTargetBall(game), 3);
      });

      test('returns ball 4 when sequence index is 1', () {
        final game = makeGame(currentBallSequenceIndex: 1);
        expect(GameLogicService.getNextTargetBall(game), 4);
      });

      test('skips pocketed ball at current index', () {
        final game = makeGame(
          remainingBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [3],
          currentBallSequenceIndex: 0,
        );
        expect(GameLogicService.getNextTargetBall(game), 4);
      });

      test('skips multiple consecutive pocketed balls', () {
        final game = makeGame(
          remainingBalls: [1, 2, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [3, 4, 5, 6],
          currentBallSequenceIndex: 0,
        );
        expect(GameLogicService.getNextTargetBall(game), 7);
      });

      test('wraps from end of sequence to beginning', () {
        // Index 14 is ball 2 (last in sequence). If ball 2 is pocketed, wraps to 3.
        final game = makeGame(
          remainingBalls: [3, 4, 5],
          pocketedBalls: [1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 14, // Points to ball 2 in sequence
        );
        expect(GameLogicService.getNextTargetBall(game), 3);
      });

      test('returns -1 when no balls remain', () {
        final game = makeGame(
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
        );
        expect(GameLogicService.getNextTargetBall(game), -1);
      });

      test('finds last remaining ball', () {
        final game = makeGame(
          remainingBalls: [15],
          pocketedBalls: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          currentBallSequenceIndex: 0,
        );
        expect(GameLogicService.getNextTargetBall(game), 15);
      });
    });

    // ==========================================
    //  advanceBallSequenceIndex
    // ==========================================
    group('advanceBallSequenceIndex', () {
      test('advances from index 0 to index 1 (ball 3 to ball 4)', () {
        final game = makeGame(currentBallSequenceIndex: 0);
        expect(GameLogicService.advanceBallSequenceIndex(game), 1);
      });

      test('skips pocketed ball in next position', () {
        // Current index 0 (ball 3). Ball 4 (index 1) is pocketed. Next remaining is ball 5 (index 2).
        final game = makeGame(
          remainingBalls: [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          pocketedBalls: [4],
          currentBallSequenceIndex: 0,
        );
        expect(GameLogicService.advanceBallSequenceIndex(game), 2);
      });

      test('wraps around from ball 15 to ball 1', () {
        // Sequence: ball 15 is at index 12. Ball 1 is at index 13.
        final game = makeGame(
          remainingBalls: [1, 2],
          pocketedBalls: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 12,
        );
        expect(GameLogicService.advanceBallSequenceIndex(game), 13);
      });

      test('returns current index when no remaining balls', () {
        final game = makeGame(
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
          currentBallSequenceIndex: 5,
        );
        expect(GameLogicService.advanceBallSequenceIndex(game), 5);
      });
    });

    // ==========================================
    //  getNextPlayerIndex
    // ==========================================
    group('getNextPlayerIndex', () {
      test('advances from player 0 to player 1', () {
        final game = makeGame(currentPlayerIndex: 0);
        expect(GameLogicService.getNextPlayerIndex(game), 1);
      });

      test('wraps from last player to first', () {
        final game = makeGame(currentPlayerIndex: 1);
        expect(GameLogicService.getNextPlayerIndex(game), 0);
      });

      test('skips eliminated player', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie'),
        ];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        expect(GameLogicService.getNextPlayerIndex(game), 2);
      });

      test('wraps around skipping eliminated players', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie', eliminated: true),
        ];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        // Both next players eliminated, wraps back to 0
        expect(GameLogicService.getNextPlayerIndex(game), 0);
      });

      test('handles three active players correctly', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob'),
          makePlayer('p3', 'Charlie'),
        ];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        expect(GameLogicService.getNextPlayerIndex(game), 1);

        game.currentPlayerIndex = 1;
        expect(GameLogicService.getNextPlayerIndex(game), 2);

        game.currentPlayerIndex = 2;
        expect(GameLogicService.getNextPlayerIndex(game), 0);
      });

      test('skips multiple eliminated players in a row', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie', eliminated: true),
          makePlayer('p4', 'Diana'),
        ];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        expect(GameLogicService.getNextPlayerIndex(game), 3);
      });
    });

    // ==========================================
    //  applySuccessfulPocket
    // ==========================================
    group('applySuccessfulPocket', () {
      test('adds correct points for ball 3 (value=6)', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.players[0].score, 6);
      });

      test('removes pocketed ball from remaining', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.remainingBalls.contains(3), false);
      });

      test('adds pocketed ball to pocketed list', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.pocketedBalls.contains(3), true);
      });

      test('advances the ball sequence index', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentBallSequenceIndex, 1); // Now pointing to ball 4
      });

      test('does NOT advance player (same player continues)', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentPlayerIndex, 0);
      });

      test('adds action to game actions list', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.actions.length, 1);
        expect(game.actions.last.type, ActionType.successfulPocket);
      });

      test('action stores previous state for undo', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        final action = game.actions.last;
        expect(action.previousScore, 0);
        expect(action.previousCurrentBallIndex, 0);
        expect(action.previousRemainingBalls!.length, 15);
        expect(action.previousPocketedBalls, isEmpty);
      });

      test('correctly pockets ball 7 (value=7)', () {
        final game = makeGame(
          remainingBalls: [7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2],
          pocketedBalls: [3, 4, 5, 6],
          currentBallSequenceIndex: 4, // Points to ball 7
        );
        GameLogicService.applySuccessfulPocket(game);
        expect(game.players[0].score, 7);
      });

      test('correctly pockets ball 1 (value=16)', () {
        final game = makeGame(
          remainingBalls: [1, 2],
          pocketedBalls: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 13, // Index of ball 1 in sequence
        );
        GameLogicService.applySuccessfulPocket(game);
        expect(game.players[0].score, 16);
      });

      test('correctly pockets ball 2 (value=17)', () {
        final game = makeGame(
          remainingBalls: [2],
          pocketedBalls: [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
          currentBallSequenceIndex: 14, // Index of ball 2 in sequence
        );
        GameLogicService.applySuccessfulPocket(game);
        expect(game.players[0].score, 17);
      });

      test('accumulates score over multiple pockets', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game); // Ball 3 = 6
        GameLogicService.applySuccessfulPocket(game); // Ball 4 = 6
        GameLogicService.applySuccessfulPocket(game); // Ball 5 = 6
        expect(game.players[0].score, 18);
      });

      test('handles no balls remaining gracefully', () {
        final game = makeGame(
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
        );
        final action = GameLogicService.applySuccessfulPocket(game);
        expect(action.type, ActionType.neutralShot); // No-op
        expect(game.players[0].score, 0);
      });
    });

    // ==========================================
    //  applyCombinationShot
    // ==========================================
    group('applyCombinationShot', () {
      test('adds correct points for combo-pocketed ball', () {
        final game = makeGame();
        // Target is ball 3, but combo pockets ball 10
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.players[0].score, 10);
      });

      test('removes combo ball from remaining', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.remainingBalls.contains(10), false);
      });

      test('adds combo ball to pocketed list', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.pocketedBalls.contains(10), true);
      });

      test('does NOT change sequence index when non-target pocketed', () {
        final game = makeGame(); // Target is ball 3
        final indexBefore = game.currentBallSequenceIndex;
        GameLogicService.applyCombinationShot(game, 10); // Not ball 3
        expect(game.currentBallSequenceIndex, indexBefore);
      });

      test('DOES NOT change player (same player continues)', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.currentPlayerIndex, 0);
      });

      test('records action as combinationShot type', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.actions.last.type, ActionType.combinationShot);
        expect(game.actions.last.ballNumber, 10);
      });

      test('combo of high-value ball adds correct points', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 15); // Ball 15 = 15 pts
        expect(game.players[0].score, 15);
      });

      test('out-of-sequence ball pocketed will be skipped later', () {
        final game = makeGame(); // Target is ball 3
        // Combo pocket ball 8 out of sequence
        GameLogicService.applyCombinationShot(game, 8);
        expect(game.pocketedBalls.contains(8), true);
        expect(game.remainingBalls.contains(8), false);

        // Now pocket balls in sequence until we reach where 8 was
        // Ball 3, 4, 5, 6, 7 then 8 should be skipped
        GameLogicService.applySuccessfulPocket(game); // Pocket 3
        GameLogicService.applySuccessfulPocket(game); // Pocket 4
        GameLogicService.applySuccessfulPocket(game); // Pocket 5
        GameLogicService.applySuccessfulPocket(game); // Pocket 6
        GameLogicService.applySuccessfulPocket(game); // Pocket 7

        // Next target should be 9 (skipping 8 which was already pocketed)
        expect(game.currentTargetBall, 9);
      });
    });

    // ==========================================
    //  applyNeutralShot
    // ==========================================
    group('applyNeutralShot', () {
      test('no points change for neutral shot', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game);
        expect(game.players[0].score, 0);
      });

      test('ball IS pocketed (removed from remaining) on neutral pocket', () {
        final game = makeGame();
        final targetBall = game.currentTargetBall;
        GameLogicService.applyNeutralShot(game);
        expect(game.remainingBalls.contains(targetBall), false);
      });

      test('ball is added to pocketed list on neutral pocket', () {
        final game = makeGame();
        final targetBall = game.currentTargetBall;
        GameLogicService.applyNeutralShot(game);
        expect(game.pocketedBalls.contains(targetBall), true);
      });

      test('advances to next player', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game);
        expect(game.currentPlayerIndex, 1);
      });

      test('advances ball sequence after neutral pocket', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game);
        // Ball 3 neutraled, next target should be 4
        expect(game.currentTargetBall, 4);
      });

      test('records action as neutralShot type', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game);
        expect(game.actions.last.type, ActionType.neutralShot);
        expect(game.actions.last.pointsChange, 0);
      });

      test('bothJumpedOff does NOT pocket the ball', () {
        final game = makeGame();
        final ballsBefore = List<int>.from(game.remainingBalls);
        GameLogicService.applyNeutralShot(game, bothJumpedOff: true);
        expect(game.remainingBalls, ballsBefore);
      });

      test('bothJumpedOff records as bothJumpedOff type', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game, bothJumpedOff: true);
        expect(game.actions.last.type, ActionType.bothJumpedOff);
      });

      test('bothJumpedOff still advances player', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game, bothJumpedOff: true);
        expect(game.currentPlayerIndex, 1);
      });
    });

    // ==========================================
    //  applyPenalty - ALL PENALTY TYPES
    // ==========================================
    group('applyPenalty', () {
      test('wrongBallContact deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        expect(game.players[0].score, -5);
      });

      test('cueBallScratch deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.cueBallScratch);
        expect(game.players[0].score, -5);
      });

      test('ballTouched deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.ballTouched);
        expect(game.players[0].score, -5);
      });

      test('cueBallJumpedOff deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.cueBallJumpedOff);
        expect(game.players[0].score, -5);
      });

      test('carryBall deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.carryBall);
        expect(game.players[0].score, -5);
      });

      test('ballJumpedOff deducts 5 points', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.ballJumpedOff,
            ballNumber: 5);
        expect(game.players[0].score, -5);
      });

      test('ballJumpedOff removes the ball from play', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.ballJumpedOff,
            ballNumber: 5);
        expect(game.remainingBalls.contains(5), false);
        expect(game.pocketedBalls.contains(5), true);
      });

      test('ballJumpedOff of target ball advances sequence', () {
        final game = makeGame(); // Target is ball 3
        GameLogicService.applyPenalty(game, ActionType.ballJumpedOff,
            ballNumber: 3);
        // Target should now be ball 4
        expect(game.currentTargetBall, 4);
      });

      test('ballJumpedOff of non-target ball does NOT advance sequence', () {
        final game = makeGame(); // Target is ball 3
        final seqBefore = game.currentBallSequenceIndex;
        GameLogicService.applyPenalty(game, ActionType.ballJumpedOff,
            ballNumber: 10);
        expect(game.currentBallSequenceIndex, seqBefore);
      });

      test('all penalties advance to next player', () {
        for (final penaltyType in [
          ActionType.wrongBallContact,
          ActionType.cueBallScratch,
          ActionType.ballTouched,
          ActionType.cueBallJumpedOff,
          ActionType.carryBall,
        ]) {
          final game = makeGame(currentPlayerIndex: 0);
          GameLogicService.applyPenalty(game, penaltyType);
          expect(game.currentPlayerIndex, 1,
              reason: '${penaltyType.label} should advance to next player');
        }
      });

      test('penalty records correct action type', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        expect(game.actions.last.type, ActionType.wrongBallContact);
        expect(game.actions.last.pointsChange, -5);
      });

      test('penalty stores previous state for undo', () {
        final game = makeGame();
        game.players[0].score = 20;
        GameLogicService.applyPenalty(game, ActionType.cueBallScratch);
        final action = game.actions.last;
        expect(action.previousScore, 20);
        expect(game.players[0].score, 15);
      });

      test('multiple penalties accumulate', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        // Advances to player 2, switch back for testing
        game.currentPlayerIndex = 0;
        GameLogicService.applyPenalty(game, ActionType.cueBallScratch);
        expect(game.players[0].score, -10);
      });

      test('score can go deeply negative', () {
        final game = makeGame();
        for (int i = 0; i < 10; i++) {
          game.currentPlayerIndex = 0;
          GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        }
        expect(game.players[0].score, -50);
      });
    });

    // ==========================================
    //  checkEliminations
    // ==========================================
    group('checkEliminations', () {
      test('no elimination at start of game', () {
        final game = makeGame();
        final eliminated = GameLogicService.checkEliminations(game);
        expect(eliminated, isEmpty);
      });

      test('eliminates player who cannot win even with all remaining balls', () {
        // Player 1: 100 points. Player 2: 0 points.
        // Remaining balls value is low enough that player 2 can't catch up.
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0),
        ];
        final game = makeGame(
          players: players,
          // Only ball 3 remaining (value 6). Bob needs 100 but can only get 6.
          remainingBalls: [3],
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        final eliminated = GameLogicService.checkEliminations(game);

        expect(eliminated.length, 1);
        expect(eliminated.first.name, 'Bob');
        expect(eliminated.first.isEliminated, true);
      });

      test('does NOT eliminate player who CAN still tie', () {
        final players = [
          makePlayer('p1', 'Alice', score: 10),
          makePlayer('p2', 'Bob', score: 5),
        ];
        // Remaining value is large enough for Bob to catch up
        final game = makeGame(players: players);
        // All balls remaining = 156 points. 5 + 156 > 10, so no elimination.

        final eliminated = GameLogicService.checkEliminations(game);
        expect(eliminated, isEmpty);
      });

      test('eliminates multiple players at once', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0),
          makePlayer('p3', 'Charlie', score: 0),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Only 6 points available
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        final eliminated = GameLogicService.checkEliminations(game);

        expect(eliminated.length, 2);
        expect(eliminated.map((p) => p.name), containsAll(['Bob', 'Charlie']));
      });

      test('does not re-eliminate already eliminated players', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0, eliminated: true),
          makePlayer('p3', 'Charlie', score: 50),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Only 6 points available
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        final eliminated = GameLogicService.checkEliminations(game);
        // Bob is already eliminated, only Charlie gets eliminated
        expect(eliminated.length, 1);
        expect(eliminated.first.name, 'Charlie');
      });

      test('returns empty if only one active player', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0, eliminated: true),
        ];
        final game = makeGame(players: players);

        final eliminated = GameLogicService.checkEliminations(game);
        expect(eliminated, isEmpty);
      });

      test('sets eliminatedAtRound on eliminated player', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3],
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );
        game.roundNumber = 5;

        GameLogicService.checkEliminations(game);

        expect(players[1].eliminatedAtRound, 5);
      });

      test('elimination check uses strict less-than (tie means NOT eliminated)', () {
        // If player can exactly tie, they should NOT be eliminated
        final players = [
          makePlayer('p1', 'Alice', score: 6),
          makePlayer('p2', 'Bob', score: 0),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Value = 6, Bob can tie Alice
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        final eliminated = GameLogicService.checkEliminations(game);
        expect(eliminated, isEmpty);
      });
    });

    // ==========================================
    //  applyHandicap
    // ==========================================
    group('applyHandicap', () {
      test('deducts deficit from leader when player eliminated', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
          makePlayer('p3', 'Charlie', score: 30),
        ];
        final game = makeGame(players: players);

        // Alice leads with 50. Bob had 10. Deficit = 50 - 10 = 40.
        GameLogicService.applyHandicap(game, players[1]);

        expect(players[0].score, 10); // 50 - 40 = 10
      });

      test('creates handicapAdjustment action', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
        ];
        final game = makeGame(players: players);

        GameLogicService.applyHandicap(game, players[1]);

        expect(game.actions.last.type, ActionType.handicapAdjustment);
        expect(game.actions.last.pointsChange, -40);
      });

      test('returns null if no active players', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50, eliminated: true),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
        ];
        final game = makeGame(players: players);

        final result = GameLogicService.applyHandicap(game, players[1]);
        expect(result, isNull);
      });

      test('returns null if deficit is 0 (leader not ahead)', () {
        final players = [
          makePlayer('p1', 'Alice', score: 10),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
          makePlayer('p3', 'Charlie', score: 10),
        ];
        final game = makeGame(players: players);

        final result = GameLogicService.applyHandicap(game, players[1]);
        expect(result, isNull);
      });

      test('handicap stores previous score for undo', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', score: 20, eliminated: true),
        ];
        final game = makeGame(players: players);

        GameLogicService.applyHandicap(game, players[1]);

        expect(game.actions.last.previousScore, 50);
      });

      test('handicap targets the correct leader among multiple active players', () {
        final players = [
          makePlayer('p1', 'Alice', score: 30),
          makePlayer('p2', 'Bob', score: 5, eliminated: true),
          makePlayer('p3', 'Charlie', score: 60), // Leader
        ];
        final game = makeGame(players: players);

        GameLogicService.applyHandicap(game, players[1]);

        // Charlie was leader with 60, deficit = 60 - 5 = 55
        expect(players[2].score, 5); // 60 - 55 = 5
        expect(players[0].score, 30); // Alice unchanged
      });
    });

    // ==========================================
    //  checkEarlyWin
    // ==========================================
    group('checkEarlyWin', () {
      test('returns false when second place can still catch up', () {
        final players = [
          makePlayer('p1', 'Alice', score: 10),
          makePlayer('p2', 'Bob', score: 5),
        ];
        final game = makeGame(players: players); // All balls remaining

        expect(GameLogicService.checkEarlyWin(game), false);
      });

      test('returns true when leader is unbeatable', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Only 6 points available
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        expect(GameLogicService.checkEarlyWin(game), true);
      });

      test('sets game status to completed on early win', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 0),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3],
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        GameLogicService.checkEarlyWin(game);

        expect(game.status, GameStatus.completed);
        expect(game.winnerId, 'p1');
        expect(game.completedAt, isNotNull);
      });

      test('returns true when only one active player remains', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
        ];
        final game = makeGame(players: players);

        expect(GameLogicService.checkEarlyWin(game), true);
      });

      test('does not declare early win when exactly tied with remaining balls', () {
        final players = [
          makePlayer('p1', 'Alice', score: 10),
          makePlayer('p2', 'Bob', score: 4),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Value = 6, Bob can reach 10 (4+6)
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        expect(GameLogicService.checkEarlyWin(game), false);
      });
    });

    // ==========================================
    //  checkGameOver
    // ==========================================
    group('checkGameOver', () {
      test('returns false when balls remain and multiple players active', () {
        final game = makeGame();
        expect(GameLogicService.checkGameOver(game), false);
      });

      test('returns true when all balls pocketed', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 56),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
        );

        expect(GameLogicService.checkGameOver(game), true);
      });

      test('sets winner to highest scorer when all balls pocketed', () {
        final players = [
          makePlayer('p1', 'Alice', score: 100),
          makePlayer('p2', 'Bob', score: 56),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [],
          pocketedBalls: AppConstants.allBalls,
        );

        GameLogicService.checkGameOver(game);

        expect(game.winnerId, 'p1');
        expect(game.status, GameStatus.completed);
      });

      test('returns true when only one player left', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', eliminated: true),
        ];
        final game = makeGame(players: players);

        expect(GameLogicService.checkGameOver(game), true);
        expect(game.winnerId, 'p1');
      });

      test('sets completedAt timestamp', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', eliminated: true),
        ];
        final game = makeGame(players: players);

        GameLogicService.checkGameOver(game);

        expect(game.completedAt, isNotNull);
      });
    });

    // ==========================================
    //  undoLastAction
    // ==========================================
    group('undoLastAction', () {
      test('returns false when no actions to undo', () {
        final game = makeGame();
        expect(GameLogicService.undoLastAction(game), false);
      });

      test('restores player score after pocket undo', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.players[0].score, 6);

        GameLogicService.undoLastAction(game);
        expect(game.players[0].score, 0);
      });

      test('restores remaining balls after pocket undo', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.remainingBalls.length, 14);

        GameLogicService.undoLastAction(game);
        expect(game.remainingBalls.length, 15);
        expect(game.remainingBalls.contains(3), true);
      });

      test('restores pocketed balls after pocket undo', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.pocketedBalls.length, 1);

        GameLogicService.undoLastAction(game);
        expect(game.pocketedBalls, isEmpty);
      });

      test('restores ball sequence index after pocket undo', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentBallSequenceIndex, 1);

        GameLogicService.undoLastAction(game);
        expect(game.currentBallSequenceIndex, 0);
      });

      test('removes the action from actions list', () {
        final game = makeGame();
        GameLogicService.applySuccessfulPocket(game);
        expect(game.actions.length, 1);

        GameLogicService.undoLastAction(game);
        expect(game.actions, isEmpty);
      });

      test('restores score after penalty undo', () {
        final game = makeGame();
        game.players[0].score = 20;
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        expect(game.players[0].score, 15);

        GameLogicService.undoLastAction(game);
        expect(game.players[0].score, 20);
      });

      test('restores game status from completed to active', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', eliminated: true),
        ];
        final game = makeGame(players: players);
        game.status = GameStatus.completed;
        game.winnerId = 'p1';
        game.completedAt = DateTime.now();

        // Add a dummy action to undo
        game.actions.add(GameAction(
          id: 'dummy',
          gameId: game.id,
          playerId: 'p1',
          type: ActionType.successfulPocket,
          pointsChange: 6,
          timestamp: DateTime.now(),
          previousScore: 44,
        ));

        GameLogicService.undoLastAction(game);

        expect(game.status, GameStatus.active);
        expect(game.winnerId, isNull);
        expect(game.completedAt, isNull);
      });

      test('multiple undos restore to original state', () {
        final game = makeGame();

        // Do 3 pockets
        GameLogicService.applySuccessfulPocket(game); // Ball 3 = 6
        GameLogicService.applySuccessfulPocket(game); // Ball 4 = 6
        GameLogicService.applySuccessfulPocket(game); // Ball 5 = 6
        expect(game.players[0].score, 18);
        expect(game.remainingBalls.length, 12);

        // Undo all 3
        GameLogicService.undoLastAction(game);
        GameLogicService.undoLastAction(game);
        GameLogicService.undoLastAction(game);

        expect(game.players[0].score, 0);
        expect(game.remainingBalls.length, 15);
        expect(game.pocketedBalls, isEmpty);
        expect(game.currentBallSequenceIndex, 0);
      });

      test('undo after combo restores the ball and score', () {
        final game = makeGame();
        GameLogicService.applyCombinationShot(game, 10);
        expect(game.players[0].score, 10);
        expect(game.remainingBalls.contains(10), false);

        GameLogicService.undoLastAction(game);
        expect(game.players[0].score, 0);
        expect(game.remainingBalls.contains(10), true);
      });

      test('undo after neutral restores ball state', () {
        final game = makeGame();
        GameLogicService.applyNeutralShot(game);
        // Ball 3 was pocketed (neutral), player advanced
        expect(game.pocketedBalls.contains(3), true);

        GameLogicService.undoLastAction(game);
        expect(game.pocketedBalls.contains(3), false);
        expect(game.remainingBalls.contains(3), true);
      });
    });

    // ==========================================
    //  advanceTurn
    // ==========================================
    group('advanceTurn', () {
      test('advances from player 0 to player 1', () {
        final game = makeGame();
        GameLogicService.advanceTurn(game);
        expect(game.currentPlayerIndex, 1);
      });

      test('wraps back to player 0 from last player', () {
        final game = makeGame(currentPlayerIndex: 1);
        GameLogicService.advanceTurn(game);
        expect(game.currentPlayerIndex, 0);
      });

      test('skips eliminated players', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie'),
        ];
        final game = makeGame(players: players, currentPlayerIndex: 0);
        GameLogicService.advanceTurn(game);
        expect(game.currentPlayerIndex, 2);
      });
    });

    // ==========================================
    //  assignRankings
    // ==========================================
    group('assignRankings', () {
      test('assigns ranks by score descending', () {
        final players = [
          makePlayer('p1', 'Alice', score: 30),
          makePlayer('p2', 'Bob', score: 50),
          makePlayer('p3', 'Charlie', score: 10),
        ];
        final game = makeGame(players: players);

        GameLogicService.assignRankings(game);

        expect(players[1].rank, 1); // Bob: 50
        expect(players[0].rank, 2); // Alice: 30
        expect(players[2].rank, 3); // Charlie: 10
      });

      test('assigns rank even with negative scores', () {
        final players = [
          makePlayer('p1', 'Alice', score: -5),
          makePlayer('p2', 'Bob', score: 10),
          makePlayer('p3', 'Charlie', score: -15),
        ];
        final game = makeGame(players: players);

        GameLogicService.assignRankings(game);

        expect(players[1].rank, 1); // Bob: 10
        expect(players[0].rank, 2); // Alice: -5
        expect(players[2].rank, 3); // Charlie: -15
      });

      test('ranks tied players', () {
        final players = [
          makePlayer('p1', 'Alice', score: 20),
          makePlayer('p2', 'Bob', score: 20),
        ];
        final game = makeGame(players: players);

        GameLogicService.assignRankings(game);

        // Both have rank 1 and 2 (order depends on sort stability)
        final ranks = players.map((p) => p.rank).toSet();
        expect(ranks, {1, 2});
      });

      test('includes eliminated players in ranking', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', score: 10, eliminated: true),
          makePlayer('p3', 'Charlie', score: 30),
        ];
        final game = makeGame(players: players);

        GameLogicService.assignRankings(game);

        expect(players[0].rank, 1); // Alice: 50
        expect(players[2].rank, 2); // Charlie: 30
        expect(players[1].rank, 3); // Bob: 10 (eliminated but still ranked)
      });
    });

    // ==========================================
    //  INTEGRATION / END-TO-END GAME SCENARIOS
    // ==========================================
    group('full game scenarios', () {
      test('complete 2-player game through all balls', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob'),
        ];
        final game = makeGame(players: players);
        int totalPoints = 0;

        // Alice pockets all balls in sequence
        while (game.remainingBalls.isNotEmpty) {
          final ball = game.currentTargetBall;
          if (ball == -1) break;
          final value = AppConstants.getBallValue(ball);
          GameLogicService.applySuccessfulPocket(game);
          totalPoints += value;
        }

        expect(game.remainingBalls, isEmpty);
        expect(game.pocketedBalls.length, 15);
        expect(players[0].score, totalPoints);
        expect(totalPoints, AppConstants.totalBallPoints);
      });

      test('alternating players pocket and miss', () {
        final players = [
          makePlayer('p1', 'Alice'),
          makePlayer('p2', 'Bob'),
        ];
        final game = makeGame(players: players);

        // Alice pockets ball 3
        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentPlayerIndex, 0); // Still Alice's turn

        // Alice misses
        GameLogicService.advanceTurn(game);
        expect(game.currentPlayerIndex, 1); // Bob's turn

        // Bob pockets ball 4
        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentPlayerIndex, 1); // Still Bob's turn
        expect(players[1].score, 6);

        // Bob scratches
        GameLogicService.applyPenalty(game, ActionType.cueBallScratch);
        expect(game.currentPlayerIndex, 0); // Alice's turn
        expect(players[1].score, 1); // 6 - 5 = 1
      });

      test('game with elimination and handicap', () {
        final players = [
          makePlayer('p1', 'Alice', score: 80),
          makePlayer('p2', 'Bob', score: 5),
          makePlayer('p3', 'Charlie', score: 40),
        ];
        final game = makeGame(
          players: players,
          remainingBalls: [3], // Only 6 points left
          pocketedBalls: [1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        );

        // Check eliminations
        final eliminated = GameLogicService.checkEliminations(game);

        // Bob (5 + 6 = 11 < 80) -> eliminated
        // Charlie (40 + 6 = 46 < 80) -> eliminated
        expect(eliminated.length, 2);

        // Apply handicap for Bob
        GameLogicService.applyHandicap(game, players[1]);
        // Leader was Alice (80), deficit = 80 - 5 = 75
        // Alice: 80 - 75 = 5
        expect(players[0].score, 5);
      });

      test('out-of-sequence pocketing followed by sequence play', () {
        final game = makeGame();

        // Combo pocket ball 12 out of sequence
        GameLogicService.applyCombinationShot(game, 12);
        expect(game.players[0].score, 12);

        // Now pocket in sequence: 3, 4, 5, 6, 7, 8, 9, 10, 11
        for (int i = 0; i < 9; i++) {
          GameLogicService.applySuccessfulPocket(game);
        }

        // Ball 12 should have been skipped, next target should be 13
        expect(game.currentTargetBall, 13);
      });

      test('undo restores entire game state after complex sequence', () {
        final game = makeGame();

        // Pocket, penalty, combo, neutral
        GameLogicService.applySuccessfulPocket(game); // Ball 3, +6
        game.currentPlayerIndex = 0;
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact); // -5
        game.currentPlayerIndex = 0;
        GameLogicService.applyCombinationShot(game, 10); // +10
        game.currentPlayerIndex = 0;
        GameLogicService.applyNeutralShot(game); // Neutral, ball 4 pocketed

        expect(game.actions.length, 4);

        // Undo everything
        for (int i = 0; i < 4; i++) {
          GameLogicService.undoLastAction(game);
        }

        expect(game.players[0].score, 0);
        expect(game.remainingBalls.length, 15);
        expect(game.pocketedBalls, isEmpty);
        expect(game.actions, isEmpty);
      });
    });

    // ==========================================
    //  EDGE CASES
    // ==========================================
    group('edge cases', () {
      test('game with maximum 20 players', () {
        final players = List.generate(
          20,
          (i) => makePlayer('p$i', 'Player$i'),
        );
        final game = makeGame(players: players);

        GameLogicService.applySuccessfulPocket(game);
        expect(game.currentPlayerIndex, 0); // Same player on pocket

        GameLogicService.advanceTurn(game);
        expect(game.currentPlayerIndex, 1);
      });

      test('all players eliminated except one triggers game over', () {
        final players = [
          makePlayer('p1', 'Alice', score: 50),
          makePlayer('p2', 'Bob', eliminated: true),
          makePlayer('p3', 'Charlie', eliminated: true),
        ];
        final game = makeGame(players: players);

        expect(GameLogicService.checkGameOver(game), true);
        expect(game.winnerId, 'p1');
      });

      test('penalty on first shot gives negative score', () {
        final game = makeGame();
        GameLogicService.applyPenalty(game, ActionType.wrongBallContact);
        expect(game.players[0].score, -5);
      });

      test('ball jumped off that is current target advances sequence', () {
        final game = makeGame(); // Target is ball 3
        GameLogicService.applyPenalty(game, ActionType.ballJumpedOff,
            ballNumber: 3);

        // Ball 3 removed, sequence should point to ball 4
        expect(game.currentTargetBall, 4);
        expect(game.remainingBalls.contains(3), false);
      });
    });
  });
}
