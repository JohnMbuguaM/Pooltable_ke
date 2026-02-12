import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers for different scenes
  late AnimationController _sceneController;
  late AnimationController _cueController;
  late AnimationController _scatterController;
  late AnimationController _logoController;

  // Animations
  late Animation<double> _zoomAnimation;
  late Animation<double> _cuePosition;
  late Animation<double> _impactScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _shimmer;

  final List<_BallAnimation> _ballAnimations = [];
  bool _showRack = true;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();

    // Scene 1: Camera zoom (0-1.5s)
    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _sceneController, curve: Curves.easeInOut),
    );

    // Scene 2: Cue ball approach (1.5-2.5s)
    _cueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _cuePosition = Tween<double>(begin: 1.5, end: 0.0).animate(
      CurvedAnimation(parent: _cueController, curve: Curves.easeIn),
    );
    _impactScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _cueController, curve: Curves.elasticOut),
    );

    // Scene 3: Balls scatter (2.5-4s)
    _scatterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Scene 4: Logo reveal (4-5.5s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Initialize ball scatter animations
    _initializeBallAnimations();

    // Start animation sequence
    _startAnimationSequence();
  }

  void _initializeBallAnimations() {
    final random = Random();
    // 15 balls in triangle rack
    for (int i = 1; i <= 15; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 0.4 + random.nextDouble() * 0.6;
      _ballAnimations.add(_BallAnimation(
        ballNumber: i,
        targetX: cos(angle) * speed,
        targetY: sin(angle) * speed,
      ));
    }
  }

  Future<void> _startAnimationSequence() async {
    // Scene 1: Zoom in (0-1.5s)
    await _sceneController.forward();

    // Scene 2: Cue ball breaks (1.5-2.5s)
    _cueController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Hide rack, show scatter
    setState(() {
      _showRack = false;
    });

    // Scene 3: Balls scatter (2.5-4s)
    await _scatterController.forward();

    // Scene 4: Logo reveal (4-5.5s)
    setState(() {
      _showLogo = true;
    });
    await _logoController.forward();

    // Hold logo for a moment
    await Future.delayed(const Duration(milliseconds: 800));

    // Navigate to home
    widget.onComplete();
  }

  @override
  void dispose() {
    _sceneController.dispose();
    _cueController.dispose();
    _scatterController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E), // Deep emerald felt
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _sceneController,
          _cueController,
          _scatterController,
          _logoController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background with vignette
              _buildBackground(),

              // Main scene
              Transform.scale(
                scale: _zoomAnimation.value,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Racked balls
                      if (_showRack) _buildRackedBalls(),

                      // Scattered balls
                      if (!_showRack) _buildScatteredBalls(),

                      // Cue ball
                      if (_cueController.isAnimating || _cueController.isCompleted)
                        _buildCueBall(),
                    ],
                  ),
                ),
              ),

              // Logo overlay
              if (_showLogo) _buildLogoReveal(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            const Color(0xFF0B3D2E),
            const Color(0xFF051F1A),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _VignettePainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildRackedBalls() {
    return Transform.scale(
      scale: _impactScale.value,
      child: CustomPaint(
        painter: _RackPainter(),
        size: const Size(200, 200),
      ),
    );
  }

  Widget _buildScatteredBalls() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: _ballAnimations.map((ballAnim) {
          final progress = _scatterController.value;
          final x = ballAnim.targetX * progress * 400;
          final y = ballAnim.targetY * progress * 400;
          final opacity = 1.0 - (progress * 0.7);

          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - 20,
            top: MediaQuery.of(context).size.height / 2 + y - 20,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: _buildPoolBall(ballAnim.ballNumber, 40),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCueBall() {
    final position = _cuePosition.value;
    return Positioned(
      bottom: MediaQuery.of(context).size.height * position,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: [
              Colors.white,
              const Color(0xFFE0E0E0),
              const Color(0xFFBDBDBD),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolBall(int number, double size) {
    final colors = {
      1: 0xFFF4C430, 2: 0xFF0066CC, 3: 0xFFCC0000, 4: 0xFF9966CC,
      5: 0xFFFF6600, 6: 0xFF006600, 7: 0xFF990000, 8: 0xFF000000,
      9: 0xFFF4C430, 10: 0xFF0066CC, 11: 0xFFCC0000, 12: 0xFF9966CC,
      13: 0xFFFF6600, 14: 0xFF006600, 15: 0xFF990000,
    };

    final isStriped = number > 8;
    final color = Color(colors[number] ?? 0xFFFFFFFF);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isStriped
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, color, color, Colors.white],
                stops: const [0.0, 0.3, 0.7, 1.0],
              )
            : RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 0.8,
                colors: [
                  Color.lerp(color, Colors.white, 0.3)!,
                  color,
                  Color.lerp(color, Colors.black, 0.3)!,
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Colors.black,
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoReveal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85 * _logoFade.value),
      child: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0xFFD4AF37),
                        Color(0xFFF5D76E),
                        Color(0xFFD4AF37),
                      ],
                      stops: [
                        (_shimmer.value - 0.3).clamp(0.0, 1.0),
                        _shimmer.value.clamp(0.0, 1.0),
                        (_shimmer.value + 0.3).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'CHALKMAN',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ABDUL TECH SOLUTION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
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

class _BallAnimation {
  final int ballNumber;
  final double targetX;
  final double targetY;

  _BallAnimation({
    required this.ballNumber,
    required this.targetX,
    required this.targetY,
  });
}

class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.7),
      ],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const ballSize = 28.0;
    const spacing = 2.0;

    // Triangle rack positions (5 rows)
    final positions = [
      // Row 1
      [const Offset(0, 0)],
      // Row 2
      [
        const Offset(-(ballSize + spacing) / 2, (ballSize + spacing) * 0.866),
        const Offset((ballSize + spacing) / 2, (ballSize + spacing) * 0.866)
      ],
      // Row 3
      [
        const Offset(-(ballSize + spacing), (ballSize + spacing) * 1.732),
        const Offset(0, (ballSize + spacing) * 1.732),
        const Offset((ballSize + spacing), (ballSize + spacing) * 1.732),
      ],
      // Row 4
      [
        const Offset(-(ballSize + spacing) * 1.5, (ballSize + spacing) * 2.598),
        const Offset(-(ballSize + spacing) * 0.5, (ballSize + spacing) * 2.598),
        const Offset((ballSize + spacing) * 0.5, (ballSize + spacing) * 2.598),
        const Offset((ballSize + spacing) * 1.5, (ballSize + spacing) * 2.598),
      ],
      // Row 5
      [
        const Offset(-(ballSize + spacing) * 2, (ballSize + spacing) * 3.464),
        const Offset(-(ballSize + spacing), (ballSize + spacing) * 3.464),
        const Offset(0, (ballSize + spacing) * 3.464),
        const Offset((ballSize + spacing), (ballSize + spacing) * 3.464),
        const Offset((ballSize + spacing) * 2, (ballSize + spacing) * 3.464),
      ],
    ];

    int ballNumber = 1;
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 40;

    for (final row in positions) {
      for (final pos in row) {
        _drawBall(canvas, centerX + pos.dx, centerY + pos.dy, ballNumber);
        ballNumber++;
      }
    }
  }

  void _drawBall(Canvas canvas, double x, double y, int number) {
    const ballSize = 28.0;
    final colors = {
      1: 0xFFF4C430, 2: 0xFF0066CC, 3: 0xFFCC0000, 4: 0xFF9966CC,
      5: 0xFFFF6600, 6: 0xFF006600, 7: 0xFF990000, 8: 0xFF000000,
      9: 0xFFF4C430, 10: 0xFF0066CC, 11: 0xFFCC0000, 12: 0xFF9966CC,
      13: 0xFFFF6600, 14: 0xFF006600, 15: 0xFF990000,
    };

    final ballRect = Rect.fromCircle(center: Offset(x, y), radius: ballSize / 2);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(x + 2, y + 3), ballSize / 2, shadowPaint);

    // Ball gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: [
        Color.lerp(Color(colors[number]!), Colors.white, 0.4)!,
        Color(colors[number]!),
        Color.lerp(Color(colors[number]!), Colors.black, 0.3)!,
      ],
    );

    final ballPaint = Paint()..shader = gradient.createShader(ballRect);
    canvas.drawCircle(Offset(x, y), ballSize / 2, ballPaint);

    // Number circle
    final numberCirclePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(x, y), ballSize * 0.25, numberCirclePaint);

    // Number text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
