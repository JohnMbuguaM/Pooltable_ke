import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/game_provider.dart';
import '../providers/prize_provider.dart';
import '../models/game.dart';
import '../models/action.dart';
import '../utils/theme.dart';
import '../utils/game_code_generator.dart';
import '../widgets/scoreboard.dart';
import '../widgets/ball_tracker.dart';
import '../widgets/action_buttons.dart';
import '../widgets/prize_summary_card.dart';
import '../services/game_logic_service.dart';
import '../services/firebase_service.dart';
import 'action_log_screen.dart';
import 'game/game_banners.dart';
import 'game/game_over_view.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch rebuilds only this widget tree — equivalent to a root
    // Consumer but without the extra closure indentation.
    final provider = context.watch<GameProvider>();
    final game = provider.currentGame;

    if (game == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show event snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final event = provider.lastEvent;
      if (event != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event),
            duration: const Duration(seconds: 2),
          ),
        );
        provider.clearLastEvent();
      }
    });

    // Check if current user is a spectator (read-only)
    final isReadOnly = game.isOnline &&
        !game.onlineData!.isHost(FirebaseService.currentUserId);

    return Scaffold(
      backgroundColor: AppTheme.gameBg,
      appBar: _buildAppBar(context, game, provider, isReadOnly),
      body: game.isGameOver
          ? GameOverView(game: game, provider: provider)
          : _buildGameView(context, game, provider, isReadOnly),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Game game, GameProvider provider, bool isReadOnly) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00C060), Color(0xFF007840)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x4400C060),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(game.isGameOver
          ? 'Game Over'
          : isReadOnly
              ? 'Spectating'
              : 'ChalkMan'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          if (game.isGameOver || isReadOnly) {
            Navigator.pop(context);
            return;
          }
          _showExitDialog(context, provider);
        },
      ),
      actions: [
        // Share button for online games
        if (game.isOnline && game.gameCode != null)
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: 'Share Game Code',
            onPressed: () => _showShareDialog(context, game),
          ),
        // Only show menu for host (not read-only)
        if (!game.isGameOver && !isReadOnly)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'undo':
                  provider.undoLastAction();
                case 'redo':
                  provider.redoLastAction();
                case 'action_log':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActionLogScreen(game: game),
                    ),
                  );
                case 'add_player':
                  _showAddPlayerDialog(context, provider);
                case 'remove_player':
                  _showRemovePlayerDialog(context, provider);
                case 'change_wager':
                  _showChangeWagerDialog(context);
                case 'abandon':
                  _showAbandonDialog(context, provider);
              }
            },
            itemBuilder: (menuCtx) => [
              const PopupMenuItem(
                value: 'undo',
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Undo Last Action'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'redo',
                child: Row(
                  children: [
                    Icon(Icons.redo_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Redo Last Action'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'action_log',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Action Log'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_player',
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Add Player'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove_player',
                child: Row(
                  children: [
                    Icon(Icons.person_remove_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Remove Player'),
                  ],
                ),
              ),
              // Change Wager — only shown when a prize session is active
              if (menuCtx.read<PrizeProvider>().hasActiveSession)
                const PopupMenuItem(
                  value: 'change_wager',
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          size: 20, color: Colors.amber),
                      SizedBox(width: 10),
                      Text('Change Wager',
                          style: TextStyle(color: Colors.amber)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'abandon',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Abandon Game',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        // Read-only users can still view the action log
        if (!game.isGameOver && isReadOnly)
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Action Log',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActionLogScreen(game: game),
              ),
            ),
          ),
      ],
        ),
      ),
    );
  }

  Widget _buildGameView(
      BuildContext context, Game game, GameProvider provider, bool isReadOnly) {
    final targetBall = game.currentTargetBall;
    final moneyBallPlayers = GameLogicService.checkMoneyBallPlayers(game);
    final drawPartners = GameLogicService.checkDrawBallPlayers(game);
    final eliminationPlayers =
        GameLogicService.checkPotentialEliminationsOnPocket(game);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Spectator banner
          if (isReadOnly)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_rounded, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Spectator Mode - View Only',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Money ball alert
          if (moneyBallPlayers.isNotEmpty && targetBall > 0)
            MoneyBallBanner(
              playerNames: moneyBallPlayers.map((p) => p.name).toList(),
              ballNumber: targetBall,
            ),

          // Draw ball alert — pocketing this last ball would result in a draw
          if (drawPartners.isNotEmpty && targetBall > 0)
            DrawBallBanner(
              currentPlayerName: game.currentPlayer.name,
              drawPartnerNames: drawPartners.map((p) => p.name).toList(),
              ballNumber: targetBall,
            ),

          // Elimination warning — only shown when it's a *partial* elimination
          // (some players survive). If ALL others would be eliminated, that's
          // a win condition, already covered by the money-ball banner.
          if (eliminationPlayers.isNotEmpty &&
              targetBall > 0 &&
              eliminationPlayers.length < game.activePlayers.length - 1)
            EliminationWarningBanner(
              playerNames: eliminationPlayers.map((p) => p.name).toList(),
              ballNumber: targetBall,
            ),

          // Prize summary card (replaces the old NOW PLAYING card)
          PrizeSummaryCard(game: game, isReadOnly: isReadOnly),

          // Ball tracker
          BallTracker(
            game: game,
            onBallLongPress: isReadOnly
                ? null
                : (ballNumber) =>
                    _showRestoreBallDialog(context, provider, ballNumber),
          ),
          const SizedBox(height: 8),

          // Scoreboard — wager ticks replace rank dots when wager > 0
          Consumer<PrizeProvider>(
            builder: (context, prize, _) {
              final session = prize.session;
              final wagerActive =
                  session != null && session.config.wagerPerPlayer > 0;
              final wagerMap = <String, bool>{};
              if (wagerActive) {
                for (final p in session.players) {
                  wagerMap[p.displayName] = p.wagerConfirmedThisGame;
                }
              }
              return Scoreboard(
                game: game,
                onPlayerTap: isReadOnly
                    ? null
                    : (playerId) async =>
                        await provider.selectPlayer(playerId),
                onPlayerLongPress: isReadOnly
                    ? null
                    : (playerId, currentScore) => _showEditScoreDialog(
                        context, provider, game, playerId, currentScore),
                wagerActive: wagerActive,
                wagerConfirmedMap: wagerMap,
                onToggleWager: wagerActive && !isReadOnly
                    ? (name) => prize.toggleWagerConfirmed(name)
                    : null,
              );
            },
          ),
          const SizedBox(height: 10),

          // Action buttons (hidden for spectators)
          if (!isReadOnly)
            ActionButtons(
              activePlayers: game.activePlayers,
              currentPlayerId: game.currentPlayer.id,
              onSelectPlayer: (id) => provider.selectPlayer(id),
              onPocket: () => provider.pocketBall(),
              onMiss: () => provider.missShot(),
              onNextPlayer: () => provider.nextPlayer(),
              onCombo: (ball) => provider.combinationShot(ball),
              onThrough: (balls) => provider.throughShot(balls),
              onThroughFoul: (balls) => provider.throughFoul(balls),
              onPenalty: (ActionType type, {int? ballNumber}) =>
                  provider.applyPenalty(type, ballNumber: ballNumber),
              onUndo: () => provider.undoLastAction(),
              canUndo: game.actions.isNotEmpty,
              onRedo: () => provider.redoLastAction(),
              canRedo: provider.canRedo,
              remainingBalls: game.remainingBalls,
              currentTargetBall: targetBall > 0 ? targetBall : null,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, GameProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Player name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final isDuplicate = provider.currentGame?.players.any(
                    (p) => p.name.trim().toLowerCase() == name.toLowerCase(),
                  ) ??
                  false;
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$name" is already in this game')),
                );
                return;
              }
              Navigator.pop(ctx);
              provider.addPlayerMidGame(name);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemovePlayerDialog(BuildContext context, GameProvider provider) {
    final game = provider.currentGame;
    if (game == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Player'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: game.players.map((player) {
              final isCurrentPlayer = player.id == game.currentPlayer.id;
              return ListTile(
                leading: Icon(
                  player.isEliminated ? Icons.person_off : Icons.person,
                  color: player.isEliminated ? Colors.red : null,
                ),
                title: Text(player.name),
                subtitle: Text(
                    'Score: ${player.score}${player.isEliminated ? " (eliminated)" : ""}'),
                trailing: isCurrentPlayer
                    ? const Chip(
                        label:
                            Text('TURN', style: TextStyle(fontSize: 10)))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  provider.removePlayerMidGame(player.id);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRestoreBallDialog(
      BuildContext context, GameProvider provider, int ballNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore Ball $ballNumber?'),
        content: Text(
          'This will put ball $ballNumber back on the table.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.restoreBall(ballNumber);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.feltGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(BuildContext context, GameProvider provider,
      Game game, String playerId, int currentScore) {
    final player = game.players.firstWhere((p) => p.id == playerId);
    final controller = TextEditingController(text: '$currentScore');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${player.name}\'s Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current score: $currentScore',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Score',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) {
                final newScore = int.tryParse(controller.text);
                if (newScore != null) {
                  Navigator.pop(ctx);
                  provider.manualEditScore(playerId, newScore);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newScore = int.tryParse(controller.text);
              if (newScore != null) {
                Navigator.pop(ctx);
                provider.manualEditScore(playerId, newScore);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.feltGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, Game game) {
    final gameCode = game.gameCode!;
    final formattedCode = GameCodeGenerator.format(gameCode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Others can scan this QR code or enter the game code to watch live:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // QR Code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 180,
                height: 180,
                child: QrImageView(
                  data: formattedCode,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1B5E20),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Game code text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.feltGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.feltGreen),
              ),
              child: Text(
                formattedCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: formattedCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
          TextButton.icon(
            onPressed: () {
              Share.share('Join my ChalkMan pool game! Code: $formattedCode');
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text(
          'Your game progress is saved automatically. You can resume it later from the home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showAbandonDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Game?'),
        content: const Text(
          'This will end the game immediately. The game will be saved to history as abandoned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.abandonGame();
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _showChangeWagerDialog(BuildContext context) {
    final prize = context.read<PrizeProvider>();
    if (!prize.hasActiveSession) return;
    final currentWager = prize.session!.config.wagerPerPlayer;
    final controller = TextEditingController(
      text: currentWager > 0 ? currentWager.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Change Wager'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: KSH ${currentWager.toStringAsFixed(0)} per player',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New Wager Per Player',
                hintText: '0 = no wager',
                prefixText: 'KSH ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Takes effect from the next game result recorded.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newWager =
                  double.tryParse(controller.text.trim()) ?? currentWager;
              Navigator.pop(ctx);
              prize.updateWager(newWager);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Wager updated to KSH ${newWager.toStringAsFixed(0)} per player'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
