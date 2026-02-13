import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../models/action.dart';
import '../utils/theme.dart';
import '../widgets/scoreboard.dart';
import '../widgets/ball_tracker.dart';
import '../widgets/action_buttons.dart';
import '../services/game_logic_service.dart';
import 'action_log_screen.dart';
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
      title: Text(game.isGameOver ? 'Game Over' : 'ChalkMan'),
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
                case 'undo':
                  provider.undoLastAction();
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
                case 'abandon':
                  _showAbandonDialog(context, provider);
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
    final moneyBallPlayers = GameLogicService.checkMoneyBallPlayers(game);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Money ball alert
          if (moneyBallPlayers.isNotEmpty && targetBall > 0)
            _MoneyBallBanner(
              playerNames: moneyBallPlayers.map((p) => p.name).toList(),
              ballNumber: targetBall,
            ),

          // Current turn indicator
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.feltGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.feltGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.currentPlayer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (targetBall > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ball $targetBall',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'R${game.roundNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),

          // Ball tracker
          BallTracker(game: game),
          const SizedBox(height: 8),

          // Scoreboard
          Scoreboard(
            game: game,
            onPlayerTap: (playerId) async =>
                await provider.selectPlayer(playerId),
          ),
          const SizedBox(height: 10),

          // Action buttons
          ActionButtons(
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
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                provider.addPlayerMidGame(name);
              }
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

class _MoneyBallBanner extends StatefulWidget {
  final List<String> playerNames;
  final int ballNumber;

  const _MoneyBallBanner({
    required this.playerNames,
    required this.ballNumber,
  });

  @override
  State<_MoneyBallBanner> createState() => _MoneyBallBannerState();
}

class _MoneyBallBannerState extends State<_MoneyBallBanner>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce-in entrance
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Pulsing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _scaleController.forward();
    _glowController.repeat(reverse: true);

    // Haptic buzz on appear
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final namesText = widget.playerNames.length == 1
        ? widget.playerNames.first
        : widget.playerNames.join(' & ');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glow = _glowAnimation.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.25),
                  AppTheme.accentGold.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.4 + glow * 0.4),
                width: 1.0 + glow * 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold
                      .withValues(alpha: 0.1 + glow * 0.25),
                  blurRadius: 8 + glow * 12,
                  spreadRadius: glow * 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AppTheme.accentGold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.3),
                  children: [
                    const TextSpan(
                      text: 'Money Ball! ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    TextSpan(
                      text: 'Ball ${widget.ballNumber} wins it for ',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    TextSpan(
                      text: namesText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              // Trophy icon with scale animation
              ScaleTransition(
                scale: _showCelebration
                    ? _trophyScale
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 72,
                  height: 72,
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
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (winner != null) ...[
                Text(
                  winner.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Special message for money ball wins
                if (widget.provider.isMoneyBallWin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 4),
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
                        Icon(
                          Icons.stars_rounded,
                          color: AppTheme.accentGold,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'MONEY BALL VICTORY!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.stars_rounded,
                          color: AppTheme.accentGold,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'Winner with ${winner.score} points!',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.accentGold.withValues(alpha: 0.8),
                  ),
                ),
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
              const SizedBox(height: 24),

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
