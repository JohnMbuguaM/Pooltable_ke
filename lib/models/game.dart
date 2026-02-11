import 'player.dart';
import 'action.dart';
import '../utils/constants.dart';

enum GameStatus { active, completed, abandoned }

class Game {
  final String id;
  List<Player> players;
  int currentPlayerIndex;
  int currentBallSequenceIndex; // Index into AppConstants.ballSequence
  List<int> remainingBalls;
  List<int> pocketedBalls;
  DateTime createdAt;
  DateTime? completedAt;
  GameStatus status;
  String? winnerId;
  List<GameAction> actions;
  int roundNumber;

  Game({
    required this.id,
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentBallSequenceIndex = 0,
    List<int>? remainingBalls,
    List<int>? pocketedBalls,
    DateTime? createdAt,
    this.completedAt,
    this.status = GameStatus.active,
    this.winnerId,
    List<GameAction>? actions,
    this.roundNumber = 1,
  })  : remainingBalls = remainingBalls ?? List.from(AppConstants.allBalls),
        pocketedBalls = pocketedBalls ?? [],
        createdAt = createdAt ?? DateTime.now(),
        actions = actions ?? [];

  int get currentTargetBall {
    // Walk the sequence to find the next ball still on the table
    for (int i = 0; i < AppConstants.ballSequence.length; i++) {
      int seqIdx = (currentBallSequenceIndex + i) % AppConstants.ballSequence.length;
      int ball = AppConstants.ballSequence[seqIdx];
      if (remainingBalls.contains(ball)) {
        return ball;
      }
    }
    return -1; // No balls left
  }

  Player get currentPlayer => players[currentPlayerIndex];

  List<Player> get activePlayers =>
      players.where((p) => !p.isEliminated).toList();

  List<Player> get eliminatedPlayers =>
      players.where((p) => p.isEliminated).toList();

  int get remainingBallsValue =>
      remainingBalls.fold(0, (sum, ball) => sum + AppConstants.getBallValue(ball));

  Player? get leader {
    final active = activePlayers;
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.score >= b.score ? a : b);
  }

  bool get isGameOver => status != GameStatus.active;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'current_player_index': currentPlayerIndex,
      'current_ball_sequence_index': currentBallSequenceIndex,
      'remaining_balls': remainingBalls.join(','),
      'pocketed_balls': pocketedBalls.join(','),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.index,
      'winner_id': winnerId,
      'round_number': roundNumber,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map,
      {List<Player>? players, List<GameAction>? actions}) {
    return Game(
      id: map['id'] as String,
      players: players ?? [],
      currentPlayerIndex: map['current_player_index'] as int? ?? 0,
      currentBallSequenceIndex: map['current_ball_sequence_index'] as int? ?? 0,
      remainingBalls: (map['remaining_balls'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          List.from(AppConstants.allBalls),
      pocketedBalls: (map['pocketed_balls'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      status: GameStatus.values[map['status'] as int? ?? 0],
      winnerId: map['winner_id'] as String?,
      actions: actions ?? [],
      roundNumber: map['round_number'] as int? ?? 1,
    );
  }
}
