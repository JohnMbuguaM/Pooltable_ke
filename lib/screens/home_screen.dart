import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
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
      context.read<GameProvider>().loadActiveGames();
      context.read<GameProvider>().loadGameHistory();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              // Active Games
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _buildSectionHeader('Active Games', Icons.play_circle),
                ),
              ),
              _buildActiveGames(context),

              // Recent Games
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child:
                      _buildSectionHeader('Recent Games', Icons.history_rounded),
                ),
              ),
              _buildRecentGames(context),

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

  Widget _buildHeader(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo area
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.feltGreen, AppTheme.darkGreen],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.feltGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '8',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pool Table KE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Max Game Scorer',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
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

  Widget _buildRecentGames(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final completedGames = provider.gameHistory
            .where((g) => g.status != GameStatus.active)
            .take(5)
            .toList();

        if (completedGames.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.history_rounded,
              message: 'No completed games yet',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GameCard(
                  game: completedGames[index],
                  isCompleted: true,
                  onTap: () =>
                      _navigateToGame(context, completedGames[index]),
                ),
              ),
              childCount: completedGames.length,
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  final bool isCompleted;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    this.isCompleted = false,
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
              // Status icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.blue.withValues(alpha: 0.1)
                      : AppTheme.feltGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.play_arrow_rounded,
                  color: isCompleted ? Colors.blue : AppTheme.feltGreen,
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
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        if (leader != null) ...[
                          Text(
                            ' \u2022 ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${leader.name}: ${leader.score}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentGold.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
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
            Icon(icon, size: 36, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            if (submessage != null) ...[
              const SizedBox(height: 2),
              Text(
                submessage!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
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
