// Prize/financial tracking data models.
//
// All classes support toJson()/fromJson() so the active session can be
// persisted to SharedPreferences and restored after an app kill.
//
// Tracks wagers, board fees, chalkman fees, and player balances across
// multiple consecutive games in a "session".
//
// Balance semantics:
//   positive  → the session owes this amount TO the player (player is owed)
//   negative  → the player owes this amount TO the session (player owes)
//
// At game END:
//   - Winner  : balance += prizePool
//   - Losers  : balance -= wagerPerPlayer
// At REMATCH start (winner rolls over):
//   - Winner  : balance -= wagerPerPlayer  (commits wager for next game)

class PrizeConfig {
  final double wagerPerPlayer;    // KSH per player; 0 = no wager
  final double boardFeePerGame;   // default KSH 20
  final double chalkmanFeePerGame; // default KSH 10

  const PrizeConfig({
    required this.wagerPerPlayer,
    this.boardFeePerGame = 20.0,
    this.chalkmanFeePerGame = 10.0,
  });

  /// Total pot contributed by all players.
  double totalPot(int numPlayers) => wagerPerPlayer * numPlayers;

  /// Prize given to the winner (total pot minus board & chalkman fees).
  double prizePool(int numPlayers) {
    final pot = totalPot(numPlayers);
    final pool = pot - boardFeePerGame - chalkmanFeePerGame;
    return pool > 0 ? pool : 0;
  }

  /// Whether totalPot meets the threshold for immediate chalkman payment.
  /// Pot >= 100 → pay immediately. Pot < 100 → accumulate for 3 consecutive games.
  bool shouldPayChalkmanImmediately(int numPlayers) =>
      totalPot(numPlayers) >= 100;

  Map<String, dynamic> toJson() => {
    'wagerPerPlayer': wagerPerPlayer,
    'boardFeePerGame': boardFeePerGame,
    'chalkmanFeePerGame': chalkmanFeePerGame,
  };

  factory PrizeConfig.fromJson(Map<String, dynamic> json) => PrizeConfig(
    wagerPerPlayer: (json['wagerPerPlayer'] as num).toDouble(),
    boardFeePerGame: (json['boardFeePerGame'] as num).toDouble(),
    chalkmanFeePerGame: (json['chalkmanFeePerGame'] as num).toDouble(),
  );
}

/// Per-player financial record for the current session.
class PlayerPrizeInfo {
  final String _key; // normalised (lower-case, trimmed) for matching
  final String displayName;

  /// Running financial position for this session.
  double balance;

  /// Has this player confirmed their wager payment for the CURRENT game?
  bool wagerConfirmedThisGame;

  PlayerPrizeInfo({
    required this.displayName,
    this.balance = 0.0,
    this.wagerConfirmedThisGame = false,
  }) : _key = displayName.trim().toLowerCase();

  String get key => _key;
  bool get isOwed => balance > 0;
  bool get owes => balance < 0;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'balance': balance,
    'wagerConfirmedThisGame': wagerConfirmedThisGame,
  };

  factory PlayerPrizeInfo.fromJson(Map<String, dynamic> json) =>
      PlayerPrizeInfo(
        displayName: json['displayName'] as String,
        balance: (json['balance'] as num).toDouble(),
        wagerConfirmedThisGame: json['wagerConfirmedThisGame'] as bool? ?? false,
      );
}

/// Record of a single completed game within a session.
class PrizeGameRecord {
  final int gameNumber;
  final String? winnerName;
  final List<String> playerNames;
  final int numPlayers;
  final double totalPot;
  final double boardFee;
  final double chalkmanFee;

  /// Whether chalkman was paid right after this game (vs accumulated).
  final bool chalkmanPaidImmediately;

  /// Prize that went to the winner (null if it was a draw split).
  final double prizePool;

  /// Names of draw partners when the game ended in a draw (null = single winner).
  final List<String>? drawPartnerNames;

  /// Snapshot of accumulatedChalkmanFee BEFORE this game (for reversal).
  final double previousAccumulatedChalkmanFee;

  /// Snapshot of consecutiveLowPotGames BEFORE this game (for reversal).
  final int previousConsecutiveLowPotGames;

  final DateTime completedAt;

  const PrizeGameRecord({
    required this.gameNumber,
    required this.winnerName,
    required this.playerNames,
    required this.numPlayers,
    required this.totalPot,
    required this.boardFee,
    required this.chalkmanFee,
    required this.chalkmanPaidImmediately,
    required this.prizePool,
    required this.previousAccumulatedChalkmanFee,
    required this.previousConsecutiveLowPotGames,
    required this.completedAt,
    this.drawPartnerNames,
  });

  Map<String, dynamic> toJson() => {
    'gameNumber': gameNumber,
    'winnerName': winnerName,
    'playerNames': playerNames,
    'numPlayers': numPlayers,
    'totalPot': totalPot,
    'boardFee': boardFee,
    'chalkmanFee': chalkmanFee,
    'chalkmanPaidImmediately': chalkmanPaidImmediately,
    'prizePool': prizePool,
    'drawPartnerNames': drawPartnerNames,
    'previousAccumulatedChalkmanFee': previousAccumulatedChalkmanFee,
    'previousConsecutiveLowPotGames': previousConsecutiveLowPotGames,
    'completedAt': completedAt.toIso8601String(),
  };

  factory PrizeGameRecord.fromJson(Map<String, dynamic> json) =>
      PrizeGameRecord(
        gameNumber: json['gameNumber'] as int,
        winnerName: json['winnerName'] as String?,
        playerNames: List<String>.from(json['playerNames'] as List),
        numPlayers: json['numPlayers'] as int,
        totalPot: (json['totalPot'] as num).toDouble(),
        boardFee: (json['boardFee'] as num).toDouble(),
        chalkmanFee: (json['chalkmanFee'] as num).toDouble(),
        chalkmanPaidImmediately: json['chalkmanPaidImmediately'] as bool,
        prizePool: (json['prizePool'] as num).toDouble(),
        drawPartnerNames: json['drawPartnerNames'] != null
            ? List<String>.from(json['drawPartnerNames'] as List)
            : null,
        previousAccumulatedChalkmanFee:
            (json['previousAccumulatedChalkmanFee'] as num).toDouble(),
        previousConsecutiveLowPotGames:
            json['previousConsecutiveLowPotGames'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}

/// The full prize session: one or more consecutive games with the same group.
class PrizeSession {
  PrizeConfig config;
  final List<PlayerPrizeInfo> players;
  final List<PrizeGameRecord> gameRecords;

  /// Chalkman fees not yet formally paid (accumulated from low-pot games).
  double accumulatedChalkmanFee;

  /// Consecutive games where totalPot < 100 (for 3-game chalkman rule).
  int consecutiveLowPotGames;

  /// Running total of board fees collected.
  double totalBoardFees;

  /// Running total of chalkman fees that have been paid out.
  double totalChalkmanFeesPaid;

  PrizeSession({
    required this.config,
    required this.players,
  })  : gameRecords = [],
        accumulatedChalkmanFee = 0.0,
        consecutiveLowPotGames = 0,
        totalBoardFees = 0.0,
        totalChalkmanFeesPaid = 0.0;

  /// The upcoming game number (1-based).
  int get currentGameNumber => gameRecords.length + 1;

  int get totalGamesPlayed => gameRecords.length;

  /// Name of the last game's winner (null if no game recorded yet).
  String? get lastWinnerName =>
      gameRecords.isEmpty ? null : gameRecords.last.winnerName;

  /// Look up a player by name (case-insensitive).
  PlayerPrizeInfo? findPlayer(String name) {
    final key = name.trim().toLowerCase();
    try {
      return players.firstWhere((p) => p.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Ensure all given names have a [PlayerPrizeInfo] entry (add if missing).
  void ensurePlayers(List<String> names) {
    for (final name in names) {
      if (findPlayer(name) == null) {
        players.add(PlayerPrizeInfo(displayName: name));
      }
    }
  }

  /// Reset wager confirmations for a new game round.
  void resetWagerConfirmations() {
    for (final p in players) {
      p.wagerConfirmedThisGame = false;
    }
  }

  Map<String, dynamic> toJson() => {
    'config': config.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'gameRecords': gameRecords.map((r) => r.toJson()).toList(),
    'accumulatedChalkmanFee': accumulatedChalkmanFee,
    'consecutiveLowPotGames': consecutiveLowPotGames,
    'totalBoardFees': totalBoardFees,
    'totalChalkmanFeesPaid': totalChalkmanFeesPaid,
  };

  factory PrizeSession.fromJson(Map<String, dynamic> json) {
    final session = PrizeSession(
      config: PrizeConfig.fromJson(json['config'] as Map<String, dynamic>),
      players: (json['players'] as List)
          .map((p) => PlayerPrizeInfo.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
    for (final r in (json['gameRecords'] as List)) {
      session.gameRecords
          .add(PrizeGameRecord.fromJson(r as Map<String, dynamic>));
    }
    session.accumulatedChalkmanFee =
        (json['accumulatedChalkmanFee'] as num).toDouble();
    session.consecutiveLowPotGames = json['consecutiveLowPotGames'] as int;
    session.totalBoardFees = (json['totalBoardFees'] as num).toDouble();
    session.totalChalkmanFeesPaid =
        (json['totalChalkmanFeesPaid'] as num).toDouble();
    return session;
  }
}
