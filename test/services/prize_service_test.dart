import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/prize_session.dart';
import 'package:pooltable_ke/providers/prize_provider.dart';

void main() {
  // ── PrizeConfig tests ────────────────────────────────────────────────────

  group('PrizeConfig', () {
    test('calculates total pot correctly', () {
      const config = PrizeConfig(wagerPerPlayer: 50);
      expect(config.totalPot(3), 150);
      expect(config.totalPot(2), 100);
    });

    test('calculates prize pool (total minus board+chalkman fees)', () {
      const config = PrizeConfig(wagerPerPlayer: 50);
      // 3 players: 150 - 20 (board) - 10 (chalkman) = 120
      expect(config.prizePool(3), 120);
      // 2 players: 100 - 20 - 10 = 70
      expect(config.prizePool(2), 70);
    });

    test('prize pool is never negative', () {
      const config = PrizeConfig(wagerPerPlayer: 5);
      // 2 players: 10 - 20 - 10 = -20 → clamped to 0
      expect(config.prizePool(2), 0);
    });

    test('shouldPayChalkmanImmediately true when pot >= 100', () {
      const config = PrizeConfig(wagerPerPlayer: 50);
      expect(config.shouldPayChalkmanImmediately(2), true);  // 100
      expect(config.shouldPayChalkmanImmediately(3), true);  // 150
    });

    test('shouldPayChalkmanImmediately false when pot < 100', () {
      const config = PrizeConfig(wagerPerPlayer: 30);
      expect(config.shouldPayChalkmanImmediately(3), false);  // 90 < 100
    });

    test('zero wager gives zero pot and zero prize pool', () {
      const config = PrizeConfig(wagerPerPlayer: 0);
      expect(config.totalPot(3), 0);
      expect(config.prizePool(3), 0);
    });
  });

  // ── PrizeProvider: single-game session ──────────────────────────────────

  group('PrizeProvider – single game', () {
    late PrizeProvider provider;

    setUp(() {
      provider = PrizeProvider();
    });

    test('starts with no active session', () {
      expect(provider.hasActiveSession, false);
      expect(provider.session, isNull);
    });

    test('startSession creates session with correct players', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );
      expect(provider.hasActiveSession, true);
      expect(provider.session!.players.length, 3);
      expect(provider.session!.config.wagerPerPlayer, 50);
    });

    test('recordGameResult credits winner and debits losers', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );

      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      final session = provider.session!;
      // prizePool = 150 - 20 - 10 = 120
      expect(session.findPlayer('Alice')!.balance, 120);
      expect(session.findPlayer('Bob')!.balance, -50);
      expect(session.findPlayer('Charlie')!.balance, -50);
    });

    test('winner balance "if quitting" = prizePool = 120', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      // "if quitting" = current balance
      expect(provider.getBalance('Alice'), 120);
    });

    test('winner balance "if playing next" = balance - wager = 70', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      // After continueSession, winner is debited the next wager
      provider.continueSession(['Alice', 'Bob', 'Charlie']);
      expect(provider.getBalance('Alice'), 70);
    });

    test('records one game record after result', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob'],
      );
      expect(provider.session!.gameRecords.length, 1);
      expect(provider.session!.gameRecords.first.winnerName, 'Alice');
    });

    test('board fee is tracked per game', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob'],
      );
      expect(provider.session!.totalBoardFees, 20);
    });

    test('endSession clears the session', () {
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );
      provider.endSession();
      expect(provider.hasActiveSession, false);
    });
  });

  // ── PrizeProvider: multi-game session ───────────────────────────────────

  group('PrizeProvider – multi-game session', () {
    late PrizeProvider provider;

    setUp(() {
      provider = PrizeProvider();
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );
    });

    test('winner who plays two games and wins both: balance 190 if quitting', () {
      // Game 1: Alice wins → balance +120
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      // Alice continues (deducted 50) → +70
      provider.continueSession(['Alice', 'Bob', 'Charlie']);

      // Game 2: Alice wins again → +70 + 120 = 190
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      expect(provider.getBalance('Alice'), 190);
    });

    test('winner who plays game 3 has balance 140 (190 - 50 wager)', () {
      // Game 1 + 2: Alice wins both
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      provider.continueSession(['Alice', 'Bob', 'Charlie']);
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      // Alice continues to game 3 → deducted another 50
      provider.continueSession(['Alice', 'Bob', 'Charlie']);

      expect(provider.getBalance('Alice'), 140);
    });

    test('winner who loses game 2 has balance 20', () {
      // Game 1: Alice wins → +120
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      // Alice commits to game 2 → +70
      provider.continueSession(['Alice', 'Bob', 'Charlie']);

      // Game 2: Bob wins, Alice loses → +70 - 50 = +20
      provider.recordGameResult(
        winnerName: 'Bob',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      expect(provider.getBalance('Alice'), 20);
    });

    test('loser who loses two games owes -100', () {
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      provider.continueSession(['Alice', 'Bob', 'Charlie']);
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      expect(provider.getBalance('Bob'), -100);
      expect(provider.getBalance('Charlie'), -100);
    });

    test('previous winner losing game 2 then game 3 owes -30', () {
      // Game 1: Alice wins → +120
      provider.recordGameResult(
        winnerName: 'Alice',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      // Alice commits to game 2 → +70
      provider.continueSession(['Alice', 'Bob', 'Charlie']);

      // Game 2: Bob wins, Alice loses → +70 - 50 = +20
      provider.recordGameResult(
        winnerName: 'Bob',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );
      // Bob commits to game 3 → Bob: 120 - 50 = +70
      provider.continueSession(['Alice', 'Bob', 'Charlie']);

      // Game 3: Charlie wins, Alice loses → +20 - 50 = -30
      provider.recordGameResult(
        winnerName: 'Charlie',
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      expect(provider.getBalance('Alice'), -30);
    });
  });

  // ── Chalkman fee rules ───────────────────────────────────────────────────

  group('Chalkman fee accumulation', () {
    test('pays chalkman immediately when pot >= 100 (2 players × 50)', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['A', 'B'],
        wagerPerPlayer: 50, // pot = 100 >= 100
      );
      provider.recordGameResult(winnerName: 'A', playerNames: ['A', 'B']);

      expect(provider.session!.totalChalkmanFeesPaid, 10);
      expect(provider.session!.accumulatedChalkmanFee, 0);
    });

    test('accumulates chalkman fee when pot < 100', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['A', 'B'],
        wagerPerPlayer: 30, // pot = 60 < 100
      );
      provider.recordGameResult(winnerName: 'A', playerNames: ['A', 'B']);

      expect(provider.session!.totalChalkmanFeesPaid, 0);
      expect(provider.session!.accumulatedChalkmanFee, 10);
      expect(provider.session!.consecutiveLowPotGames, 1);
    });

    test('pays accumulated chalkman fee after 3 consecutive low-pot games', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['A', 'B'],
        wagerPerPlayer: 30, // pot = 60 < 100
      );

      for (var i = 0; i < 3; i++) {
        provider.recordGameResult(winnerName: 'A', playerNames: ['A', 'B']);
        if (i < 2) provider.continueSession(['A', 'B']);
      }

      // After 3 games: 3 × 10 = 30 accumulated then paid
      expect(provider.session!.totalChalkmanFeesPaid, 30);
      expect(provider.session!.accumulatedChalkmanFee, 0);
      expect(provider.session!.consecutiveLowPotGames, 0);
    });

    test('resets consecutive counter after immediate payment', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['A', 'B'],
        wagerPerPlayer: 50, // pot = 100 >= 100
      );
      provider.recordGameResult(winnerName: 'A', playerNames: ['A', 'B']);

      expect(provider.session!.consecutiveLowPotGames, 0);
    });
  });

  // ── Wager confirmation ───────────────────────────────────────────────────

  group('Wager confirmation', () {
    test('toggleWagerConfirmed flips the confirmed flag', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );

      expect(
          provider.session!.findPlayer('Alice')!.wagerConfirmedThisGame, false);

      provider.toggleWagerConfirmed('Alice');
      expect(
          provider.session!.findPlayer('Alice')!.wagerConfirmedThisGame, true);

      provider.toggleWagerConfirmed('Alice');
      expect(
          provider.session!.findPlayer('Alice')!.wagerConfirmedThisGame, false);
    });

    test('continueSession resets wager confirmations', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );
      provider.toggleWagerConfirmed('Alice');
      provider.toggleWagerConfirmed('Bob');
      provider.recordGameResult(
          winnerName: 'Alice', playerNames: ['Alice', 'Bob']);
      provider.continueSession(['Alice', 'Bob']);

      expect(
          provider.session!.findPlayer('Alice')!.wagerConfirmedThisGame, false);
      expect(
          provider.session!.findPlayer('Bob')!.wagerConfirmedThisGame, false);
    });
  });

  // ── Name matching ────────────────────────────────────────────────────────

  group('Player name matching (case-insensitive)', () {
    test('finds player regardless of case', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['Alice', 'Bob', 'Charlie'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
          winnerName: 'ALICE', playerNames: ['Alice', 'Bob', 'Charlie']);
      // prizePool = 3×50 - 20 (board) - 10 (chalk) = 120
      expect(provider.getBalance('alice'), 120);
      expect(provider.getBalance('ALICE'), 120);
      expect(provider.getBalance('Alice'), 120);
    });

    test('continueSession adds new players not previously in session', () {
      final provider = PrizeProvider();
      provider.startSession(
        playerNames: ['Alice', 'Bob'],
        wagerPerPlayer: 50,
      );
      provider.recordGameResult(
          winnerName: 'Alice', playerNames: ['Alice', 'Bob']);
      provider.continueSession(['Alice', 'Bob', 'Dave']);

      expect(provider.session!.players.length, 3);
      expect(provider.session!.findPlayer('Dave'), isNotNull);
    });
  });

  // ── PrizeProvider.formatKsh ──────────────────────────────────────────────

  group('PrizeProvider.formatKsh', () {
    test('formats positive balance with + sign', () {
      expect(PrizeProvider.formatKsh(120), '+KSH 120');
      expect(PrizeProvider.formatKsh(70), '+KSH 70');
    });

    test('formats zero balance', () {
      expect(PrizeProvider.formatKsh(0), '+KSH 0');
    });

    test('formats negative balance without + sign', () {
      expect(PrizeProvider.formatKsh(-50), '-KSH 50');
      expect(PrizeProvider.formatKsh(-30), '-KSH 30');
    });
  });
}
