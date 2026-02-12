import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../models/game.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import '../utils/page_transitions.dart';
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.premiumGold.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToNewGame(context),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'NEW GAME',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepEmerald.withValues(alpha: 0.2),
            AppTheme.deepEmeraldDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.premiumGold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepEmerald.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Premium Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.premiumGold, AppTheme.goldDim],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.premiumGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '8',
                style: TextStyle(
                  color: AppTheme.charcoalBase,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.premiumGold, AppTheme.goldHighlight],
                  ).createShader(bounds),
                  child: const Text(
                    'CHALKMAN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PREMIUM POOL SCORER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: AppTheme.premiumGold.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.charcoalOverlay.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: AppTheme.premiumGold,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.charcoalOverlay.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppTheme.premiumGold,
                size: 22,
              ),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.deepEmerald.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'history':
                    Navigator.push(
                      context,
                      PremiumPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  case 'settings':
                    Navigator.push(
                      context,
                      PremiumPageRoute(builder: (_) => const SettingsScreen()),
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
                      Text('HISTORY'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('SETTINGS'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppTheme.deepEmerald.withValues(alpha: 0.15),
            AppTheme.deepEmerald.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.deepEmerald.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.premiumGold,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
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
      PremiumPageRoute(
        builder: (_) => const NewGameScreen(),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Game game) async {
    final provider = context.read<GameProvider>();
    await provider.loadGame(game.id);
    if (context.mounted) {
      Navigator.push(
        context,
        PremiumPageRoute(
          builder: (_) => const GameScreen(),
          duration: const Duration(milliseconds: 350),
        ),
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

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.charcoalCard,
            AppTheme.charcoalOverlay.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppTheme.info.withValues(alpha: 0.3)
              : AppTheme.deepEmerald.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppTheme.info : AppTheme.deepEmerald)
                .withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Premium status icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCompleted
                          ? [
                              AppTheme.info.withValues(alpha: 0.3),
                              AppTheme.info.withValues(alpha: 0.1),
                            ]
                          : [
                              AppTheme.premiumGold.withValues(alpha: 0.3),
                              AppTheme.premiumGold.withValues(alpha: 0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.info.withValues(alpha: 0.5)
                          : AppTheme.premiumGold.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.emoji_events_rounded
                        : Icons.play_circle_rounded,
                    color: isCompleted ? AppTheme.info : AppTheme.premiumGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerNames,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.charcoalBase.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    AppTheme.deepEmerald.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              Helpers.formatDateTime(game.createdAt)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          if (leader != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.premiumGold
                                        .withValues(alpha: 0.2),
                                    AppTheme.goldDim.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.premiumGold
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${leader.name}: ${leader.score}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppTheme.premiumGold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.charcoalBase.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.premiumGold.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepEmerald.withValues(alpha: 0.1),
            AppTheme.charcoalCard.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.deepEmerald.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.charcoalBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.deepEmerald.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.deepEmerald.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            if (submessage != null) ...[
              const SizedBox(height: 6),
              Text(
                submessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
