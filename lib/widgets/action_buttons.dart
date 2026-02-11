import 'package:flutter/material.dart';
import '../models/action.dart';
import '../utils/theme.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onPocket;
  final VoidCallback onMiss;
  final Function(int ball) onCombo;
  final VoidCallback onNeutral;
  final Function(ActionType type) onPenalty;
  final VoidCallback onUndo;
  final bool canUndo;
  final List<int> remainingBalls;
  final int? currentTargetBall;

  const ActionButtons({
    super.key,
    required this.onPocket,
    required this.onMiss,
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
                icon: Icons.close_rounded,
                color: Colors.grey.shade600,
                onTap: onMiss,
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
              onTap: () => onPenalty(ActionType.wrongBallContact),
            ),
            _FoulChip(
              label: 'Scratch',
              icon: Icons.lens_outlined,
              onTap: () => onPenalty(ActionType.cueBallScratch),
            ),
            _FoulChip(
              label: 'Touch',
              icon: Icons.pan_tool_outlined,
              onTap: () => onPenalty(ActionType.ballTouched),
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
    final comboBalls =
        remainingBalls.where((b) => b != currentTargetBall).toList();
    if (comboBalls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other balls available for combo')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select ball pocketed in combo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: comboBalls.map((ball) {
                  return ActionChip(
                    label: Text('Ball $ball',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onCombo(ball);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBallOffDialog(BuildContext context) {
    if (remainingBalls.isEmpty) {
      onPenalty(ActionType.ballJumpedOff);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which ball jumped off?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: remainingBalls.map((ball) {
                  return ActionChip(
                    label: Text('Ball $ball',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onPenalty(ActionType.ballJumpedOff);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
