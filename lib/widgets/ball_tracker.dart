import 'package:flutter/material.dart';
import '../models/game.dart';
import '../utils/constants.dart';
import 'ball_painter.dart';

class BallTracker extends StatelessWidget {
  final Game game;
  final Function(int ballNumber)? onBallTap;
  final Function(int ballNumber)? onBallLongPress;

  const BallTracker({
    super.key,
    required this.game,
    this.onBallTap,
    this.onBallLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final targetBall = game.currentTargetBall;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.sports_bar,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Ball Tracker',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    targetBall > 0 ? 'Target: $targetBall' : 'Game Over',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ball sequence display - show in game sequence order
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.ballSequence.map((ball) {
              final isPocketed = game.pocketedBalls.contains(ball);
              final isTarget = ball == targetBall;

              return BallWidget(
                ballNumber: ball,
                isPocketed: isPocketed,
                isTarget: isTarget,
                size: 36,
                onTap: onBallTap != null && !isPocketed
                    ? () => onBallTap!(ball)
                    : null,
                onLongPress: onBallLongPress != null && isPocketed
                    ? () => onBallLongPress!(ball)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                label: 'Remaining',
                value: '${game.remainingBalls.length}',
                color: Colors.green,
              ),
              _StatChip(
                label: 'Pocketed',
                value: '${game.pocketedBalls.length}',
                color: Colors.orange,
              ),
              _StatChip(
                label: 'Points Left',
                value: '${game.remainingBallsValue}',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
