import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { host, player, spectator }

class OnlineGameData {
  final String gameCode;
  final String hostId;
  final bool allowSpectators;
  final bool isPublic;
  final Map<String, ViewerData> viewers;
  final DateTime lastSyncAt;

  OnlineGameData({
    required this.gameCode,
    required this.hostId,
    this.allowSpectators = true,
    this.isPublic = false,
    Map<String, ViewerData>? viewers,
    DateTime? lastSyncAt,
  })  : viewers = viewers ?? {},
        lastSyncAt = lastSyncAt ?? DateTime.now();

  bool isHost(String? userId) => userId != null && hostId == userId;

  Map<String, dynamic> toFirestore() {
    return {
      'gameCode': gameCode,
      'hostId': hostId,
      'allowSpectators': allowSpectators,
      'isPublic': isPublic,
      'viewers': viewers.map((k, v) => MapEntry(k, v.toMap())),
      'lastSyncAt': FieldValue.serverTimestamp(),
    };
  }

  factory OnlineGameData.fromFirestore(Map<String, dynamic> data) {
    return OnlineGameData(
      gameCode: data['gameCode'] as String,
      hostId: data['hostId'] as String,
      allowSpectators: data['allowSpectators'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? false,
      viewers: (data['viewers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, ViewerData.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      lastSyncAt: (data['lastSyncAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ViewerData {
  final String userId;
  final UserRole role;
  final String? playerName;
  final DateTime joinedAt;
  final DateTime lastSeen;

  ViewerData({
    required this.userId,
    required this.role,
    this.playerName,
    DateTime? joinedAt,
    DateTime? lastSeen,
  })  : joinedAt = joinedAt ?? DateTime.now(),
        lastSeen = lastSeen ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'playerName': playerName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  factory ViewerData.fromMap(Map<String, dynamic> map) {
    return ViewerData(
      userId: map['userId'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      playerName: map['playerName'] as String?,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
    );
  }
}
