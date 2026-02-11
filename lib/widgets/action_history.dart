import 'package:flutter/material.dart';
import '../models/action.dart';
import '../utils/helpers.dart';

class ActionHistory extends StatelessWidget {
  final List<GameAction> actions;
  final int maxItems;

  const ActionHistory({
    super.key,
    required this.actions,
    this.maxItems = 20,
  });

  @override
  Widget build(BuildContext context) {
    final displayActions = actions.reversed.take(maxItems).toList();

    if (displayActions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.history,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Text(
                'No actions yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayActions.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final action = displayActions[index];
        return _ActionTile(action: action);
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final GameAction action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(action.type);
    final icon = _getActionIcon(action.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.description ?? action.type.label,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  Helpers.formatTime(action.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          if (action.pointsChange != 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: action.pointsChange > 0
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                action.pointsChange > 0
                    ? '+${action.pointsChange}'
                    : '${action.pointsChange}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: action.pointsChange > 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getActionColor(ActionType type) {
    if (type.isPositive) return Colors.green;
    if (type.isNeutral) return Colors.blueGrey;
    if (type == ActionType.handicapAdjustment) return Colors.orange;
    return Colors.red;
  }

  IconData _getActionIcon(ActionType type) {
    switch (type) {
      case ActionType.successfulPocket:
        return Icons.check_circle;
      case ActionType.combinationShot:
        return Icons.auto_awesome;
      case ActionType.neutralShot:
        return Icons.remove_circle_outline;
      case ActionType.wrongBallContact:
        return Icons.error_outline;
      case ActionType.cueBallScratch:
        return Icons.lens_outlined;
      case ActionType.ballTouched:
        return Icons.pan_tool;
      case ActionType.ballJumpedOff:
        return Icons.arrow_upward;
      case ActionType.cueBallJumpedOff:
        return Icons.north_east;
      case ActionType.bothJumpedOff:
        return Icons.unfold_more;
      case ActionType.carryBall:
        return Icons.swipe;
      case ActionType.handicapAdjustment:
        return Icons.balance;
    }
  }
}
