import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/action.dart';
import '../models/game_rules.dart';
import '../services/game_logic_service.dart';
import '../services/database_service.dart';
import '../services/online_game_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  Game? _currentGame;
  List<Game> _gameHistory = [];
  List<Game> _activeGames = [];
  bool _isLoading = false;
  String? _lastEvent; // For showing snackbar messages
  bool _isMoneyBallWin = false; // Flag for money ball victory
  Player? _moneyBallWinner; // Stores the money ball winner for celebration
  GameRules _rules = GameRules.defaults(); // Current game rules
  StreamSubscription<Game>? _gameStreamSubscription; // For online game sync

  Game? get currentGame => _currentGame;
  List<Game> get gameHistory => _gameHistory;
  List<Game> get activeGames => _activeGames;
  bool get isLoading => _isLoading;
  String? get lastEvent => _lastEvent;
  bool get isMoneyBallWin => _isMoneyBallWin;
  Player? get moneyBallWinner => _moneyBallWinner;
  GameRules get rules => _rules;

  void clearLastEvent() {
    _lastEvent = null;
  }

  // Update current rules (called from widgets with access to RulesProvider)
  void updateRules(GameRules newRules) {
    _rules = newRules;
    // Sync with AppConstants so existing game logic uses custom rules
    AppConstants.customRules = newRules;
    notifyListeners();
  }

  void _clearMoneyBallWin() {
    _isMoneyBallWin = false;
    _moneyBallWinner = null;
  }

  // ========== GAME CREATION ==========

  Future<Game> createGame(List<String> playerNames) async {
    final players = playerNames.map((name) {
      return Player(id: _uuid.v4(), name: name);
    }).toList();

    final game = Game(
      id: _uuid.v4(),
      players: players,
    );

    _currentGame = game;
    _clearMoneyBallWin(); // Reset money ball win flag for new game
    await DatabaseService.saveGame(game);
    await loadActiveGames();
    notifyListeners();
    return game;
  }

  // ========== GAME LOADING ==========

  Future<void> loadGame(String gameId) async {
    _isLoading = true;
    notifyListeners();

    _currentGame = await DatabaseService.getGame(gameId);
    _clearMoneyBallWin(); // Reset money ball win flag when loading game

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveGames() async {
    _activeGames = await DatabaseService.getActiveGames();
    notifyListeners();
  }

  Future<void> loadGameHistory() async {
    _gameHistory = await DatabaseService.getAllGames();
    notifyListeners();
  }

  // ========== ONLINE GAME MANAGEMENT ==========

  /// Set current game directly (used when joining online games)
  void setCurrentGame(Game game) {
    _currentGame = game;
    _clearMoneyBallWin();
    notifyListeners();
  }

  /// Create an online game from the current local game
  Future<Game> createOnlineGame() async {
    if (_currentGame == null) {
      throw Exception('No active game to convert to online');
    }

    final onlineGame = await OnlineGameService.createOnlineGame(_currentGame!);
    _currentGame = onlineGame;

    // Start listening to real-time updates
    await _listenToOnlineGame(onlineGame.id);

    notifyListeners();
    return onlineGame;
  }

  /// Listen to real-time game updates (for online games)
  Future<void> _listenToOnlineGame(String gameId) async {
    await _gameStreamSubscription?.cancel();

    _gameStreamSubscription = OnlineGameService.listenToGame(gameId).listen(
      (updatedGame) {
        _currentGame = updatedGame;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to game: $error');
        _lastEvent = 'Connection error: $error';
        notifyListeners();
      },
    );
  }

  /// Stop listening to online game updates
  Future<void> stopListeningToGame() async {
    await _gameStreamSubscription?.cancel();
    _gameStreamSubscription = null;
  }

  /// Sync current game state to Firestore (for online games)
  Future<void> _syncOnlineGame() async {
    if (_currentGame != null && _currentGame!.isOnline) {
      await OnlineGameService.syncGame(_currentGame!);
    }
  }

  @override
  void dispose() {
    _gameStreamSubscription?.cancel();
    super.dispose();
  }

  // ========== SCORING ACTIONS ==========

  Future<void> pocketBall() async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    // Check if this ball is the money ball BEFORE pocketing
    final moneyBallLeader = GameLogicService.checkMoneyBall(_currentGame!);
    final isMoneyBall = moneyBallLeader != null &&
                        moneyBallLeader.id == _currentGame!.currentPlayer.id;

    GameLogicService.applySuccessfulPocket(_currentGame!);
    _lastEvent =
        '${_currentGame!.currentPlayer.name} pocketed ball ${_currentGame!.actions.last.ballNumber}';

    // Store money ball info for celebration if this was the money ball
    if (isMoneyBall) {
      _moneyBallWinner = moneyBallLeader;
    }

    await _postAction(isMoneyBallPocket: isMoneyBall);
  }

  Future<void> combinationShot(int pocketedBall) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    // Check if the pocketed ball is the money ball BEFORE pocketing
    final moneyBallLeader = GameLogicService.checkMoneyBall(_currentGame!);
    final isMoneyBall = moneyBallLeader != null &&
                        moneyBallLeader.id == _currentGame!.currentPlayer.id &&
                        pocketedBall == _currentGame!.currentTargetBall;

    GameLogicService.applyCombinationShot(_currentGame!, pocketedBall);
    _lastEvent = 'Combo: ball $pocketedBall pocketed';

    // Store money ball info for celebration if this was the money ball
    if (isMoneyBall) {
      _moneyBallWinner = moneyBallLeader;
    }

    await _postAction(isMoneyBallPocket: isMoneyBall);
  }

  Future<void> throughShot(List<int> ballNumbers) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.applyThroughShot(_currentGame!, ballNumbers);
    final ballsStr = ballNumbers.join(', ');
    _lastEvent = 'Through shot: ball(s) $ballsStr + cue (0 pts)';

    await _postAction();
  }

  Future<void> throughFoul(List<int> ballNumbers) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;
    if (ballNumbers.isEmpty) return;

    GameLogicService.applyThroughFoul(_currentGame!, ballNumbers);
    final penaltyBall = ballNumbers.first;
    final penalty = _rules.getBallValue(penaltyBall);
    final ballsStr = ballNumbers.join(', ');
    _lastEvent = 'Through + Foul: ball(s) $ballsStr pocketed (-$penalty pts)';

    await _postAction();
  }

  Future<void> applyPenalty(ActionType penaltyType, {int? ballNumber}) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.applyPenalty(_currentGame!, penaltyType,
        ballNumber: ballNumber);
    _lastEvent = '${penaltyType.label}: -${_currentGame!.actions.last.pointsChange.abs()} pts';

    await _postAction();
  }

  Future<void> missShot() async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.applyMiss(_currentGame!);
    _lastEvent =
        '${_currentGame!.actions.last.description}';

    await _postAction();
  }

  Future<void> nextPlayer() async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.advanceTurn(_currentGame!);
    _lastEvent = 'Next player: ${_currentGame!.currentPlayer.name}';

    await _saveCurrentGame();
    notifyListeners();
  }

  Future<void> selectPlayer(String playerId) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    // Find the player index by ID
    final playerIndex = _currentGame!.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return; // Player not found

    final player = _currentGame!.players[playerIndex];
    if (player.isEliminated) return;

    _currentGame!.currentPlayerIndex = playerIndex;
    _lastEvent = 'Selected: ${player.name}';
    await _saveCurrentGame();
    notifyListeners();
  }

  // ========== MID-GAME PLAYER MANAGEMENT ==========

  Future<void> addPlayerMidGame(String name) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    final newPlayer = Player(id: _uuid.v4(), name: name);
    _currentGame!.players.add(newPlayer);

    _lastEvent = '${newPlayer.name} joined the game!';
    await _saveCurrentGame();
    notifyListeners();
  }

  Future<void> removePlayerMidGame(String playerId) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    final game = _currentGame!;
    final activePlayers = game.activePlayers;

    final playerToRemove = game.players.firstWhere((p) => p.id == playerId);

    // Cannot remove if only 2 active players remain
    if (!playerToRemove.isEliminated && activePlayers.length <= 2) {
      _lastEvent = 'Cannot remove: minimum 2 active players required';
      notifyListeners();
      return;
    }

    final removedIndex = game.players.indexWhere((p) => p.id == playerId);
    if (removedIndex == -1) return;

    final removedName = game.players[removedIndex].name;

    // If the removed player is the current player, advance turn first
    if (removedIndex == game.currentPlayerIndex) {
      game.currentPlayerIndex = GameLogicService.getNextPlayerIndex(game);
    }

    // Remove the player
    game.players.removeAt(removedIndex);

    // Adjust currentPlayerIndex if removed player was before current
    if (removedIndex < game.currentPlayerIndex) {
      game.currentPlayerIndex--;
    }

    // Clamp index to valid range
    if (game.currentPlayerIndex >= game.players.length) {
      game.currentPlayerIndex = 0;
    }

    // Ensure current player is not eliminated
    if (game.players[game.currentPlayerIndex].isEliminated) {
      game.currentPlayerIndex = GameLogicService.getNextPlayerIndex(game);
    }

    _lastEvent = '$removedName removed from game';
    await _saveCurrentGame();
    notifyListeners();
  }

  // ========== POST-ACTION PROCESSING ==========

  Future<void> _postAction({bool isMoneyBallPocket = false}) async {
    if (_currentGame == null) return;

    // Check re-entries first (leader may have lost points from fouls,
    // letting eliminated players back in)
    final reEntered = GameLogicService.checkReEntries(_currentGame!);
    for (final player in reEntered) {
      _lastEvent = '${player.name} is back in the game!';
    }

    // Check eliminations (scores stay intact - no handicap)
    final eliminated = GameLogicService.checkEliminations(_currentGame!);
    for (final player in eliminated) {
      _lastEvent = '${player.name} eliminated!';
    }

    // Check early win
    if (GameLogicService.checkEarlyWin(_currentGame!)) {
      final winner = _currentGame!.players.firstWhere(
          (p) => p.id == _currentGame!.winnerId);

      // Special handling for money ball wins
      if (isMoneyBallPocket && _moneyBallWinner != null) {
        _isMoneyBallWin = true;
        _lastEvent = '${winner.name} pocketed the money ball and wins!';
      } else {
        _lastEvent = '${winner.name} wins!';
      }
      GameLogicService.assignRankings(_currentGame!);
    }

    // Check natural game over
    if (GameLogicService.checkGameOver(_currentGame!)) {
      if (_currentGame!.winnerId != null) {
        final winner = _currentGame!.players.firstWhere(
            (p) => p.id == _currentGame!.winnerId);
        _lastEvent = '${winner.name} wins!';
      }
      GameLogicService.assignRankings(_currentGame!);
    }

    // Money ball alert (only if game is still active)
    if (!_currentGame!.isGameOver) {
      final moneyBallPlayers =
          GameLogicService.checkMoneyBallPlayers(_currentGame!);
      if (moneyBallPlayers.isNotEmpty) {
        final ball = _currentGame!.currentTargetBall;
        final names = moneyBallPlayers.map((p) => p.name).join(' & ');
        _lastEvent = 'Ball $ball is the money ball for $names!';
      }
    }

    await _saveCurrentGame();
    notifyListeners();
  }

  // ========== UNDO ==========

  Future<void> undoLastAction() async {
    if (_currentGame == null || _currentGame!.actions.isEmpty) return;

    final success = GameLogicService.undoLastAction(_currentGame!);
    if (success) {
      _lastEvent = 'Action undone';
      await _saveCurrentGame();
      notifyListeners();
    }
  }

  // ========== MANUAL ADJUSTMENTS ==========

  /// Manually set a player's score (for corrections)
  Future<void> manualEditScore(String playerId, int newScore) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    final player = _currentGame!.players.firstWhere((p) => p.id == playerId);
    final oldScore = player.score;
    player.score = newScore;

    _lastEvent = '${player.name}: score adjusted from $oldScore to $newScore';

    // Recalculate eliminations based on new scores
    GameLogicService.recalculateEliminations(_currentGame!);

    await _saveCurrentGame();
    notifyListeners();
  }

  /// Restore a pocketed ball back to the table
  Future<void> restoreBall(int ballNumber) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    final game = _currentGame!;
    if (!game.pocketedBalls.contains(ballNumber)) return;

    game.pocketedBalls.remove(ballNumber);
    game.remainingBalls.add(ballNumber);
    game.remainingBalls.sort();

    _lastEvent = 'Ball $ballNumber restored to the table';

    // Recalculate eliminations since remaining ball value changed
    GameLogicService.recalculateEliminations(game);

    await _saveCurrentGame();
    notifyListeners();
  }

  // ========== GAME MANAGEMENT ==========

  Future<void> abandonGame() async {
    if (_currentGame == null) return;

    _currentGame!.status = GameStatus.abandoned;
    _currentGame!.completedAt = DateTime.now();
    GameLogicService.assignRankings(_currentGame!);

    await _saveCurrentGame();
    await loadActiveGames();
    _currentGame = null;
    notifyListeners();
  }

  Future<void> deleteGame(String gameId) async {
    await DatabaseService.deleteGame(gameId);
    await loadActiveGames();
    await loadGameHistory();
    if (_currentGame?.id == gameId) {
      _currentGame = null;
    }
    notifyListeners();
  }

  Future<void> _saveCurrentGame() async {
    if (_currentGame == null) return;
    await DatabaseService.updateGame(_currentGame!);
    await _syncOnlineGame(); // Sync to Firestore if online game
  }
}
