import 'package:cloud_firestore/cloud_firestore.dart';
import 'player.dart';
import 'action.dart';
import 'online_game_data.dart';
import '../utils/constants.dart';

enum GameStatus { active, completed, abandoned, draw }

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
  List<String>? drawPlayerIds; // non-null only when status == GameStatus.draw
  List<GameAction> actions;
  int roundNumber;
  OnlineGameData? onlineData; // null for local games

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
    this.drawPlayerIds,
    List<GameAction>? actions,
    this.roundNumber = 1,
    this.onlineData,
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
      remainingBalls.fold(0, (acc, ball) => acc + AppConstants.getBallValue(ball));

  Player? get leader {
    final active = activePlayers;
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.score >= b.score ? a : b);
  }

  bool get isGameOver => status != GameStatus.active;

  // Online game helpers
  bool get isOnline => onlineData != null;
  String? get gameCode => onlineData?.gameCode;

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
      'draw_player_ids': drawPlayerIds?.join(','),
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
      drawPlayerIds: (map['draw_player_ids'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList(),
      actions: actions ?? [],
      roundNumber: map['round_number'] as int? ?? 1,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'players': players.map((p) => p.toMap()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'currentBallSequenceIndex': currentBallSequenceIndex,
      'remainingBalls': remainingBalls,
      'pocketedBalls': pocketedBalls,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'winnerId': winnerId,
      'drawPlayerIds': drawPlayerIds,
      'actions': actions.map((a) => a.toMap()).toList(),
      'roundNumber': roundNumber,
      if (onlineData != null) 'onlineData': onlineData!.toFirestore(),
    };
  }

  factory Game.fromFirestore(Map<String, dynamic> data) {
    return Game(
      id: data['id'] as String,
      players: (data['players'] as List)
          .map((p) => Player.fromMap(p as Map<String, dynamic>))
          .toList(),
      currentPlayerIndex: data['currentPlayerIndex'] as int? ?? 0,
      currentBallSequenceIndex: data['currentBallSequenceIndex'] as int? ?? 0,
      remainingBalls: List<int>.from(data['remainingBalls'] as List),
      pocketedBalls: List<int>.from(data['pocketedBalls'] as List),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
      status: GameStatus.values.firstWhere((e) => e.name == data['status']),
      winnerId: data['winnerId'] as String?,
      drawPlayerIds: data['drawPlayerIds'] != null
          ? List<String>.from(data['drawPlayerIds'] as List)
          : null,
      actions: (data['actions'] as List)
          .map((a) => GameAction.fromMap(a as Map<String, dynamic>))
          .toList(),
      roundNumber: data['roundNumber'] as int? ?? 1,
      onlineData: data['onlineData'] != null
          ? OnlineGameData.fromFirestore(data['onlineData'] as Map<String, dynamic>)
          : null,
    );
  }
}
