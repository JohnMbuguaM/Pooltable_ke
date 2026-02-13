import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class Scoreboard extends StatefulWidget {
  final Game game;
  final Function(String playerId)? onPlayerTap;

  const Scoreboard({super.key, required this.game, this.onPlayerTap});

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
    final theme = Theme.of(context);
    final rowCount = rows.length;
    final hasHistory = rowCount > 0;
    final playerCount = widget.game.players.length;
    const double minCellWidth = 46.0;

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
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              buildCellRow(_headerCells(context, ranks)),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              // Expand/collapse toggle
              if (hasHistory)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _expanded ? 'Hide history' : '$rowCount entries',
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // History rows (only when expanded)
              if (_expanded)
                ...rows.map((row) =>
                    buildCellRow(_historyCells(context, row))),
              // Total row (always shown)
              buildCellRow(_totalCells(context, totals)),
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

      return GestureDetector(
        onTap: widget.onPlayerTap != null
            ? () => widget.onPlayerTap!(player.id)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.feltGreen.withValues(alpha: 0.08)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RankDot(rank: rank, isEliminated: isEliminated),
              const SizedBox(height: 2),
              Text(
                Helpers.getPlayerInitials(player.name),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isEliminated
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.25)
                      : Theme.of(context).colorScheme.onSurface,
                  decoration:
                      isEliminated ? TextDecoration.lineThrough : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              if (isCurrent && !isEliminated)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.feltGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'TURN',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              else if (isEliminated)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'OUT',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              else
                const SizedBox(height: 11),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _historyCells(
      BuildContext context, Map<String, int?> row) {
    final theme = Theme.of(context);
    return widget.game.players.map((player) {
      final isCurrent = player.id == widget.game.currentPlayer.id;
      final score = row[player.id];

      return GestureDetector(
        onTap: widget.onPlayerTap != null
            ? () => widget.onPlayerTap!(player.id)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.feltGreen.withValues(alpha: 0.08)
                : null,
          ),
          child: Center(
            child: score != null
                ? Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.35),
                    ),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _totalCells(
      BuildContext context, Map<String, int> totals) {
    final theme = Theme.of(context);
    return widget.game.players.map((player) {
      final isCurrent = player.id == widget.game.currentPlayer.id;
      final isEliminated = player.isEliminated;
      final score = totals[player.id] ?? 0;

      Color scoreColor;
      if (isEliminated) {
        scoreColor = theme.colorScheme.onSurface.withValues(alpha: 0.2);
      } else if (score > 0) {
        scoreColor = Colors.green;
      } else if (score < 0) {
        scoreColor = Colors.red;
      } else {
        scoreColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);
      }

      return GestureDetector(
        onTap: widget.onPlayerTap != null
            ? () => widget.onPlayerTap!(player.id)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.feltGreen.withValues(alpha: 0.08)
                : null,
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ),
      );
    }).toList();
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
        color = Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.35);
        icon = null;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
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
