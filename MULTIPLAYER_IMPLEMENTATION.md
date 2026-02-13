# 🌐 Firebase Multiplayer Implementation Guide

Complete guide to adding real-time multiplayer and spectator mode to ChalkMan.

---

## 📋 Table of Contents

1. [Firebase Project Setup](#firebase-project-setup)
2. [Code Implementation](#code-implementation)
3. [Security Rules](#security-rules)
4. [Testing Guide](#testing-guide)
5. [Troubleshooting](#troubleshooting)

---

## 🔥 Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Project name: `ChalkMan` (or your choice)
4. Disable Google Analytics (optional for this project)
5. Click "Create project"

### Step 2: Add Android App

1. In Firebase Console, click Android icon
2. **Android package name**: `com.pooltableke.pooltable_ke`
   (Must match your `android/app/build.gradle`)
3. **App nickname**: ChalkMan Android
4. **SHA-1**: Optional for now (needed for advanced auth)
5. Click "Register app"
6. Download `google-services.json`
7. Place file in: `android/app/google-services.json`

### Step 3: Add iOS App (if building for iOS)

1. Click iOS icon in Firebase Console
2. **Bundle ID**: Get from `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

### Step 4: Enable Firestore

1. In Firebase Console → Build → Firestore Database
2. Click "Create database"
3. **Start mode**: Production mode
4. **Location**: Choose closest to your users
5. Click "Enable"

### Step 5: Enable Anonymous Authentication

1. In Firebase Console → Build → Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Anonymous"
5. Click "Save"

### Step 6: Update Android build.gradle

**File**: `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File**: `android/app/build.gradle`

```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

---

## 💻 Code Implementation

### Step 1: Install Dependencies

The packages are already added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

### Step 2: Create Online Game Model

**File**: `lib/models/online_game_data.dart`

```dart
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
```

### Step 3: Update Game Model

**File**: `lib/models/game.dart`

Add these fields to the `Game` class:

```dart
// Add at the top of Game class
OnlineGameData? onlineData; // null for local games

// Update constructor
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
  this.onlineData, // Add this
})  : remainingBalls = remainingBalls ?? List.from(AppConstants.allBalls),
      pocketedBalls = pocketedBalls ?? [],
      createdAt = createdAt ?? DateTime.now(),
      actions = actions ?? [];

// Add helper getters
bool get isOnline => onlineData != null;
String? get gameCode => onlineData?.gameCode;
```

Add Firestore serialization methods:

```dart
// Convert Game to Firestore document
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
    'actions': actions.map((a) => a.toMap()).toList(),
    'roundNumber': roundNumber,
    if (onlineData != null) 'onlineData': onlineData!.toFirestore(),
  };
}

// Create Game from Firestore document
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
    actions: (data['actions'] as List)
        .map((a) => GameAction.fromMap(a as Map<String, dynamic>))
        .toList(),
    roundNumber: data['roundNumber'] as int? ?? 1,
    onlineData: data['onlineData'] != null
        ? OnlineGameData.fromFirestore(data['onlineData'] as Map<String, dynamic>)
        : null,
  );
}
```

### Step 4: Create Online Game Service

**File**: `lib/services/online_game_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/player.dart';
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
```

### Step 5: Create Join Game Screen

**File**: `lib/screens/join_game_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/online_game_service.dart';
import '../utils/game_code_generator.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a game code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final game = await OnlineGameService.joinGameByCode(code);

      if (game == null) {
        setState(() => _errorMessage = 'Game not found');
        return;
      }

      if (!mounted) return;

      // Load game into provider
      final gameProvider = context.read<GameProvider>();
      await gameProvider.loadOnlineGame(game);

      if (!mounted) return;

      // Navigate to game screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error joining game: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: AppTheme.feltGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Game Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the host for the 6-character code',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'ABC-123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
                errorText: _errorMessage,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 7,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  String text = newValue.text.toUpperCase().replaceAll('-', '');
                  if (text.length > 3) {
                    text = '${text.substring(0, 3)}-${text.substring(3)}';
                  }
                  return TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              onSubmitted: (_) => _joinGame(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _joinGame,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_isLoading ? 'Joining...' : 'Join Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.feltGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔐 Security Rules

In Firebase Console → Firestore → Rules, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isGameHost(gameData) {
      return isSignedIn() &&
             request.auth.uid == gameData.onlineData.hostId;
    }

    function isGameViewer(gameData) {
      return isSignedIn() &&
             request.auth.uid in gameData.onlineData.viewers;
    }

    // Games collection
    match /games/{gameId} {
      // Anyone authenticated can read (if they have the code)
      allow read: if isSignedIn();

      // Only authenticated users can create
      allow create: if isSignedIn();

      // Only host or players can update
      allow update: if isSignedIn() &&
                      (isGameHost(resource.data) ||
                       isGameViewer(resource.data));

      // Only host can delete
      allow delete: if isSignedIn() &&
                      isGameHost(resource.data);
    }
  }
}
```

Click **Publish** to activate the rules.

---

## 🧪 Testing Guide

### Test 1: Create Online Game

1. Run app on Device 1
2. Tap "New Game" → Create local game
3. In game screen, tap "Share" (implement share button)
4. Get game code (e.g., `ABC123`)

### Test 2: Join Game

1. Run app on Device 2
2. Tap "Join Game"
3. Enter code from Device 1
4. Verify scoreboard loads

### Test 3: Real-time Sync

1. On Device 1: Pocket a ball
2. On Device 2: Verify score updates instantly
3. Repeat with multiple actions

### Test 4: Multiple Spectators

1. Join same game from 3+ devices
2. Verify all see real-time updates
3. Check viewer count

---

## 🐛 Troubleshooting

### Issue: "Firebase not initialized"

**Solution:** Add Firebase initialization in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ChalkManApp());
}
```

### Issue: "Permission denied" in Firestore

**Solution:** Verify security rules are published and user is signed in anonymously.

### Issue: Game not found by code

**Solution:** Check Firestore indexes. Create composite index for:
- Collection: `games`
- Fields: `onlineData.gameCode` (Ascending), `status` (Ascending)

### Issue: Real-time updates not working

**Solution:** Ensure listener is active in `GameProvider`. Add:

```dart
StreamSubscription? _gameSubscription;

void listenToOnlineGame(String gameId) {
  _gameSubscription?.cancel();
  _gameSubscription = OnlineGameService.listenToGame(gameId).listen(
    (updatedGame) {
      _currentGame = updatedGame;
      notifyListeners();
    },
    onError: (error) {
      debugPrint('Error listening to game: $error');
    },
  );
}

@override
void dispose() {
  _gameSubscription?.cancel();
  super.dispose();
}
```

---

## ✅ Next Steps

After completing this guide:

1. **Test thoroughly** with multiple devices
2. **Add share functionality** (QR codes, links)
3. **Add presence indicators** (who's online)
4. **Add turn notifications** (when it's your turn)
5. **Add game discovery** (browse public games)
6. **Add chat/reactions** (optional)

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console logs
2. Enable debug logging: `FirebaseFirestore.setLoggingEnabled(true)`
3. Verify all config files are in place
4. Check network connectivity

---

**Good luck! 🚀**
