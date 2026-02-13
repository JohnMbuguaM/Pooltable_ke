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
  final Function(List<int> balls) onThrough;
  final Function(List<int> balls) onThroughFoul;
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
    required this.onThrough,
    required this.onThroughFoul,
    required this.onPenalty,
    required this.onUndo,
    required this.canUndo,
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
        // Row 1: Pocket / Miss / Next — all equal
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.check_circle_rounded,
                label: 'Pocket',
                badge: pts != null ? '+$pts' : null,
                color: AppTheme.success,
                onTap: onPocket,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ActionTile(
                icon: Icons.close_rounded,
                label: 'Miss',
                badge: pts != null ? '-$pts' : null,
                color: Colors.red.shade400,
                onTap: onMiss,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ActionTile(
                icon: Icons.skip_next_rounded,
                label: 'Next',
                color: Colors.blueGrey,
                onTap: onNextPlayer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Row 2: Combo / Through / Undo — all equal
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.auto_awesome,
                label: 'Combo',
                color: AppTheme.accentGold,
                onTap: () => _showComboDialog(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ActionTile(
                icon: Icons.compare_arrows,
                label: 'Through',
                color: Colors.blue,
                onTap: () => _showThroughDialog(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ActionTile(
                icon: Icons.undo_rounded,
                label: 'Undo',
                color: Colors.orange,
                onTap: canUndo ? onUndo : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Fouls — wrap so all chips are fully visible
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
              label: 'Scratch',
              icon: Icons.cancel,
              onTap: () => onPenalty(ActionType.cueBallScratch),
            ),
            _FoulChip(
              label: 'Thru+Foul',
              icon: Icons.warning_amber_rounded,
              onTap: () => _showThroughFoulDialog(context),
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
          onThroughFoul(balls);
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
          onThrough(balls);
        },
      ),
    );
  }
}

// ============================================================
//  BUTTON WIDGETS
// ============================================================

/// Uniform action tile with icon + label, optional point badge.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.badge,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveColor = isEnabled ? color : Colors.grey.shade500;

    return Material(
      color: effectiveColor.withValues(alpha: isEnabled ? 0.1 : 0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: effectiveColor, size: 17),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: effectiveColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 3),
                Text(
                  badge!,
                  style: TextStyle(
                    color: effectiveColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
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
      color: Colors.red.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.red.shade300),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              color: Colors.green,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              color: Colors.green,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              color: isFirst ? Colors.red : Colors.green,
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                    backgroundColor: Colors.red.shade400,
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
