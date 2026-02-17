import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/online_game_data.dart';
import '../utils/game_code_generator.dart';
import 'firebase_service.dart';

class OnlineGameService {
  static final _firestore = FirebaseFirestore.instance;
  static const _gamesCollection = 'games';

  /// Create an online game
  static Future<Game> createOnlineGame(Game localGame) async {
    final userId = FirebaseService.getUserId();
    final gameCode = GameCodeGenerator.generate();

    // Add online data to game
    final onlineData = OnlineGameData(
      gameCode: gameCode,
      hostId: userId,
      allowSpectators: true,
      viewers: {
        userId: ViewerData(
          userId: userId,
          role: UserRole.host,
        ),
      },
    );

    final onlineGame = Game(
      id: localGame.id,
      players: localGame.players,
      currentPlayerIndex: localGame.currentPlayerIndex,
      currentBallSequenceIndex: localGame.currentBallSequenceIndex,
      remainingBalls: localGame.remainingBalls,
      pocketedBalls: localGame.pocketedBalls,
      createdAt: localGame.createdAt,
      status: localGame.status,
      actions: localGame.actions,
      roundNumber: localGame.roundNumber,
      onlineData: onlineData,
    );

    // Save to Firestore
    await _firestore
        .collection(_gamesCollection)
        .doc(localGame.id)
        .set(onlineGame.toFirestore());

    debugPrint('Online game created with code: $gameCode');
    return onlineGame;
  }

  /// Join a game by code
  static Future<Game?> joinGameByCode(String code) async {
    final userId = FirebaseService.getUserId();
    final cleanCode = GameCodeGenerator.unformat(code);

    if (!GameCodeGenerator.isValid(cleanCode)) {
      throw Exception('Invalid game code format');
    }

    // Find game by code
    final querySnapshot = await _firestore
        .collection(_gamesCollection)
        .where('onlineData.gameCode', isEqualTo: cleanCode)
        .where('status', isEqualTo: GameStatus.active.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Game not found
    }

    final doc = querySnapshot.docs.first;
    final game = Game.fromFirestore(doc.data());

    // Add viewer
    await addViewer(game.id, userId, UserRole.spectator);

    return game;
  }

  /// Add viewer to game
  static Future<void> addViewer(
    String gameId,
    String userId,
    UserRole role, {
    String? playerName,
  }) async {
    await _firestore.collection(_gamesCollection).doc(gameId).update({
      'onlineData.viewers.$userId': ViewerData(
        userId: userId,
        role: role,
        playerName: playerName,
      ).toMap(),
    });
  }

  /// Update viewer presence
  static Future<void> updatePresence(String gameId, String userId) async {
    await _firestore.collection(_gamesCollection).doc(gameId).update({
      'onlineData.viewers.$userId.lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Sync game state to Firestore
  static Future<void> syncGame(Game game) async {
    await _firestore
        .collection(_gamesCollection)
        .doc(game.id)
        .update(game.toFirestore());
  }

  /// Listen to game updates
  static Stream<Game> listenToGame(String gameId) {
    return _firestore
        .collection(_gamesCollection)
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Game not found');
      }
      return Game.fromFirestore(snapshot.data()!);
    });
  }

  /// End online game
  static Future<void> endOnlineGame(String gameId) async {
    await _firestore.collection(_gamesCollection).doc(gameId).update({
      'status': GameStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete game
  static Future<void> deleteGame(String gameId) async {
    await _firestore.collection(_gamesCollection).doc(gameId).delete();
  }
}
