import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../../providers/prize_provider.dart';
import '../../utils/theme.dart';
import '../../services/sound_service.dart';
import '../rematch_setup_screen.dart';

// ==========================================================
//  GAME OVER VIEW WITH CELEBRATION
// ==========================================================

class GameOverView extends StatefulWidget {
  final Game game;
  final GameProvider provider;

  const GameOverView({super.key, required this.game, required this.provider});

  @override
  State<GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<GameOverView>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late Animation<double> _trophyScale;
  late List<_ConfettiParticle> _particles;
  final _random = Random();
  bool _resultRecorded = false;

  bool get _showCelebration =>
      widget.game.winnerId != null &&
      widget.game.status == GameStatus.completed;

  bool get _isDraw => widget.game.status == GameStatus.draw;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trophyScale = CurvedAnimation(
      parent: _trophyController,
      curve: Curves.elasticOut,
    );

    _particles = List.generate(50, (_) => _ConfettiParticle(_random));

    if (_showCelebration) {
      _trophyController.forward();
      _confettiController.forward();
      // Celebratory double-buzz — feels like Duolingo's win haptic
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 180),
          () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 380),
          () => HapticFeedback.mediumImpact());
      // Fanfare sound slightly after vibration settles
      Future.delayed(const Duration(milliseconds: 120),
          () => SoundService.instance.playGameOver());
    } else if (_isDraw) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 200),
          () => HapticFeedback.mediumImpact());
      Future.delayed(const Duration(milliseconds: 100),
          () => SoundService.instance.playGameOverDraw());
    }

    // Record game result in prize session (exactly once, after first build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _resultRecorded) return;
      _resultRecorded = true;
      final game = widget.game;
      if (game.status == GameStatus.abandoned) return;
      final winner = game.winnerId != null
          ? game.players.firstWhere((p) => p.id == game.winnerId,
              orElse: () => game.players.first)
          : null;
      final drawPartnerNames = game.status == GameStatus.draw
          ? (game.drawPlayerIds ?? [])
              .map((id) => game.players
                  .firstWhere((p) => p.id == id,
                      orElse: () => game.players.first)
                  .name)
              .toList()
          : null;
      context.read<PrizeProvider>().recordGameResult(
            winnerName: winner?.name,
            playerNames: game.players.map((p) => p.name).toList(),
            drawPartnerNames: drawPartnerNames,
          );
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _trophyController.dispose();
    super.dispose();
  }

  void _showRevokeWinDialog(BuildContext context, GameProvider provider) {
    final winner = widget.game.players
        .firstWhere((p) => p.id == widget.game.winnerId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Win?'),
        content: Text(
          'This will cancel ${winner.name}\'s win and return the game to active state. Use this if points were added incorrectly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.revokeWin();
              context.read<PrizeProvider>().revokeLastGameResult();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke Win'),
          ),
        ],
      ),
    );
  }

  void _showRevokeDrawDialog(BuildContext context, GameProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Draw?'),
        content: const Text(
          'This will cancel the draw and return the game to active state. Use this if points were recorded incorrectly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.revokeWin();
              context.read<PrizeProvider>().revokeLastGameResult();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke Draw'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final winner = game.winnerId != null
        ? game.players.firstWhere((p) => p.id == game.winnerId)
        : null;

    final sortedPlayers = List.from(game.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Stack(
      children: [
        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Trophy / Draw icon with scale animation
              ScaleTransition(
                scale: _showCelebration
                    ? _trophyScale
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isDraw
                          ? [const Color(0xFF26C6DA), const Color(0xFF0097A7)]
                          : [AppTheme.accentGold, const Color(0xFFFF8F00)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isDraw ? const Color(0xFF26C6DA) : AppTheme.accentGold)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isDraw ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_isDraw) ...[
                const Text(
                  "IT'S A DRAW!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF26C6DA),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final drawIds = game.drawPlayerIds ?? [];
                  final drawNames = game.players
                      .where((p) => drawIds.contains(p.id))
                      .map((p) => p.name)
                      .join(' & ');
                  final topScore = game.players
                      .where((p) => drawIds.contains(p.id))
                      .fold(0, (m, p) => p.score > m ? p.score : m);
                  return Text(
                    '$drawNames tied with $topScore points',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF26C6DA).withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  );
                }),
              ] else if (winner != null) ...[
                Text(
                  winner.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Special message for money ball wins
                if (widget.provider.isMoneyBallWin) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGold.withValues(alpha: 0.2),
                          Colors.amber.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 20),
                        const SizedBox(width: 6),
                        const Text(
                          'MONEY BALL VICTORY!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 20),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const Text(
                  'Game Over',
                  style: TextStyle(
                    fontSize: 26,
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
              const SizedBox(height: 20),

              // ── Prize breakdown card (only when wager active) ───────────
              Consumer<PrizeProvider>(
                builder: (context, prize, _) {
                  final session = prize.session;
                  if (session == null || session.config.wagerPerPlayer == 0) {
                    return const SizedBox.shrink();
                  }
                  final config = session.config;
                  final numPlayers = game.players.length;
                  final prizePool = config.prizePool(numPlayers);
                  final board = config.boardFeePerGame;
                  final chalk = config.chalkmanFeePerGame;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.gameCard,
                          AppTheme.gameElevated,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withValues(alpha: 0.1),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded,
                                size: 16, color: AppTheme.accentGold),
                            const SizedBox(width: 8),
                            const Text(
                              'Game Finances',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FinanceRow(
                          icon: Icons.table_bar_rounded,
                          label: 'Board fee',
                          amount: board,
                          color: const Color(0xFF5C9BFF),
                          isDeduction: true,
                        ),
                        const SizedBox(height: 6),
                        _FinanceRow(
                          icon: Icons.sports_bar_rounded,
                          label: 'ChalkMan fee',
                          amount: chalk,
                          color: const Color(0xFFB39DDB),
                          isDeduction: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: AppTheme.accentGold.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                        _FinanceRow(
                          icon: Icons.emoji_events_rounded,
                          label: _isDraw ? 'Split prize each' : 'Winner takes',
                          amount: _isDraw
                              ? (prizePool /
                                  ((game.drawPlayerIds ?? []).length.clamp(1, 999)))
                              : prizePool,
                          color: AppTheme.feltGreen,
                          isDeduction: false,
                          isBig: true,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Final standings card ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.gameCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header gradient strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.gameElevated,
                            AppTheme.gameCard,
                          ],
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.leaderboard_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Final Standings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.feltGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.feltGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: AppTheme.feltGreen.withValues(alpha: 0.7)),
                                const SizedBox(width: 5),
                                Text(
                                  'On table: ${game.remainingBallsValue} pts',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.feltGreen.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          ...sortedPlayers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final player = entry.value;
                            final isWinner = player.id == game.winnerId;
                            final isDrawPlayer = _isDraw &&
                                (game.drawPlayerIds ?? []).contains(player.id);
                            final highlightColor = isDrawPlayer
                                ? const Color(0xFF26C6DA)
                                : AppTheme.accentGold;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: (isWinner || isDrawPlayer)
                                    ? highlightColor.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: (isWinner || isDrawPlayer)
                                    ? Border.all(
                                        color: highlightColor
                                            .withValues(alpha: 0.25),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  _buildRankBadge(
                                      player.rank > 0 ? player.rank : idx + 1),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              player.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: (isWinner || isDrawPlayer)
                                                    ? highlightColor
                                                    : null,
                                              ),
                                            ),
                                            if (isWinner &&
                                                widget.provider
                                                    .isMoneyBallWin) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.stars_rounded,
                                                  size: 16,
                                                  color: AppTheme.accentGold),
                                            ],
                                            if (isDrawPlayer) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                  Icons.handshake_rounded,
                                                  size: 16,
                                                  color: Color(0xFF26C6DA)),
                                            ],
                                          ],
                                        ),
                                        if (player.isEliminated)
                                          Text(
                                            'Eliminated',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${player.score}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: (isWinner || isDrawPlayer)
                                          ? highlightColor
                                          : Colors.white
                                              .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.feltGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.feltGreen.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RematchSetupScreen(
                                  previousGame: game,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Play Again',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Revoke win (completed games with a single winner)
              if (game.status == GameStatus.completed && game.winnerId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRevokeWinDialog(context, widget.provider),
                    icon: const Icon(Icons.gavel_rounded, color: Colors.orange),
                    label: const Text(
                      'Revoke Win',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
              // Revoke draw (draw games)
              if (_isDraw) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRevokeDrawDialog(context, widget.provider),
                    icon: const Icon(Icons.gavel_rounded, color: Colors.orange),
                    label: const Text(
                      'Revoke Draw',
                      style: TextStyle(color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Confetti overlay
        if (_showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
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
}

// ==========================================================
//  FINANCE ROW (used in game-over prize breakdown)
// ==========================================================

class _FinanceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool isDeduction;
  final bool isBig;

  const _FinanceRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.isDeduction,
    this.isBig = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBig ? 14 : 13,
              color: Colors.white.withValues(alpha: isBig ? 0.9 : 0.65),
              fontWeight: isBig ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          '${isDeduction ? '-' : '+'}KSH ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isBig ? 18 : 13,
            fontWeight: isBig ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ==========================================================
//  CONFETTI ANIMATION
// ==========================================================

class _ConfettiParticle {
  final double x; // 0..1 horizontal position
  final double speed; // fall speed multiplier
  final double size;
  final double drift; // horizontal drift
  final double rotationSpeed;
  final Color color;

  _ConfettiParticle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.5 + rng.nextDouble() * 0.8,
        size = 4 + rng.nextDouble() * 6,
        drift = (rng.nextDouble() - 0.5) * 0.15,
        rotationSpeed = rng.nextDouble() * 4,
        color = _colors[rng.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFFFFD700), // gold
    Color(0xFFFF6B6B), // red
    Color(0xFF48DBFB), // blue
    Color(0xFF1DD1A1), // green
    Color(0xFFFECA57), // yellow
    Color(0xFFFF9FF3), // pink
    Color(0xFFFF8C00), // orange
    Color(0xFFA29BFE), // purple
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fade out in the last 30%
    final opacity = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;
    if (opacity <= 0) return;

    for (final p in particles) {
      final px = (p.x + p.drift * progress) * size.width;
      final py = -20 + progress * (size.height + 40) * p.speed;

      if (py < -20 || py > size.height + 20) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(progress * p.rotationSpeed * pi);

      // Draw a small rectangle for confetti piece
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
