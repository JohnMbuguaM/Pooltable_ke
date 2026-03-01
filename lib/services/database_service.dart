import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/action.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY,
        current_player_index INTEGER NOT NULL DEFAULT 0,
        current_ball_sequence_index INTEGER NOT NULL DEFAULT 0,
        remaining_balls TEXT NOT NULL,
        pocketed_balls TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        completed_at TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        winner_id TEXT,
        draw_player_ids TEXT,
        round_number INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        name TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        is_eliminated INTEGER NOT NULL DEFAULT 0,
        rank INTEGER NOT NULL DEFAULT 0,
        eliminated_at_round INTEGER,
        player_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE actions (
        id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        type INTEGER NOT NULL,
        ball_number INTEGER,
        points_change INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT,
        previous_score INTEGER,
        previous_current_ball_index INTEGER,
        previous_remaining_balls TEXT,
        previous_pocketed_balls TEXT,
        previous_is_eliminated INTEGER DEFAULT 0,
        action_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_players_game ON players(game_id)');
    await db.execute(
        'CREATE INDEX idx_actions_game ON actions(game_id)');
    await db.execute(
        'CREATE INDEX idx_actions_player ON actions(player_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: add draw_player_ids column
      await db.execute(
          'ALTER TABLE games ADD COLUMN draw_player_ids TEXT');
    }
  }

  // ========== GAME CRUD ==========

  static Future<void> saveGame(Game game) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'games',
        game.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save players
      for (int i = 0; i < game.players.length; i++) {
        final playerMap = game.players[i].toMap();
        playerMap['game_id'] = game.id;
        playerMap['player_order'] = i;
        await txn.insert(
          'players',
          playerMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Save actions
      for (int i = 0; i < game.actions.length; i++) {
        final actionMap = game.actions[i].toMap();
        actionMap['action_order'] = i;
        await txn.insert(
          'actions',
          actionMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> updateGame(Game game) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'games',
        game.toMap(),
        where: 'id = ?',
        whereArgs: [game.id],
      );

      // Update players
      for (int i = 0; i < game.players.length; i++) {
        final playerMap = game.players[i].toMap();
        playerMap['game_id'] = game.id;
        playerMap['player_order'] = i;
        await txn.insert(
          'players',
          playerMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Delete players no longer in the game (removed mid-game)
      final currentPlayerIds = game.players.map((p) => p.id).toList();
      if (currentPlayerIds.isNotEmpty) {
        final placeholders = List.filled(currentPlayerIds.length, '?').join(',');
        await txn.rawDelete(
          'DELETE FROM players WHERE game_id = ? AND id NOT IN ($placeholders)',
          [game.id, ...currentPlayerIds],
        );
      }

      // Delete old actions and re-insert (simpler for undo support)
      await txn.delete('actions', where: 'game_id = ?', whereArgs: [game.id]);
      for (int i = 0; i < game.actions.length; i++) {
        final actionMap = game.actions[i].toMap();
        actionMap['action_order'] = i;
        await txn.insert('actions', actionMap);
      }
    });
  }

  static Future<Game?> getGame(String gameId) async {
    final db = await database;

    final gameMaps =
        await db.query('games', where: 'id = ?', whereArgs: [gameId]);
    if (gameMaps.isEmpty) return null;

    final players = await _getPlayersForGame(db, gameId);
    final actions = await _getActionsForGame(db, gameId);

    return Game.fromMap(gameMaps.first, players: players, actions: actions);
  }

  static Future<List<Game>> getAllGames() async {
    final db = await database;
    final gameMaps =
        await db.query('games', orderBy: 'created_at DESC');

    final games = <Game>[];
    for (final map in gameMaps) {
      final gameId = map['id'] as String;
      final players = await _getPlayersForGame(db, gameId);
      final actions = await _getActionsForGame(db, gameId);
      games.add(Game.fromMap(map, players: players, actions: actions));
    }
    return games;
  }

  static Future<List<Game>> getActiveGames() async {
    final db = await database;
    final gameMaps = await db.query(
      'games',
      where: 'status = ?',
      whereArgs: [GameStatus.active.index],
      orderBy: 'created_at DESC',
    );

    final games = <Game>[];
    for (final map in gameMaps) {
      final gameId = map['id'] as String;
      final players = await _getPlayersForGame(db, gameId);
      games.add(Game.fromMap(map, players: players));
    }
    return games;
  }

  static Future<List<Game>> getCompletedGames() async {
    final db = await database;
    final gameMaps = await db.query(
      'games',
      where: 'status = ?',
      whereArgs: [GameStatus.completed.index],
      orderBy: 'completed_at DESC',
    );

    final games = <Game>[];
    for (final map in gameMaps) {
      final gameId = map['id'] as String;
      final players = await _getPlayersForGame(db, gameId);
      games.add(Game.fromMap(map, players: players));
    }
    return games;
  }

  static Future<void> deleteGame(String gameId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('actions', where: 'game_id = ?', whereArgs: [gameId]);
      await txn.delete('players', where: 'game_id = ?', whereArgs: [gameId]);
      await txn.delete('games', where: 'id = ?', whereArgs: [gameId]);
    });
  }

  // ========== Helpers ==========

  static Future<List<Player>> _getPlayersForGame(
      Database db, String gameId) async {
    final maps = await db.query(
      'players',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'player_order ASC',
    );
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  static Future<List<GameAction>> _getActionsForGame(
      Database db, String gameId) async {
    final maps = await db.query(
      'actions',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'action_order ASC',
    );
    return maps.map((m) => GameAction.fromMap(m)).toList();
  }
}
