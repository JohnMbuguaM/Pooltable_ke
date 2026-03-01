import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../providers/prize_provider.dart';
import '../utils/theme.dart';

/// Premium prize/financial summary bar shown at the top of the game screen.
/// Displays Prize (this game), Board fees, and ChalkMan fees with
/// elevated gradient tiles and a glowing card container.
class PrizeSummaryCard extends StatelessWidget {
  final Game game;
  final bool isReadOnly;

  const PrizeSummaryCard({
    super.key,
    required this.game,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrizeProvider>(
      builder: (context, prize, _) {
        final session = prize.session;
        if (session == null) return const SizedBox.shrink();

        final config = session.config;
        final numPlayers = game.players.length;

        // Prize pool for this game
        final prizePool = config.prizePool(numPlayers);

        // Board: this game only (not accumulated session total)
        final boardTotal = config.boardFeePerGame;

        // Chalk projection for this game
        final wouldPayImmediately = config.shouldPayChalkmanImmediately(numPlayers);
        final projectedConsecutive =
            session.consecutiveLowPotGames + (wouldPayImmediately ? 0 : 1);
        final wouldPayThisGame = wouldPayImmediately || projectedConsecutive >= 3;
        // Accumulated unpaid chalk from previous low-pot games + this game's fee
        final chalkTotal = session.accumulatedChalkmanFee + config.chalkmanFeePerGame;
        final chalkPending = !wouldPayThisGame;
        final gamesUntilChalk = chalkPending ? (3 - projectedConsecutive) : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.feltGreen.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.feltGreen.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                // Game number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentGold.withValues(alpha: 0.22),
                        AppTheme.accentGold.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        config.wagerPerPlayer > 0
                            ? config.wagerPerPlayer.toStringAsFixed(0)
                            : 'Free',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentGold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        config.wagerPerPlayer > 0 ? 'KSH' : '',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGold.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Prize money tile
                Expanded(
                  child: _FinancialTile(
                    icon: Icons.emoji_events_rounded,
                    label: 'Prize',
                    value: 'KSH ${prizePool.toStringAsFixed(0)}',
                    accentColor: AppTheme.feltGreen,
                  ),
                ),
                const SizedBox(width: 6),

                // Board fee tile
                Expanded(
                  child: _FinancialTile(
                    icon: Icons.table_bar_rounded,
                    label: 'Board',
                    value: 'KSH ${boardTotal.toStringAsFixed(0)}',
                    accentColor: const Color(0xFF5C9BFF),
                  ),
                ),
                const SizedBox(width: 6),

                // ChalkMan fee tile
                Expanded(
                  child: _FinancialTile(
                    icon: Icons.sports_bar_rounded,
                    label: chalkPending
                        ? 'Chalk ($gamesUntilChalk)'
                        : 'Chalk',
                    value: 'KSH ${chalkTotal.toStringAsFixed(0)}',
                    accentColor: chalkPending
                        ? const Color(0xFFFF9100)
                        : const Color(0xFFB39DDB),
                    isPending: chalkPending,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FinancialTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isPending;

  const _FinancialTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.18),
            accentColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: isPending ? 0.45 : 0.28),
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accentColor),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: 0.1,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: accentColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
