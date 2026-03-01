import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prize_session.dart';

class PrizeProvider extends ChangeNotifier {
  PrizeSession? _session;
  static const _kSessionKey = 'prize_session_v1';

  PrizeProvider() {
    _loadSession();
  }

  PrizeSession? get session => _session;
  bool get hasActiveSession => _session != null;

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessionKey);
      if (raw != null) {
        _session = PrizeSession.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PrizeProvider: failed to restore session: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_session == null) {
        await prefs.remove(_kSessionKey);
      } else {
        await prefs.setString(_kSessionKey, jsonEncode(_session!.toJson()));
      }
    } catch (e) {
      debugPrint('PrizeProvider: failed to persist session: $e');
    }
  }

  void _notifyAndPersist() {
    notifyListeners();
    _persist();
  }

  // ── Session lifecycle ────────────────────────────────────────────────────

  /// Start a new prize session from the new-game screen.
  ///
  /// [wagerPerPlayer] = 0 means no monetary wager (fees still tracked).
  void startSession({
    required List<String> playerNames,
    required double wagerPerPlayer,
    double boardFeePerGame = 20.0,
    double chalkmanFeePerGame = 10.0,
  }) {
    final config = PrizeConfig(
      wagerPerPlayer: wagerPerPlayer,
      boardFeePerGame: boardFeePerGame,
      chalkmanFeePerGame: chalkmanFeePerGame,
    );
    _session = PrizeSession(
      config: config,
      players: playerNames.map((n) => PlayerPrizeInfo(displayName: n)).toList(),
    );
    _notifyAndPersist();
  }

  /// Called from RematchSetupScreen when starting the next game in the session.
  ///
  /// - Optionally updates the wager for the new game.
  /// - Resets wager confirmations for all players.
  /// - Adds any new players that weren't in previous games.
  /// - Deducts the wager from the last winner's balance (they commit to the
  ///   next game, so their wager is held now rather than at game end).
  void continueSession(List<String> playerNames, {double? newWagerPerPlayer}) {
    if (_session == null) return;

    // Update wager if a new amount was provided.
    if (newWagerPerPlayer != null) {
      _session!.config = PrizeConfig(
        wagerPerPlayer: newWagerPerPlayer,
        boardFeePerGame: _session!.config.boardFeePerGame,
        chalkmanFeePerGame: _session!.config.chalkmanFeePerGame,
      );
    }

    _session!.resetWagerConfirmations();
    _session!.ensurePlayers(playerNames);

    // Deduct next-game wager from the previous winner's balance so their
    // displayed balance already reflects the "if playing next" amount.
    final lastWinner = _session!.lastWinnerName;
    if (lastWinner != null && _session!.config.wagerPerPlayer > 0) {
      final winner = _session!.findPlayer(lastWinner);
      winner?.balance -= _session!.config.wagerPerPlayer;
    }

    _notifyAndPersist();
  }

  /// Change the wager amount for the current/upcoming game mid-session.
  /// The new wager will be used when recording the next game result.
  void updateWager(double newWager) {
    if (_session == null) return;
    _session!.config = PrizeConfig(
      wagerPerPlayer: newWager,
      boardFeePerGame: _session!.config.boardFeePerGame,
      chalkmanFeePerGame: _session!.config.chalkmanFeePerGame,
    );
    _notifyAndPersist();
  }

  /// End the session (user is done playing for the day).
  void endSession() {
    _session = null;
    _notifyAndPersist();
  }

  // ── In-game actions ──────────────────────────────────────────────────────

  /// Toggle wager-confirmed status for a player (green tick in the UI).
  void toggleWagerConfirmed(String playerName) {
    final player = _session?.findPlayer(playerName);
    if (player == null) return;
    player.wagerConfirmedThisGame = !player.wagerConfirmedThisGame;
    _notifyAndPersist();
  }

  /// Record the result of a completed game and update all balances.
  ///
  /// Call this from the game-over screen once a winner is known.
  ///
  /// [winnerName] may be null if the game was abandoned or a draw.
  /// [playerNames] is the list of all players who participated.
  /// [drawPartnerNames] is set when the game ended in a draw; the prize pool
  /// is split equally among all draw partners.
  void recordGameResult({
    required String? winnerName,
    required List<String> playerNames,
    List<String>? drawPartnerNames,
  }) {
    if (_session == null) return;

    final config = _session!.config;
    final numPlayers = playerNames.length;
    final totalPot = config.totalPot(numPlayers);
    final boardFee = config.boardFeePerGame;
    final chalkmanFee = config.chalkmanFeePerGame;
    final prizePool = config.prizePool(numPlayers);

    // ── Board fees ──────────────────────────────────────────────────────
    _session!.totalBoardFees += boardFee;

    // ── Chalkman fee: immediate (pot ≥ 100) or accumulated (pot < 100) ──
    final prevAccumulatedChalkman = _session!.accumulatedChalkmanFee;
    final prevConsecutiveLowPot = _session!.consecutiveLowPotGames;
    bool chalkmanPaidNow = false;
    if (config.shouldPayChalkmanImmediately(numPlayers)) {
      // Pay accumulated + current fee at once
      _session!.totalChalkmanFeesPaid +=
          chalkmanFee + _session!.accumulatedChalkmanFee;
      _session!.accumulatedChalkmanFee = 0;
      _session!.consecutiveLowPotGames = 0;
      chalkmanPaidNow = true;
    } else {
      _session!.accumulatedChalkmanFee += chalkmanFee;
      _session!.consecutiveLowPotGames++;
      // Pay after every 3 consecutive low-pot games
      if (_session!.consecutiveLowPotGames >= 3) {
        _session!.totalChalkmanFeesPaid += _session!.accumulatedChalkmanFee;
        _session!.accumulatedChalkmanFee = 0;
        _session!.consecutiveLowPotGames = 0;
        chalkmanPaidNow = true;
      }
    }

    // ── Player balance updates ──────────────────────────────────────────
    _session!.ensurePlayers(playerNames);
    final isDrawGame = drawPartnerNames != null && drawPartnerNames.isNotEmpty;
    final splitPrize = isDrawGame ? prizePool / drawPartnerNames.length : 0.0;

    for (final name in playerNames) {
      final player = _session!.findPlayer(name);
      if (player == null) continue;

      if (isDrawGame) {
        final nameKey = name.trim().toLowerCase();
        final isDrawPartner = drawPartnerNames
            .any((d) => d.trim().toLowerCase() == nameKey);
        if (isDrawPartner) {
          player.balance += splitPrize;
        } else if (config.wagerPerPlayer > 0) {
          player.balance -= config.wagerPerPlayer;
        }
      } else {
        final isWinner = winnerName != null &&
            name.trim().toLowerCase() == winnerName.trim().toLowerCase();
        if (isWinner) {
          player.balance += prizePool;
        } else if (config.wagerPerPlayer > 0) {
          player.balance -= config.wagerPerPlayer;
        }
      }
    }

    // ── Game record ─────────────────────────────────────────────────────
    _session!.gameRecords.add(PrizeGameRecord(
      gameNumber: _session!.currentGameNumber,
      winnerName: winnerName,
      playerNames: List.from(playerNames),
      numPlayers: numPlayers,
      totalPot: totalPot,
      boardFee: boardFee,
      chalkmanFee: chalkmanFee,
      chalkmanPaidImmediately: chalkmanPaidNow,
      prizePool: prizePool,
      previousAccumulatedChalkmanFee: prevAccumulatedChalkman,
      previousConsecutiveLowPotGames: prevConsecutiveLowPot,
      completedAt: DateTime.now(),
      drawPartnerNames:
          isDrawGame ? List.from(drawPartnerNames) : null,
    ));

    _notifyAndPersist();
  }

  /// Reverse the last recorded game result (call when a win is revoked).
  /// Restores all player balances and fee totals to pre-game state.
  void revokeLastGameResult() {
    if (_session == null || _session!.gameRecords.isEmpty) return;

    final record = _session!.gameRecords.removeLast();
    final config = _session!.config;

    // ── Reverse board fees ───────────────────────────────────────────
    _session!.totalBoardFees -= record.boardFee;

    // ── Restore chalkman state to exactly what it was before ────────
    if (record.chalkmanPaidImmediately) {
      // Paid out = current fee + whatever was accumulated before
      final paidOut =
          record.chalkmanFee + record.previousAccumulatedChalkmanFee;
      _session!.totalChalkmanFeesPaid -= paidOut;
    } else if (record.previousConsecutiveLowPotGames + 1 >= 3) {
      // Was a 3rd consecutive low-pot payout
      _session!.totalChalkmanFeesPaid -=
          record.previousAccumulatedChalkmanFee + record.chalkmanFee;
    }
    _session!.accumulatedChalkmanFee = record.previousAccumulatedChalkmanFee;
    _session!.consecutiveLowPotGames = record.previousConsecutiveLowPotGames;

    // ── Reverse player balance changes ──────────────────────────────
    final wasDrawGame = record.drawPartnerNames != null &&
        record.drawPartnerNames!.isNotEmpty;
    final splitPrize = wasDrawGame
        ? record.prizePool / record.drawPartnerNames!.length
        : 0.0;

    for (final name in record.playerNames) {
      final player = _session!.findPlayer(name);
      if (player == null) continue;

      if (wasDrawGame) {
        final nameKey = name.trim().toLowerCase();
        final wasDrawPartner = record.drawPartnerNames!
            .any((d) => d.trim().toLowerCase() == nameKey);
        if (wasDrawPartner) {
          player.balance -= splitPrize;
        } else if (config.wagerPerPlayer > 0) {
          player.balance += config.wagerPerPlayer;
        }
      } else {
        final isWinner = record.winnerName != null &&
            name.trim().toLowerCase() ==
                record.winnerName!.trim().toLowerCase();
        if (isWinner) {
          player.balance -= record.prizePool;
        } else if (config.wagerPerPlayer > 0) {
          player.balance += config.wagerPerPlayer;
        }
      }
    }

    _notifyAndPersist();
  }

  // ── Display helpers ──────────────────────────────────────────────────────

  /// Current balance for [playerName] (what they can cash out right now).
  double? getBalance(String playerName) =>
      _session?.findPlayer(playerName)?.balance;

  /// For the winner between games: what they'd net if playing the next game
  /// (balance already has wager deducted via [continueSession]).
  /// For display only — just returns the same balance after continueSession.
  double? getBalanceIfPlaying(String winnerName) => getBalance(winnerName);

  /// Formatted KSH string (e.g. "+KSH 120" or "-KSH 50").
  static String formatKsh(double amount) {
    if (amount < 0) {
      return '-KSH ${(-amount).toStringAsFixed(0)}';
    }
    return '+KSH ${amount.toStringAsFixed(0)}';
  }
}
