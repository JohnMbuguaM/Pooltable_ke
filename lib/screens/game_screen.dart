import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../utils/theme.dart';
import '../widgets/scoreboard.dart';
import '../widgets/ball_tracker.dart';
import '../widgets/action_buttons.dart';
import '../widgets/action_history.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
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

        return Scaffold(
          appBar: _buildAppBar(context, game, provider),
          body: game.isGameOver
              ? _buildGameOverView(context, game)
              : _buildGameView(context, game, provider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Game game, GameProvider provider) {
    return AppBar(
      title: Text(game.isGameOver ? 'Game Over' : 'Max Game'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          if (game.isGameOver) {
            Navigator.pop(context);
            return;
          }
          _showExitDialog(context, provider);
        },
      ),
      actions: [
        if (!game.isGameOver)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'abandon':
                  _showAbandonDialog(context, provider);
                case 'undo':
                  provider.undoLastAction();
              }
            },
            itemBuilder: (_) => [
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
                value: 'abandon',
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Abandon Game', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildGameView(
      BuildContext context, Game game, GameProvider provider) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.darkElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.feltGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Score'),
              Tab(text: 'Actions'),
              Tab(text: 'History'),
            ],
          ),
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildScoreTab(game, provider),
              _buildActionsTab(game, provider),
              _buildHistoryTab(game),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreTab(Game game, GameProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current player banner
          _CurrentPlayerBanner(game: game),
          const SizedBox(height: 12),
          // Ball tracker
          BallTracker(game: game),
          const SizedBox(height: 12),
          // Scoreboard
          Scoreboard(game: game),
        ],
      ),
    );
  }

  Widget _buildActionsTab(Game game, GameProvider provider) {
    final targetBall = game.currentTargetBall;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current player & target ball info
          _CurrentPlayerBanner(game: game),
          const SizedBox(height: 16),
          // Action buttons
          ActionButtons(
            onPocket: () => provider.pocketBall(),
            onMiss: () => provider.missShot(),
            onCombo: (ball) => provider.combinationShot(ball),
            onNeutral: () => provider.neutralShot(),
            onPenalty: (type) => provider.applyPenalty(type),
            onUndo: () => provider.undoLastAction(),
            canUndo: game.actions.isNotEmpty,
            remainingBalls: game.remainingBalls,
            currentTargetBall: targetBall > 0 ? targetBall : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(Game game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 6),
              const Text(
                'Action Log',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${game.actions.length} actions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ActionHistory(actions: game.actions),
        ],
      ),
    );
  }

  Widget _buildGameOverView(BuildContext context, Game game) {
    final winner = game.winnerId != null
        ? game.players.firstWhere((p) => p.id == game.winnerId)
        : null;

    final sortedPlayers = List.from(game.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.accentGold, Color(0xFFFF8F00)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (winner != null) ...[
            Text(
              winner.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Winner with ${winner.score} points!',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.accentGold.withValues(alpha: 0.8),
              ),
            ),
          ] else ...[
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (game.status == GameStatus.abandoned) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Game Abandoned',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Final standings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final Standings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...sortedPlayers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final player = entry.value;
                  final isWinner = player.id == game.winnerId;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? AppTheme.accentGold.withValues(alpha: 0.08)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildRankBadge(idx + 1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isWinner
                                      ? AppTheme.accentGold
                                      : null,
                                ),
                              ),
                              if (player.isEliminated)
                                Text(
                                  'Eliminated',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.withValues(alpha: 0.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${player.score}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isWinner
                                ? AppTheme.accentGold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Could navigate to new game screen
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('New Game'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;
    switch (rank) {
      case 1:
        color = AppTheme.accentGold;
        icon = Icons.emoji_events_rounded;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.emoji_events_rounded;
      case 3:
        color = const Color(0xFFCD7F32);
        icon = Icons.emoji_events_rounded;
      default:
        color = Colors.grey.shade600;
        icon = null;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: color)
            : Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
}

class _CurrentPlayerBanner extends StatelessWidget {
  final Game game;

  const _CurrentPlayerBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    final player = game.currentPlayer;
    final targetBall = game.currentTargetBall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.feltGreen.withValues(alpha: 0.2),
            AppTheme.feltGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.feltGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded,
              color: AppTheme.feltGreen, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Score: ${player.score}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (targetBall > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.adjust,
                      size: 16, color: AppTheme.accentGold),
                  const SizedBox(width: 4),
                  Text(
                    'Ball $targetBall',
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
