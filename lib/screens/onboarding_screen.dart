import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/ball_painter.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Pulse animation for the money-ball page
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const int _pageCount = 5;

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pageCount - 1;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: skip ───────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: isLast ? null : widget.onComplete,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Page content ────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _TrackScoresPage(),
                  _ActionsPage(),
                  _MoneyBallPage(pulse: _pulse),
                  _PrizePage(),
                ],
              ),
            ),

            // ── Dot indicators ──────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? AppTheme.feltGreen
                        : Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),

            // ── Next / Get Started button ───────────────────────────────
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _GradientButton(
                label: isLast ? 'Get Started' : 'Next',
                onTap: _next,
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 1 — Welcome
// ════════════════════════════════════════════════════════════════════

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageShell(
      illustration: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.feltGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.feltGreen.withValues(alpha: 0.4),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: 'Welcome to ChalkMan',
      description:
          'The smart way to track pool scores, manage player turns, and settle payouts — all from your pocket.',
      badge: null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 2 — Track Scores
// ════════════════════════════════════════════════════════════════════

class _TrackScoresPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageShell(
      illustration: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini rack of 5 balls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [3, 5, 8, 11, 14]
                .map((n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: BallWidget(ballNumber: n, size: 42),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          // Mini scoreboard mockup
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.feltGreen.withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                _ScoreRow('Ali', 42, isLeader: true),
                Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06)),
                _ScoreRow('Ben', 28, isLeader: false),
                Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06)),
                _ScoreRow('Caro', 15, isLeader: false),
              ],
            ),
          ),
        ],
      ),
      title: 'Track Every Game',
      description:
          'Up to 20 players per game. Scores update in real time, players are ranked live, and you can undo any action instantly.',
      badge: null,
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String name;
  final int score;
  final bool isLeader;
  const _ScoreRow(this.name, this.score, {required this.isLeader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          if (isLeader)
            Icon(Icons.emoji_events_rounded,
                size: 14, color: AppTheme.accentGold)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: isLeader ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight:
                  isLeader ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            '$score',
            style: TextStyle(
              color: isLeader
                  ? AppTheme.feltGreen
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 3 — Game Actions
// ════════════════════════════════════════════════════════════════════

class _ActionsPage extends StatelessWidget {
  static const _actions = [
    ('Pocket', AppTheme.feltGreen, Icons.radio_button_checked_rounded),
    ('Combo', Color(0xFF4FC3F7), Icons.link_rounded),
    ('Through', Colors.white70, Icons.swap_horiz_rounded),
    ('Miss', Colors.white38, Icons.close_rounded),
    ('Scratch', Colors.redAccent, Icons.sports_bar_rounded),
    ('Wrong Ball', AppTheme.wrongBallColor, Icons.warning_amber_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      illustration: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _actions.map((a) {
          final (label, color, icon) = a;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      title: 'Tap the Right Action',
      description:
          'After every shot, tap what happened — Pocket, Combo, Miss, Scratch, or more. The app handles scoring, turns, and ball sequence automatically.',
      badge: null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 4 — Money Ball
// ════════════════════════════════════════════════════════════════════

class _MoneyBallPage extends StatelessWidget {
  final Animation<double> pulse;
  const _MoneyBallPage({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      illustration: AnimatedBuilder(
        animation: pulse,
        builder: (_, _) => Transform.scale(
          scale: pulse.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
              // Ball
              BallWidget(ballNumber: 8, size: 90, isTarget: true),
              // Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppTheme.accentGold.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    '💰 MONEY BALL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: 'Money Ball Alert',
      description:
          'When a player is one pocket away from an unbeatable win, the screen flashes and the phone vibrates with sound — so everyone knows the stakes.',
      badge: const Color(0xFFFFB300),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 5 — Prize Tracking
// ════════════════════════════════════════════════════════════════════

class _PrizePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageShell(
      illustration: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withValues(alpha: 0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: AppTheme.accentGold, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Prize Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Wager: KSH 50',
                  style: TextStyle(
                    color: AppTheme.accentGold.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BalanceRow('Ali', '+KSH 120', true),
            _BalanceRow('Ben', '-KSH 50', false),
            _BalanceRow('Caro', '-KSH 50', false),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.feltGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.feltGreen.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Board Fee',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11)),
                  Text('KSH 20',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      title: 'Built-in Prize Tracking',
      description:
          'Set a wager per player. The app tracks the prize pool, board fees, and chalk fees — and shows every player\'s running balance across multiple games.',
      badge: null,
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String name;
  final String amount;
  final bool isPositive;
  const _BalanceRow(this.name, this.amount, this.isPositive);

  @override
  Widget build(BuildContext context) {
    final color =
        isPositive ? AppTheme.feltGreen : Colors.redAccent.shade100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(amount,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Shared layout shell for every page
// ════════════════════════════════════════════════════════════════════

class _PageShell extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;
  final Color? badge; // accent for title text (null = white)

  const _PageShell({
    required this.illustration,
    required this.title,
    required this.description,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Illustration — upper 45%
          Expanded(
            flex: 45,
            child: Center(child: illustration),
          ),
          // Text — lower 55%
          Expanded(
            flex: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: badge ?? Colors.white,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.55,
                    fontWeight: FontWeight.w400,
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

// ════════════════════════════════════════════════════════════════════
//  Gradient "Next / Get Started" button
// ════════════════════════════════════════════════════════════════════

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppTheme.feltGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.feltGreen.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
