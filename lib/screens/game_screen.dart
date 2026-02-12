import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../models/action.dart';
import '../utils/theme.dart';
import '../widgets/scoreboard.dart';
import '../widgets/ball_tracker.dart';
import '../widgets/action_buttons.dart';
import '../widgets/action_history.dart';
import '../services/game_logic_service.dart';
import 'rematch_setup_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

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
              ? _GameOverView(game: game, provider: provider)
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
                    Text('Abandon Game',
                        style: TextStyle(color: Colors.red)),
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
    final targetBall = game.currentTargetBall;
    final moneyBallLeader = GameLogicService.checkMoneyBall(game);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Money ball alert
          if (moneyBallLeader != null && targetBall > 0)
            _MoneyBallBanner(
              leaderName: moneyBallLeader.name,
              ballNumber: targetBall,
            ),

          // Ball tracker
          BallTracker(game: game),
          const SizedBox(height: 10),

          // Scoreboard (tap to select player - TURN badge shows current)
          Scoreboard(
            game: game,
            onPlayerTap: (playerId) async => await provider.selectPlayer(playerId),
          ),
          const SizedBox(height: 14),

          // Action buttons
          ActionButtons(
            onPocket: () => provider.pocketBall(),
            onMiss: () => provider.missShot(),
            onNextPlayer: () => provider.nextPlayer(),
            onCombo: (ball) => provider.combinationShot(ball),
            onNeutral: () => provider.neutralShot(),
            onPenalty: (ActionType type, {int? ballNumber}) =>
                provider.applyPenalty(type, ballNumber: ballNumber),
            onUndo: () => provider.undoLastAction(),
            canUndo: game.actions.isNotEmpty,
            remainingBalls: game.remainingBalls,
            currentTargetBall: targetBall > 0 ? targetBall : null,
          ),
          const SizedBox(height: 14),

          // Collapsible action history
          if (game.actions.isNotEmpty) _ActionHistorySection(game: game),
          const SizedBox(height: 16),
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
}

class _ActionHistorySection extends StatefulWidget {
  final Game game;

  const _ActionHistorySection({required this.game});

  @override
  State<_ActionHistorySection> createState() => _ActionHistorySectionState();
}

class _ActionHistorySectionState extends State<_ActionHistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          color: AppTheme.deepEmerald.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - tap to expand/collapse
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: _expanded
                  ? const BorderRadius.vertical(top: Radius.circular(20))
                  : BorderRadius.circular(20),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.deepEmerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: AppTheme.premiumGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ACTION LOG',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.premiumGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.premiumGold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${widget.game.actions.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.premiumGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: AppTheme.premiumGold.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: ActionHistory(actions: widget.game.actions),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _MoneyBallBanner extends StatelessWidget {
  final String leaderName;
  final int ballNumber;

  const _MoneyBallBanner({
    required this.leaderName,
    required this.ballNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.premiumGold.withValues(alpha: 0.3),
            AppTheme.goldDim.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.premiumGold.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumGold.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.premiumGold, AppTheme.goldHighlight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.premiumGold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: AppTheme.charcoalBase,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
                children: [
                  const TextSpan(
                    text: 'MONEY BALL! ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.premiumGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextSpan(
                    text: 'Ball $ballNumber wins it for ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  TextSpan(
                    text: leaderName.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.premiumGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
//  GAME OVER VIEW WITH CELEBRATION
// ==========================================================

class _GameOverView extends StatefulWidget {
  final Game game;
  final GameProvider provider;

  const _GameOverView({required this.game, required this.provider});

  @override
  State<_GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<_GameOverView>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _trophyController;
  late Animation<double> _trophyScale;
  late List<_ConfettiParticle> _particles;
  final _random = Random();

  bool get _showCelebration =>
      widget.game.winnerId != null &&
      widget.game.status != GameStatus.abandoned;

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
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _trophyController.dispose();
    super.dispose();
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
              // Premium Trophy icon with scale animation
              ScaleTransition(
                scale: _showCelebration
                    ? _trophyScale
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.premiumGold, AppTheme.goldDim],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.premiumGold.withValues(alpha: 0.5),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AppTheme.premiumGold.withValues(alpha: 0.3),
                        blurRadius: 64,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldHighlight.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 52,
                      color: AppTheme.charcoalBase,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (winner != null) ...[
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.premiumGold, AppTheme.goldHighlight],
                  ).createShader(bounds),
                  child: Text(
                    winner.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Special message for money ball wins
                if (widget.provider.isMoneyBallWin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.premiumGold.withValues(alpha: 0.3),
                          AppTheme.goldDim.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.premiumGold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.premiumGold.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: AppTheme.premiumGold,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MONEY BALL VICTORY!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.premiumGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.stars_rounded,
                          color: AppTheme.premiumGold,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'WINNER WITH ${winner.score} POINTS!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppTheme.premiumGold.withValues(alpha: 0.9),
                  ),
                ),
              ] else ...[
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
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
              const SizedBox(height: 24),

              // Final standings
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.charcoalCard,
                      AppTheme.charcoalOverlay.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.deepEmerald.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepEmerald.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.premiumGold.withValues(alpha: 0.3),
                                AppTheme.premiumGold.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.leaderboard_rounded,
                            size: 20,
                            color: AppTheme.premiumGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'FINAL STANDINGS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                                  Row(
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
                                      // Money ball icon for winner
                                      if (isWinner && widget.provider.isMoneyBallWin) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.stars_rounded,
                                          size: 16,
                                          color: AppTheme.accentGold,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (player.isEliminated)
                                    Text(
                                      'Eliminated',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.red.withValues(alpha: 0.6),
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
                                color: isWinner ? AppTheme.accentGold : null,
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RematchSetupScreen(
                              previousGame: game,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
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
