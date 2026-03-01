import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class Scoreboard extends StatefulWidget {
  final Game game;
  final Function(String playerId)? onPlayerTap;
  final Function(String playerId, int currentScore)? onPlayerLongPress;

  /// When true, the rank-dot in each column header is replaced by a wager
  /// confirmation checkbox. Only set this when wagerPerPlayer > 0.
  final bool wagerActive;

  /// Map of player name (display name) → whether they confirmed their wager.
  final Map<String, bool> wagerConfirmedMap;

  /// Called with the player's display name when their wager tick is tapped.
  final Function(String playerName)? onToggleWager;

  const Scoreboard({
    super.key,
    required this.game,
    this.onPlayerTap,
    this.onPlayerLongPress,
    this.wagerActive = false,
    this.wagerConfirmedMap = const {},
    this.onToggleWager,
  });

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  bool _expanded = false;

  Map<String, int> _computeRanks() {
    final sorted = List<Player>.from(widget.game.players)
      ..sort((a, b) => b.score.compareTo(a.score));
    final ranks = <String, int>{};
    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].score == sorted[i - 1].score) {
        ranks[sorted[i].id] = ranks[sorted[i - 1].id]!;
      } else {
        ranks[sorted[i].id] = i + 1;
      }
    }
    return ranks;
  }

  ({List<Map<String, int?>> rows, Map<String, int> totals}) _buildScoreGrid() {
    final rows = <Map<String, int?>>[];
    final totals = <String, int>{};
    for (final player in widget.game.players) {
      totals[player.id] = 0;
    }
    for (final action in widget.game.actions) {
      if (action.pointsChange == 0) continue;
      if (!totals.containsKey(action.playerId)) continue;
      totals[action.playerId] =
          totals[action.playerId]! + action.pointsChange;
      final row = <String, int?>{};
      for (final player in widget.game.players) {
        row[player.id] =
            (player.id == action.playerId) ? totals[action.playerId] : null;
      }
      rows.add(row);
    }
    return (rows: rows, totals: totals);
  }

  @override
  Widget build(BuildContext context) {
    final ranks = _computeRanks();
    final grid = _buildScoreGrid();
    final rows = grid.rows;
    final totals = grid.totals;
    final rowCount = rows.length;
    final hasHistory = rowCount > 0;
    final playerCount = widget.game.players.length;
    const double minCellWidth = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsInline = playerCount * minCellWidth <= constraints.maxWidth;

        Widget buildCellRow(List<Widget> cells) {
          if (fitsInline) {
            return Row(
              children: cells.map((c) => Expanded(child: c)).toList(),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: cells
                .map((c) => SizedBox(width: minCellWidth, child: c))
                .toList(),
          );
        }

        final tableContent = Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.feltGreen.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient strip
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkElevated,
                      AppTheme.darkCard,
                    ],
                  ),
                ),
                child: buildCellRow(_headerCells(context, ranks)),
              ),
              Container(
                height: 1,
                color: AppTheme.feltGreen.withValues(alpha: 0.18),
              ),
              // Expand/collapse toggle
              if (hasHistory)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withValues(alpha: 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: AppTheme.feltGreen.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _expanded ? 'Hide history' : '$rowCount entries',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.feltGreen.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // History rows (only when expanded)
              if (_expanded)
                ...rows.asMap().entries.map((entry) => Container(
                      color: entry.key.isEven
                          ? Colors.white.withValues(alpha: 0.015)
                          : Colors.transparent,
                      child: buildCellRow(_historyCells(context, entry.value)),
                    )),
              // Total row — always shown, with elevated styling
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.darkElevated.withValues(alpha: 0.5),
                      AppTheme.darkElevated,
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.feltGreen.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: buildCellRow(_totalCells(context, totals)),
              ),
            ],
          ),
        );

        if (!fitsInline) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tableContent,
          );
        }
        return tableContent;
      },
    );
  }

  // ── Cell builders ────────────────────────────────────────

  List<Widget> _headerCells(BuildContext context, Map<String, int> ranks) {
    return widget.game.players.asMap().entries.map((entry) {
      final player = entry.value;
      final isCurrent = player.id == widget.game.currentPlayer.id;
      final isEliminated = player.isEliminated;
      final rank = ranks[player.id] ?? widget.game.players.length;
      final wagerConfirmed =
          widget.wagerConfirmedMap[player.name] ?? false;

      return GestureDetector(
        onTap: widget.onPlayerTap != null
            ? () => widget.onPlayerTap!(player.id)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isCurrent
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.feltGreen.withValues(alpha: 0.18),
                      AppTheme.feltGreen.withValues(alpha: 0.06),
                    ],
                  )
                : null,
            border: isCurrent
                ? const Border(
                    bottom: BorderSide(
                      color: AppTheme.feltGreen,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wager tick (when wager active) or rank dot
              if (widget.wagerActive)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onToggleWager != null
                      ? () => widget.onToggleWager!(player.name)
                      : null,
                  child: _WagerTick(confirmed: wagerConfirmed),
                )
              else
                _RankDot(rank: rank, isEliminated: isEliminated),
              const SizedBox(height: 3),
              Text(
                Helpers.getPlayerInitials(player.name),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isEliminated
                      ? Colors.white.withValues(alpha: 0.2)
                      : isCurrent
                          ? AppTheme.feltGreen
                          : Colors.white.withValues(alpha: 0.85),
                  decoration:
                      isEliminated ? TextDecoration.lineThrough : null,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              if (isCurrent && !isEliminated)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: AppTheme.feltGradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.feltGreen.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'TURN',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else if (isEliminated)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'OUT',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _historyCells(
      BuildContext context, Map<String, int?> row) {
    return widget.game.players.map((player) {
      final isCurrent = player.id == widget.game.currentPlayer.id;
      final score = row[player.id];

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.feltGreen.withValues(alpha: 0.04)
              : null,
        ),
        child: Center(
          child: score != null
              ? Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: score > 0
                        ? Colors.green.withValues(alpha: 0.55)
                        : score < 0
                            ? Colors.red.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        ),
      );
    }).toList();
  }

  List<Widget> _totalCells(
      BuildContext context, Map<String, int> totals) {
    return widget.game.players.map((player) {
      final isCurrent = player.id == widget.game.currentPlayer.id;
      final isEliminated = player.isEliminated;
      final score = totals[player.id] ?? 0;

      Color scoreColor;
      if (isEliminated) {
        scoreColor = Colors.white.withValues(alpha: 0.15);
      } else if (score > 0) {
        scoreColor = AppTheme.feltGreen;
      } else if (score < 0) {
        scoreColor = Colors.redAccent;
      } else {
        scoreColor = Colors.white.withValues(alpha: 0.4);
      }

      return GestureDetector(
        onTap: widget.onPlayerTap != null
            ? () => widget.onPlayerTap!(player.id)
            : null,
        onLongPress: widget.onPlayerLongPress != null
            ? () => widget.onPlayerLongPress!(player.id, score)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.feltGreen.withValues(alpha: 0.08)
                : null,
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: scoreColor,
                shadows: score != 0
                    ? [
                        Shadow(
                          color: scoreColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Animated wager-confirmed checkbox shown in the scoreboard header when
/// wagerPerPlayer > 0.
class _WagerTick extends StatelessWidget {
  final bool confirmed;
  const _WagerTick({required this.confirmed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        gradient: confirmed ? AppTheme.feltGradient : null,
        color: confirmed ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: confirmed
              ? AppTheme.feltGreen
              : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: confirmed
            ? [
                BoxShadow(
                  color: AppTheme.feltGreen.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: confirmed
          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
          : null,
    );
  }
}

/// Compact rank indicator.
class _RankDot extends StatelessWidget {
  final int rank;
  final bool isEliminated;

  const _RankDot({required this.rank, required this.isEliminated});

  @override
  Widget build(BuildContext context) {
    if (isEliminated) {
      return Icon(
        Icons.remove_circle_outline,
        size: 14,
        color: Colors.red.withValues(alpha: 0.4),
      );
    }

    Color color;
    IconData? icon;
    switch (rank) {
      case 1:
        color = AppTheme.accentGold;
        icon = Icons.emoji_events_rounded;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.emoji_events_rounded;
      case 3:
        color = const Color(0xFFCD7F32);
        icon = Icons.emoji_events_rounded;
      default:
        color = Colors.white.withValues(alpha: 0.3);
        icon = null;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 12, color: color)
            : Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
      ),
    );
  }
}
