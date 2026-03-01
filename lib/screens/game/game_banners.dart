import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';
import '../../services/sound_service.dart';

// ==========================================================
//  MONEY BALL BANNER
// ==========================================================

class MoneyBallBanner extends StatefulWidget {
  final List<String> playerNames;
  final int ballNumber;

  const MoneyBallBanner({
    super.key,
    required this.playerNames,
    required this.ballNumber,
  });

  @override
  State<MoneyBallBanner> createState() => _MoneyBallBannerState();
}

class _MoneyBallBannerState extends State<MoneyBallBanner>
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

    // Haptic + sound on appear
    HapticFeedback.heavyImpact();
    SoundService.instance.playMoneyBall();
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
//  ELIMINATION WARNING BANNER
// ==========================================================

class EliminationWarningBanner extends StatefulWidget {
  final List<String> playerNames;
  final int ballNumber;

  const EliminationWarningBanner({
    super.key,
    required this.playerNames,
    required this.ballNumber,
  });

  @override
  State<EliminationWarningBanner> createState() =>
      _EliminationWarningBannerState();
}

class _EliminationWarningBannerState extends State<EliminationWarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100),
        () => HapticFeedback.lightImpact());
    SoundService.instance.playElimination();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final namesText = widget.playerNames.length == 1
        ? widget.playerNames.first
        : widget.playerNames.join(' & ');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.2),
              Colors.red.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.3),
                  children: [
                    TextSpan(
                      text: namesText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
                      text: ' will be eliminated if ball '
                          '${widget.ballNumber} is pocketed!',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
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
//  DRAW BALL BANNER
// ==========================================================

class DrawBallBanner extends StatefulWidget {
  final String currentPlayerName;
  final List<String> drawPartnerNames;
  final int ballNumber;

  const DrawBallBanner({
    super.key,
    required this.currentPlayerName,
    required this.drawPartnerNames,
    required this.ballNumber,
  });

  @override
  State<DrawBallBanner> createState() => _DrawBallBannerState();
}

class _DrawBallBannerState extends State<DrawBallBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    HapticFeedback.mediumImpact();
    SoundService.instance.playDraw();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnersText = widget.drawPartnerNames.join(' & ');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF26C6DA).withValues(alpha: 0.22),
              const Color(0xFF26C6DA).withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF26C6DA).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.handshake_rounded,
                color: Color(0xFF26C6DA), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, height: 1.3),
                  children: [
                    const TextSpan(
                      text: 'Draw Ball! ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26C6DA),
                      ),
                    ),
                    TextSpan(
                      text: 'Pocketing ball ${widget.ballNumber} ties ',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    TextSpan(
                      text: widget.currentPlayerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26C6DA),
                      ),
                    ),
                    TextSpan(
                      text: ' with ',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    TextSpan(
                      text: partnersText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF26C6DA),
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
