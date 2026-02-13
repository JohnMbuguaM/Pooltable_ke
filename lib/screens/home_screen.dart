import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/rules_provider.dart';
import '../models/game.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import 'new_game_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

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
      appBar: AppBar(
        backgroundColor: AppTheme.feltGreen,
        elevation: 0,
        title: const Text('ChalkMan'),
        actions: [
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
            // Logo section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ChalkMan',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pool Score Tracker',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNewGame(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Game'),
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
            child: _EmptyState(
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
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GameCard(
                  game: displayedGames[index],
                  onTap: () => _navigateToGame(context, displayedGames[index]),
                ),
              ),
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
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            selectedColor: AppTheme.feltGreen,
            backgroundColor: Theme.of(context).cardTheme.color,
            side: BorderSide(
              color: isSelected ? AppTheme.feltGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: _EmptyState(
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
              winCounts[winner.name] =
                  (winCounts[winner.name] ?? 0) + 1;
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

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary stat cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '$gamesPlayed',
                        label: 'Played',
                        icon: Icons.sports_esports_rounded,
                        color: AppTheme.feltGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        value: topWinner,
                        label: '$topWins wins',
                        icon: Icons.emoji_events_rounded,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        value: '$avgWinScore',
                        label: 'Avg Score',
                        icon: Icons.trending_up_rounded,
                        color: Colors.blue,
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
                  _WinLeaderboard(entries: leaderboard),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToNewGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewGameScreen()),
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

class _GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerNames = game.players.map((p) => p.name).join(', ');
    final leader = game.leader;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.feltGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.feltGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerNames,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          Helpers.formatDateTime(game.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (leader != null) ...[
                          Text(
                            ' \u2022 ',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${leader.name}: ${leader.score}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentGold.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinLeaderboard extends StatelessWidget {
  final List<MapEntry<String, int>> entries;

  const _WinLeaderboard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWins = entries.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                'Win Leaderboard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...entries.take(5).map((entry) {
            final fraction = maxWins > 0 ? entry.value / maxWins : 0.0;
            final isTop = entry.key == entries.first.key;
            final barColor =
                isTop ? AppTheme.accentGold : AppTheme.feltGreen;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isTop ? FontWeight.w700 : FontWeight.w500,
                        color: isTop
                            ? AppTheme.accentGold
                            : theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 18,
                              width: constraints.maxWidth * fraction,
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? submessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.submessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            if (submessage != null) ...[
              const SizedBox(height: 2),
              Text(
                submessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
