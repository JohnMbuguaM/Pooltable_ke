import 'package:flutter/material.dart';
import '../models/action.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'ball_painter.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onPocket;
  final VoidCallback onMiss;
  final VoidCallback onNextPlayer;
  final Function(int ball) onCombo;
  final VoidCallback onNeutral;
  final Function(ActionType type, {int? ballNumber}) onPenalty;
  final VoidCallback onUndo;
  final bool canUndo;
  final List<int> remainingBalls;
  final int? currentTargetBall;

  const ActionButtons({
    super.key,
    required this.onPocket,
    required this.onMiss,
    required this.onNextPlayer,
    required this.onCombo,
    required this.onNeutral,
    required this.onPenalty,
    required this.onUndo,
    required this.canUndo,
    required this.remainingBalls,
    this.currentTargetBall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary actions
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _PrimaryActionButton(
                label: 'Pocket',
                sublabel: currentTargetBall != null
                    ? 'Ball $currentTargetBall'
                    : null,
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                onTap: onPocket,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PrimaryActionButton(
                label: 'Miss',
                sublabel: currentTargetBall != null
                    ? '-${AppConstants.getBallValue(currentTargetBall!)} pts'
                    : null,
                icon: Icons.close_rounded,
                color: Colors.red.shade400,
                onTap: onMiss,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PrimaryActionButton(
                label: 'Next',
                icon: Icons.skip_next_rounded,
                color: Colors.grey.shade600,
                onTap: onNextPlayer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: _SecondaryActionButton(
                label: 'Combo',
                icon: Icons.auto_awesome,
                color: AppTheme.accentGold,
                onTap: () => _showComboDialog(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SecondaryActionButton(
                label: 'Neutral',
                icon: Icons.remove_circle_outline,
                color: Colors.blueGrey,
                onTap: onNeutral,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SecondaryActionButton(
                label: 'Undo',
                icon: Icons.undo_rounded,
                color: Colors.orange,
                onTap: canUndo ? onUndo : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Foul/Penalty section
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Fouls',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FoulChip(
              label: 'Wrong Ball',
              icon: Icons.error_outline,
              onTap: () => _showWrongBallDialog(context),
            ),
            _FoulChip(
              label: 'Touch',
              icon: Icons.pan_tool_outlined,
              onTap: () => _showTouchFoulDialog(context),
            ),
            _FoulChip(
              label: 'Ball Off',
              icon: Icons.arrow_upward,
              onTap: () => _showBallOffDialog(context),
            ),
            _FoulChip(
              label: 'Cue Off',
              icon: Icons.north_east,
              onTap: () => onPenalty(ActionType.cueBallJumpedOff),
            ),
            _FoulChip(
              label: 'Carry',
              icon: Icons.swipe,
              onTap: () => onPenalty(ActionType.carryBall),
            ),
          ],
        ),
      ],
    );
  }

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
          // Process each selected ball as a combo shot
          for (final ball in selectedBalls) {
            onCombo(ball);
          }
        },
      ),
    );
  }

  void _showWrongBallDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      onPenalty(ActionType.wrongBallContact);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SingleSelectBallDialog(
        title: 'Wrong Ball Contact',
        subtitle: 'Select the ball that was hit first',
        remainingBalls: remainingBalls,
        onConfirm: (ball) {
          onPenalty(ActionType.wrongBallContact, ballNumber: ball);
        },
      ),
    );
  }

  void _showTouchFoulDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      onPenalty(ActionType.ballTouched);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _SingleSelectBallDialog(
        title: 'Ball Touched',
        subtitle: 'Select the ball that was touched',
        remainingBalls: remainingBalls,
        onConfirm: (ball) {
          onPenalty(ActionType.ballTouched, ballNumber: ball);
        },
      ),
    );
  }

  void _showBallOffDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      onPenalty(ActionType.ballJumpedOff);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _MultiSelectBallDialog(
        title: 'Balls Jumped Off',
        subtitle: 'Select all balls that jumped off the table',
        remainingBalls: remainingBalls,
        onConfirm: (selectedBalls) {
          // Process each selected ball
          for (final ball in selectedBalls) {
            onPenalty(ActionType.ballJumpedOff, ballNumber: ball);
          }
        },
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null
          ? color.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon,
                  color: onTap != null ? color : Colors.grey.shade600,
                  size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: onTap != null ? color : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.red.shade300),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Multi-select ball dialog for Combo and Ball Off
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            // Ball selection grid
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
                        ballNumber: ball,
                        isPocketed: false,
                        size: 42,
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Action buttons
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
                  child: Text('Confirm (${_selectedBalls.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Single-select ball dialog for Touch
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
  State<_SingleSelectBallDialog> createState() => _SingleSelectBallDialogState();
}

class _SingleSelectBallDialogState extends State<_SingleSelectBallDialog> {
  int? _selectedBall;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            // Ball selection grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.remainingBalls.map((ball) {
                final isSelected = _selectedBall == ball;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBall = ball;
                    });
                  },
                  child: Stack(
                    children: [
                      BallWidget(
                        ballNumber: ball,
                        isPocketed: false,
                        size: 42,
                      ),
                      if (isSelected)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Action buttons
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
                    backgroundColor: Colors.red.shade400,
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
