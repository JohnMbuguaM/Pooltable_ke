import 'package:flutter/material.dart';
import '../models/game.dart';
import 'player_card.dart';

class Scoreboard extends StatelessWidget {
  final Game game;
  final Function(String playerId)? onPlayerTap;

  const Scoreboard({super.key, required this.game, this.onPlayerTap});

  @override
  Widget build(BuildContext context) {
    // Sort: active players first (by score desc), then eliminated
    final activePlayers = game.activePlayers.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final eliminatedPlayers = game.eliminatedPlayers.toList()
      ..sort((a, b) => (b.eliminatedAtRound ?? 0).compareTo(a.eliminatedAtRound ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.leaderboard_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Scoreboard',
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
              Text(
                'Round ${game.roundNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        ...activePlayers.asMap().entries.map((entry) {
          final player = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: PlayerCard(
              player: player,
              isCurrentPlayer: player.id == game.currentPlayer.id,
              rank: entry.key + 1,
              onTap: onPlayerTap != null
                  ? () => onPlayerTap!(player.id)
                  : null,
            ),
          );
        }),
        if (eliminatedPlayers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, bottom: 6),
            child: Text(
              'Eliminated',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red.withValues(alpha: 0.6),
              ),
            ),
          ),
          ...eliminatedPlayers.map((player) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PlayerCard(
                player: player,
                isCurrentPlayer: false,
              ),
            );
          }),
        ],
      ],
    );
  }
}
