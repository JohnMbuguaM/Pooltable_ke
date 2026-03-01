import 'dart:math';
import 'package:flutter/material.dart';
import '../models/action.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'ball_painter.dart';

class ActionButtons extends StatelessWidget {
  final List<Player> activePlayers;
  final String currentPlayerId;
  final Function(String playerId) onSelectPlayer;
  final VoidCallback onPocket;
  final VoidCallback onMiss;
  final VoidCallback onNextPlayer;
  final Function(int ball) onCombo;
  final Function(List<int> balls) onThrough;
  final Function(List<int> balls) onThroughFoul;
  final Function(ActionType type, {int? ballNumber}) onPenalty;
  final VoidCallback onUndo;
  final bool canUndo;
  final VoidCallback onRedo;
  final bool canRedo;
  final List<int> remainingBalls;
  final int? currentTargetBall;

  const ActionButtons({
    super.key,
    required this.activePlayers,
    required this.currentPlayerId,
    required this.onSelectPlayer,
    required this.onPocket,
    required this.onMiss,
    required this.onNextPlayer,
    required this.onCombo,
    required this.onThrough,
    required this.onThroughFoul,
    required this.onPenalty,
    required this.onUndo,
    required this.canUndo,
    required this.onRedo,
    required this.canRedo,
    required this.remainingBalls,
    this.currentTargetBall,
  });

  @override
  Widget build(BuildContext context) {
    final pts = currentTargetBall != null
        ? AppConstants.getBallValue(currentTargetBall!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row 1: Top-3 most-used actions ──────────────────────────────────
        Row(
          children: [
            // Pocket — #1 most used
            Expanded(
              flex: 2,
              child: _ActionTile(
                icon: Icons.check_circle_rounded,
                label: 'Pocket',
                badge: pts != null ? '+$pts' : null,
                color: AppTheme.success,
                onTap: () => _showPlayerPicker(
                  context,
                  title: 'Who pocketed the ball?',
                  onConfirm: (id) {
                    onSelectPlayer(id);
                    onPocket();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Miss — #2 most used
            Expanded(
              flex: 2,
              child: _ActionTile(
                icon: Icons.close_rounded,
                label: 'Miss',
                badge: pts != null ? '-$pts' : null,
                color: AppTheme.error,
                onTap: () => _showPlayerPicker(
                  context,
                  title: 'Who missed?',
                  onConfirm: (id) {
                    onSelectPlayer(id);
                    onMiss();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Wrong Ball — #3 most used (elevated from foul chips)
            Expanded(
              flex: 2,
              child: _ActionTile(
                icon: Icons.do_not_touch_rounded,
                iconWidget: const _WrongBallIcon(size: 30),
                label: 'Wrong Ball',
                color: AppTheme.wrongBallColor,
                onTap: () => _showWrongBallDialog(context),
                isHighlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Row 2: Secondary actions ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.auto_awesome_rounded,
                iconWidget: const _MultiBallIcon(size: 26),
                label: 'Combo',
                color: AppTheme.accentGold,
                onTap: () => _showComboDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.compare_arrows_rounded,
                label: 'Through',
                color: AppTheme.info,
                onTap: () => _showThroughDialog(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.undo_rounded,
                label: 'Undo',
                color: Colors.orange.shade400,
                onTap: canUndo ? onUndo : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionTile(
                icon: Icons.redo_rounded,
                label: 'Redo',
                color: Colors.deepPurple.shade300,
                onTap: canRedo ? onRedo : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Row 3: Remaining foul chips ──────────────────────────────────────
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FoulChip(
              label: 'Scratch',
              icon: Icons.cancel_rounded,
              onTap: () => _showPlayerPicker(
                context,
                title: 'Who scratched (cue ball)?',
                onConfirm: (id) {
                  onSelectPlayer(id);
                  onPenalty(ActionType.cueBallScratch);
                },
              ),
            ),
            _FoulChip(
              label: 'Thru+Foul',
              icon: Icons.warning_amber_rounded,
              onTap: () => _showThroughFoulDialog(context),
            ),
            _FoulChip(
              label: 'Carry',
              icon: Icons.swipe_rounded,
              onTap: () => _showPlayerPicker(
                context,
                title: 'Who carried the ball?',
                onConfirm: (id) {
                  onSelectPlayer(id);
                  onPenalty(ActionType.carryBall);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Player picker ──────────────────────────────────────────────────────────

  void _showPlayerPicker(
    BuildContext context, {
    required String title,
    required Function(String playerId) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _PlayerPickerDialog(
        title: title,
        activePlayers: activePlayers,
        initialPlayerId: currentPlayerId,
        onConfirm: onConfirm,
      ),
    );
  }

  // ── Ball selection dialogs ─────────────────────────────────────────────────

  void _showComboDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balls available for combo')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _MultiSelectBallDialog(
        title: 'Select Balls Pocketed in Combo',
        subtitle: 'Tap balls to select, then confirm',
        remainingBalls: remainingBalls,
        onConfirm: (selectedBalls) {
          _showPlayerPicker(
            context,
            title: 'Who made the combo?',
            onConfirm: (id) {
              onSelectPlayer(id);
              for (final ball in selectedBalls) {
                onCombo(ball);
              }
            },
          );
        },
      ),
    );
  }

  void _showWrongBallDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      _showPlayerPicker(
        context,
        title: 'Who hit the wrong ball?',
        onConfirm: (id) {
          onSelectPlayer(id);
          onPenalty(ActionType.wrongBallContact);
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SingleSelectBallDialog(
        title: 'Wrong Ball Contact',
        subtitle: 'Select the ball that was hit first',
        remainingBalls: remainingBalls,
        onConfirm: (ball) {
          _showPlayerPicker(
            context,
            title: 'Who hit the wrong ball?',
            onConfirm: (id) {
              onSelectPlayer(id);
              onPenalty(ActionType.wrongBallContact, ballNumber: ball);
            },
          );
        },
      ),
    );
  }

  void _showThroughFoulDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balls available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _OrderedMultiSelectBallDialog(
        title: 'Through + Foul',
        subtitle:
            'Select ball(s) pocketed. The FIRST ball selected determines the penalty.',
        remainingBalls: remainingBalls,
        onConfirm: (balls) {
          _showPlayerPicker(
            context,
            title: 'Who made the through + foul?',
            onConfirm: (id) {
              onSelectPlayer(id);
              onThroughFoul(balls);
            },
          );
        },
      ),
    );
  }

  void _showThroughDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No balls available for through shot')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _MultiSelectBallDialog(
        title: 'Through Shot',
        subtitle: 'Select ball(s) pocketed with the cue ball',
        remainingBalls: remainingBalls,
        onConfirm: (balls) {
          _showPlayerPicker(
            context,
            title: 'Who made the through shot?',
            onConfirm: (id) {
              onSelectPlayer(id);
              onThrough(balls);
            },
          );
        },
      ),
    );
  }
}

// ============================================================
//  PLAYER PICKER DIALOG
// ============================================================

class _PlayerPickerDialog extends StatefulWidget {
  final String title;
  final List<Player> activePlayers;
  final String initialPlayerId;
  final Function(String playerId) onConfirm;

  const _PlayerPickerDialog({
    required this.title,
    required this.activePlayers,
    required this.initialPlayerId,
    required this.onConfirm,
  });

  @override
  State<_PlayerPickerDialog> createState() => _PlayerPickerDialogState();
}

class _PlayerPickerDialogState extends State<_PlayerPickerDialog> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialPlayerId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.activePlayers.map((p) {
              final isSelected = _selectedId == p.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedId = p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.feltGreen.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.feltGreen.withValues(alpha: 0.6)
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.feltGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.feltGreen
                                : Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? AppTheme.feltGreen : null,
                          ),
                        ),
                      ),
                      Text(
                        '${p.score} pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onConfirm(_selectedId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.feltGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  BUTTON WIDGETS
// ============================================================

/// Animated action tile with icon above label, optional point badge.
/// Supports a subtle scale-down animation on press for tactile feedback.
class _ActionTile extends StatefulWidget {
  final IconData icon;
  /// Optional custom widget to render instead of [icon].
  final Widget? iconWidget;
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _ActionTile({
    required this.icon,
    this.iconWidget,
    required this.label,
    this.badge,
    required this.color,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 0.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;
    final effectiveColor =
        isEnabled ? widget.color : Colors.grey.shade600;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: effectiveColor.withValues(
                  alpha: isEnabled ? (widget.isHighlighted ? 0.16 : 0.11) : 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: effectiveColor.withValues(
                    alpha: isEnabled ? (widget.isHighlighted ? 0.5 : 0.28) : 0.1),
                width: widget.isHighlighted ? 2.0 : 1.5,
              ),
              boxShadow: isEnabled && widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              splashColor: effectiveColor.withValues(alpha: 0.18),
              highlightColor: effectiveColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.iconWidget ?? Icon(widget.icon, color: effectiveColor, size: 26),
                    const SizedBox(height: 5),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: effectiveColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    if (widget.badge != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badge!,
                          style: TextStyle(
                            color: effectiveColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small foul chip with icon + label.
class _FoulChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FoulChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          splashColor: Colors.red.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.red.shade400),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

// ============================================================
//  CUSTOM ICON WIDGETS
// ============================================================

/// Pool ball circle with a red prohibition (no-entry) overlay —
/// used as the Wrong Ball action icon.
class _WrongBallIcon extends StatelessWidget {
  final double size;
  const _WrongBallIcon({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ball base
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
                colors: [
                  AppTheme.wrongBallColor.withValues(alpha: 0.7),
                  AppTheme.wrongBallColor.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.38,
                  height: 1,
                ),
              ),
            ),
          ),
          // Prohibition overlay
          CustomPaint(
            painter: _ProhibitPainter(
              color: Colors.red.shade700,
              strokeFraction: 0.14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProhibitPainter extends CustomPainter {
  final Color color;
  final double strokeFraction;

  const _ProhibitPainter({required this.color, this.strokeFraction = 0.13});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * strokeFraction;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final r = size.width / 2 - stroke / 2;
    final c = Offset(size.width / 2, size.height / 2);

    // Circle
    canvas.drawCircle(c, r, paint);

    // Diagonal slash (top-right → bottom-left)
    final angle = pi * 0.75; // 135 degrees
    canvas.drawLine(
      c + Offset(cos(angle) * r, sin(angle) * r),
      c + Offset(cos(angle + pi) * r, sin(angle + pi) * r),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProhibitPainter old) =>
      old.color != color || old.strokeFraction != strokeFraction;
}

/// Three overlapping mini pool-ball circles — used as the Combo action icon.
class _MultiBallIcon extends StatelessWidget {
  final double size;
  const _MultiBallIcon({this.size = 26});

  static const _ballData = [
    (color: Color(0xFFFFD700), num: '1', dx: -0.32, dy: 0.1),   // yellow
    (color: Color(0xFF1565C0), num: '4', dx:  0.32, dy: 0.1),   // blue
    (color: Color(0xFFFF0000), num: '3', dx:  0.0,  dy: -0.25), // red
  ];

  @override
  Widget build(BuildContext context) {
    final ballSize = size * 0.55;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: _ballData.map((b) {
          return Transform.translate(
            offset: Offset(b.dx * size, b.dy * size),
            child: Container(
              width: ballSize,
              height: ballSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.85,
                  colors: [
                    Color.lerp(b.color, Colors.white, 0.35)!,
                    b.color,
                    Color.lerp(b.color, Colors.black, 0.25)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 2,
                    offset: const Offset(0.5, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  b.num,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: ballSize * 0.42,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
//  BALL SELECTION DIALOGS
// ============================================================

class _MultiSelectBallDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<int> remainingBalls;
  final Function(List<int>) onConfirm;

  const _MultiSelectBallDialog({
    required this.title,
    required this.subtitle,
    required this.remainingBalls,
    required this.onConfirm,
  });

  @override
  State<_MultiSelectBallDialog> createState() => _MultiSelectBallDialogState();
}

class _MultiSelectBallDialogState extends State<_MultiSelectBallDialog> {
  final Set<int> _selectedBalls = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.remainingBalls.map((ball) {
                final isSelected = _selectedBalls.contains(ball);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBalls.remove(ball);
                      } else {
                        _selectedBalls.add(ball);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      BallWidget(
                          ballNumber: ball, isPocketed: false, size: 42),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.feltGreen,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedBalls.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onConfirm(_selectedBalls.toList()..sort());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.feltGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Next (${_selectedBalls.length} balls)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleSelectBallDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<int> remainingBalls;
  final Function(int) onConfirm;

  const _SingleSelectBallDialog({
    required this.title,
    required this.subtitle,
    required this.remainingBalls,
    required this.onConfirm,
  });

  @override
  State<_SingleSelectBallDialog> createState() =>
      _SingleSelectBallDialogState();
}

class _SingleSelectBallDialogState extends State<_SingleSelectBallDialog> {
  int? _selectedBall;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.remainingBalls.map((ball) {
                final isSelected = _selectedBall == ball;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBall = ball),
                  child: Stack(
                    children: [
                      BallWidget(
                          ballNumber: ball, isPocketed: false, size: 42),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.wrongBallColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedBall == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onConfirm(_selectedBall!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.wrongBallColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderedMultiSelectBallDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<int> remainingBalls;
  final Function(List<int>) onConfirm;

  const _OrderedMultiSelectBallDialog({
    required this.title,
    required this.subtitle,
    required this.remainingBalls,
    required this.onConfirm,
  });

  @override
  State<_OrderedMultiSelectBallDialog> createState() =>
      _OrderedMultiSelectBallDialogState();
}

class _OrderedMultiSelectBallDialogState
    extends State<_OrderedMultiSelectBallDialog> {
  final List<int> _selectedBalls = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.remainingBalls.map((ball) {
                final selectionIndex = _selectedBalls.indexOf(ball);
                final isSelected = selectionIndex >= 0;
                final isFirst = selectionIndex == 0;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBalls.remove(ball);
                      } else {
                        _selectedBalls.add(ball);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      BallWidget(
                          ballNumber: ball, isPocketed: false, size: 42),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isFirst ? AppTheme.error : AppTheme.feltGreen,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${selectionIndex + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (_selectedBalls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Penalty: -${AppConstants.getBallValue(_selectedBalls.first)} pts (ball ${_selectedBalls.first})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade300,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedBalls.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onConfirm(List.from(_selectedBalls));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Next (${_selectedBalls.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
