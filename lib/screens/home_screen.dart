import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/rules_provider.dart';
import '../models/game.dart';
import '../utils/theme.dart';
import 'new_game_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'join_game_screen.dart';
import 'home/home_game_card.dart';
import 'home/home_stat_widgets.dart';
import 'home/home_common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // null = "Today", otherwise number of last games
  int? _gameCountFilter = 10;
  static const _filterOptions = [
    (label: 'Today', value: null),
    (label: 'Last 3', value: 3),
    (label: 'Last 5', value: 5),
    (label: 'Last 10', value: 10),
    (label: 'Last 15', value: 15),
    (label: 'Last 20', value: 20),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rulesProvider = context.read<RulesProvider>();
      final gameProvider = context.read<GameProvider>();

      // Sync custom rules to game provider
      if (rulesProvider.isLoaded) {
        gameProvider.updateRules(rulesProvider.rules);
      }

      gameProvider.loadActiveGames();
      gameProvider.loadGameHistory();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final provider = context.read<GameProvider>();
    await Future.wait([
      provider.loadActiveGames(),
      provider.loadGameHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
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
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ChalkMan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Pool Score Tracker',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                icon: Icon(
                  context.watch<ThemeProvider>().isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: Colors.white,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'history':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    case 'settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Active Games
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildSectionHeader('Active Games', Icons.play_circle),
                ),
              ),
              _buildActiveGames(context),

              // Statistics
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _buildSectionHeader('Statistics', Icons.insights_rounded),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),
              _buildStatistics(context),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.feltGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.feltGreen.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showGameTypeSelector(context),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'New Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveGames(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final games = provider.activeGames;

        if (games.isEmpty) {
          return SliverToBoxAdapter(
            child: HomeEmptyState(
              icon: Icons.sports_esports_outlined,
              message: 'No active games',
              submessage: 'Start a new game to begin scoring',
            ),
          );
        }

        // Show only the last 3 active games
        final displayedGames = games.take(min(3, games.length)).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = displayedGames[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key: Key(game.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Game?'),
                          content: const Text(
                            'This will permanently remove this game.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) {
                      context.read<GameProvider>().deleteGame(game.id);
                    },
                    child: HomeGameCard(
                      game: game,
                      onTap: () => _navigateToGame(context, game),
                    ),
                  ),
                );
              },
              childCount: displayedGames.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _gameCountFilter == option.value;
          return ChoiceChip(
            label: Text(option.label),
            selected: isSelected,
            onSelected: (_) => setState(() => _gameCountFilter = option.value),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
            ),
            selectedColor: AppTheme.feltGreen,
            backgroundColor: Theme.of(context).cardTheme.color,
            side: BorderSide(
              color: isSelected
                  ? AppTheme.feltGreen
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final allCompleted = provider.gameHistory
            .where((g) => g.status == GameStatus.completed);

        final List<Game> completedGames;
        if (_gameCountFilter == null) {
          // "Today" filter
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          completedGames = allCompleted
              .where((g) => g.createdAt.isAfter(startOfDay))
              .toList();
        } else {
          completedGames = allCompleted.take(_gameCountFilter!).toList();
        }

        if (completedGames.isEmpty) {
          return const SliverToBoxAdapter(
            child: HomeEmptyState(
              icon: Icons.insights_rounded,
              message: 'No completed games yet',
              submessage: 'Stats will appear after your first game',
            ),
          );
        }

        // Compute stats
        final gamesPlayed = completedGames.length;

        // Win counts per player name
        final winCounts = <String, int>{};
        int totalWinScore = 0;
        int winnerCount = 0;
        for (final game in completedGames) {
          if (game.winnerId != null) {
            try {
              final winner =
                  game.players.firstWhere((p) => p.id == game.winnerId);
              winCounts[winner.name] = (winCounts[winner.name] ?? 0) + 1;
              totalWinScore += winner.score;
              winnerCount++;
            } catch (_) {}
          }
        }
        final avgWinScore =
            winnerCount > 0 ? (totalWinScore / winnerCount).round() : 0;

        // Top winner
        String topWinner = '-';
        int topWins = 0;
        winCounts.forEach((name, count) {
          if (count > topWins) {
            topWins = count;
            topWinner = name;
          }
        });

        // Most active player (appears in most games)
        final appearCounts = <String, int>{};
        for (final game in completedGames) {
          for (final player in game.players) {
            appearCounts[player.name] =
                (appearCounts[player.name] ?? 0) + 1;
          }
        }
        String mostActive = '-';
        int mostActiveCount = 0;
        appearCounts.forEach((name, count) {
          if (count > mostActiveCount) {
            mostActiveCount = count;
            mostActive = name;
          }
        });

        // Sorted leaderboard entries
        final leaderboard = winCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Longest win streak per player
        String streakHolder = '-';
        int longestStreak = 0;
        if (completedGames.length > 1) {
          final streaks = <String, int>{};
          final currentStreaks = <String, int>{};
          for (final game in completedGames.reversed) {
            String? winnerName;
            if (game.winnerId != null) {
              try {
                winnerName = game.players
                    .firstWhere((p) => p.id == game.winnerId)
                    .name;
              } catch (_) {}
            }
            for (final p in game.players) {
              if (p.name == winnerName) {
                currentStreaks[p.name] = (currentStreaks[p.name] ?? 0) + 1;
                final s = currentStreaks[p.name]!;
                if (s > (streaks[p.name] ?? 0)) streaks[p.name] = s;
              } else {
                currentStreaks[p.name] = 0;
              }
            }
          }
          streaks.forEach((name, streak) {
            if (streak > longestStreak) {
              longestStreak = streak;
              streakHolder = name;
            }
          });
        }

        // Average game duration (minutes)
        final durations = completedGames
            .where((g) => g.completedAt != null)
            .map((g) => g.completedAt!.difference(g.createdAt).inMinutes)
            .where((d) => d > 0)
            .toList();
        final avgDuration =
            durations.isNotEmpty ? (durations.reduce((a, b) => a + b) / durations.length).round() : 0;

        // Total balls pocketed across all games
        final totalBalls =
            completedGames.fold<int>(0, (sum, g) => sum + g.pocketedBalls.length);

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1 — games played / top winner / avg score
                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        value: '$gamesPlayed',
                        label: 'Played',
                        icon: Icons.sports_esports_rounded,
                        color: AppTheme.feltGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HomeStatCard(
                        value: topWinner,
                        label: '$topWins wins',
                        icon: Icons.emoji_events_rounded,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HomeStatCard(
                        value: '$avgWinScore',
                        label: 'Avg Score',
                        icon: Icons.trending_up_rounded,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2 — streak / avg duration / total balls
                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        value: longestStreak > 1 ? '$longestStreak' : '-',
                        label: longestStreak > 1 ? '$streakHolder streak' : 'Best streak',
                        icon: Icons.whatshot_rounded,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HomeStatCard(
                        value: avgDuration > 0 ? '${avgDuration}m' : '-',
                        label: 'Avg duration',
                        icon: Icons.timer_rounded,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HomeStatCard(
                        value: '$totalBalls',
                        label: 'Balls potted',
                        icon: Icons.circle_rounded,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Most active row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 16,
                          color: Colors.orange.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'Most Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$mostActive ($mostActiveCount games)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Win leaderboard
                if (leaderboard.isNotEmpty)
                  HomeWinLeaderboard(entries: leaderboard),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGameTypeSelector(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon header
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.feltGreen.withValues(alpha: 0.25),
                        AppTheme.feltGreen.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.feltGreen.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    size: 32,
                    color: AppTheme.feltGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New Game',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to play',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Local Game
              HomeGameTypeOption(
                icon: Icons.phone_android_rounded,
                title: 'Local Game',
                subtitle: 'Play on this device only',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToNewGame(context);
                },
              ),
              const SizedBox(height: 10),

              // Online Game
              HomeGameTypeOption(
                icon: Icons.cloud_rounded,
                title: 'Create Online Game',
                subtitle: 'Share with multiple devices',
                onTap: () {
                  Navigator.pop(ctx);
                  _createOnlineGame(context);
                },
              ),
              const SizedBox(height: 10),

              // Join Game
              HomeGameTypeOption(
                icon: Icons.login_rounded,
                title: 'Join Game',
                subtitle: 'Enter a game code',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JoinGameScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewGameScreen()),
    );
  }

  void _createOnlineGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewGameScreen(isOnline: true),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Game game) async {
    final provider = context.read<GameProvider>();
    await provider.loadGame(game.id);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
      // Reload games when returning from game screen
      // This ensures completed games are moved from active to recent
      if (context.mounted) {
        await provider.loadActiveGames();
        await provider.loadGameHistory();
      }
    }
  }
}
