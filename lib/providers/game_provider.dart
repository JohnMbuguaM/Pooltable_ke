import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/action.dart';
import '../services/game_logic_service.dart';
import '../services/database_service.dart';

class GameProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  Game? _currentGame;
  List<Game> _gameHistory = [];
  List<Game> _activeGames = [];
  bool _isLoading = false;
  String? _lastEvent; // For showing snackbar messages
  bool _isMoneyBallWin = false; // Flag for money ball victory
  Player? _moneyBallWinner; // Stores the money ball winner for celebration

  Game? get currentGame => _currentGame;
  List<Game> get gameHistory => _gameHistory;
  List<Game> get activeGames => _activeGames;
  bool get isLoading => _isLoading;
  String? get lastEvent => _lastEvent;
  bool get isMoneyBallWin => _isMoneyBallWin;
  Player? get moneyBallWinner => _moneyBallWinner;

  void clearLastEvent() {
    _lastEvent = null;
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

  Future<void> neutralShot({bool bothJumpedOff = false}) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.applyNeutralShot(_currentGame!,
        bothJumpedOff: bothJumpedOff);
    _lastEvent = bothJumpedOff ? 'Both balls jumped off' : 'Neutral shot';

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

  Future<void> selectPlayer(int playerIndex) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;
    if (playerIndex < 0 || playerIndex >= _currentGame!.players.length) return;
    if (_currentGame!.players[playerIndex].isEliminated) return;

    _currentGame!.currentPlayerIndex = playerIndex;
    _lastEvent = 'Selected: ${_currentGame!.currentPlayer.name}';
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
      final moneyBallLeader =
          GameLogicService.checkMoneyBall(_currentGame!);
      if (moneyBallLeader != null) {
        final ball = _currentGame!.currentTargetBall;
        _lastEvent =
            'Ball $ball is the money ball for ${moneyBallLeader.name}!';
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
  }
}
