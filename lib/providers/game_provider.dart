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

  Game? get currentGame => _currentGame;
  List<Game> get gameHistory => _gameHistory;
  List<Game> get activeGames => _activeGames;
  bool get isLoading => _isLoading;
  String? get lastEvent => _lastEvent;

  void clearLastEvent() {
    _lastEvent = null;
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

    GameLogicService.applySuccessfulPocket(_currentGame!);
    _lastEvent =
        '${_currentGame!.currentPlayer.name} pocketed ball ${_currentGame!.actions.last.ballNumber}';

    await _postAction();
  }

  Future<void> combinationShot(int pocketedBall) async {
    if (_currentGame == null || _currentGame!.isGameOver) return;

    GameLogicService.applyCombinationShot(_currentGame!, pocketedBall);
    _lastEvent = 'Combo: ball $pocketedBall pocketed';

    await _postAction();
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

    GameLogicService.advanceTurn(_currentGame!);
    _lastEvent = 'Miss - next player';

    await _saveCurrentGame();
    notifyListeners();
  }

  // ========== POST-ACTION PROCESSING ==========

  Future<void> _postAction() async {
    if (_currentGame == null) return;

    // Check eliminations
    final eliminated = GameLogicService.checkEliminations(_currentGame!);
    for (final player in eliminated) {
      _lastEvent = '${player.name} eliminated!';
      GameLogicService.applyHandicap(_currentGame!, player);
    }

    // Check early win
    if (GameLogicService.checkEarlyWin(_currentGame!)) {
      final winner = _currentGame!.players.firstWhere(
          (p) => p.id == _currentGame!.winnerId);
      _lastEvent = '${winner.name} wins!';
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
