import 'package:flutter/material.dart';
import '../models/player.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isCurrentPlayer;
  final int rank;
  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.player,
    this.isCurrentPlayer = false,
    this.rank = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEliminated = player.isEliminated;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentPlayer
              ? AppTheme.feltGreen.withValues(alpha: 0.2)
              : isEliminated
                  ? Colors.red.withValues(alpha: 0.08)
                  : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentPlayer
                ? AppTheme.feltGreen
                : isEliminated
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.transparent,
            width: isCurrentPlayer ? 2 : 1,
          ),
          boxShadow: isCurrentPlayer
              ? [
                  BoxShadow(
                    color: AppTheme.feltGreen.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(context),
            const SizedBox(width: 12),

            // Name & status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isEliminated
                                ? Colors.white.withValues(alpha: 0.4)
                                : null,
                            decoration: isEliminated
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentPlayer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.feltGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TURN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                      if (isEliminated) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OUT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rank > 0)
                    Text(
                      Helpers.getOrdinal(rank),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),

            // Score
            _buildScore(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final initials = Helpers.getPlayerInitials(player.name);
    final avatarColors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF43E97B),
      const Color(0xFFFA8BFF),
      const Color(0xFFFFA751),
      const Color(0xFF00C9FF),
    ];

    final colorIndex = player.name.hashCode.abs() % avatarColors.length;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColors[colorIndex],
            avatarColors[colorIndex].withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColors[colorIndex].withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildScore(BuildContext context) {
    final isPositive = player.score > 0;
    final isNegative = player.score < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withValues(alpha: 0.12)
            : isNegative
                ? Colors.red.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${player.score}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isPositive
              ? Colors.green
              : isNegative
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
