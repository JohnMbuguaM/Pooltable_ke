import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadGameHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        actions: [
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              if (provider.gameHistory.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Export history',
                onPressed: () => _exportHistory(provider.gameHistory),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          final games = provider.gameHistory;

          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'No games yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed games will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HistoryGameCard(
                  game: games[index],
                  onTap: () => _openGame(context, games[index]),
                  onDelete: () =>
                      _confirmDelete(context, provider, games[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openGame(BuildContext context, Game game) async {
    final provider = context.read<GameProvider>();
    await provider.loadGame(game.id);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  void _exportHistory(List<Game> games) {
    final buf = StringBuffer();
    buf.writeln('ChalkMan — Game History');
    buf.writeln('Exported: ${Helpers.formatDateTime(DateTime.now())}');
    buf.writeln('─' * 32);

    for (var i = 0; i < games.length; i++) {
      final g = games[i];
      final status = g.status == GameStatus.completed
          ? 'Completed'
          : g.status == GameStatus.abandoned
              ? 'Abandoned'
              : 'Active';
      buf.writeln('\nGame ${i + 1} — ${Helpers.formatDateTime(g.createdAt)}');
      buf.writeln('Status: $status');
      if (g.completedAt != null) {
        final dur = g.completedAt!.difference(g.createdAt);
        buf.writeln('Duration: ${Helpers.formatDuration(dur)}');
      }
      final sortedPlayers = List.from(g.players)
        ..sort((a, b) => b.score.compareTo(a.score));
      for (final p in sortedPlayers) {
        final tag = p.id == g.winnerId ? ' ★' : '';
        buf.writeln('  ${p.name}: ${p.score} pts$tag');
      }
    }

    Share.share(buf.toString(), subject: 'ChalkMan Game History');
  }

  void _confirmDelete(
      BuildContext context, GameProvider provider, Game game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteGame(game.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _HistoryGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryGameCard({
    required this.game,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = game.status == GameStatus.active;
    final isAbandoned = game.status == GameStatus.abandoned;
    final playerNames = game.players.map((p) => p.name).join(', ');
    final winner = game.winnerId != null
        ? game.players.where((p) => p.id == game.winnerId).firstOrNull
        : null;
    final sortedPlayers = List.from(game.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Dismissible(
      key: Key(game.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.feltGreen.withValues(alpha: 0.1)
                            : isAbandoned
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.play_arrow_rounded
                            : isAbandoned
                                ? Icons.flag_rounded
                                : Icons.emoji_events_rounded,
                        size: 22,
                        color: isActive
                            ? AppTheme.feltGreen
                            : isAbandoned
                                ? Colors.orange
                                : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerNames,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                Helpers.formatDateTime(game.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              if (game.completedAt != null) ...[
                                Text(
                                  ' \u2022 ',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                Text(
                                  Helpers.formatDuration(
                                    game.completedAt!
                                        .difference(game.createdAt),
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.feltGreen.withValues(alpha: 0.15)
                            : isAbandoned
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive
                            ? 'Active'
                            : isAbandoned
                                ? 'Abandoned'
                                : 'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppTheme.feltGreen
                              : isAbandoned
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),

                // Winner info
                if (winner != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 14,
                            color:
                                AppTheme.accentGold.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          '${winner.name} won with ${winner.score} points',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                AppTheme.accentGold.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Player scores
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: sortedPlayers.take(5).map((player) {
                    final isWinner = player.id == game.winnerId;
                    return Text(
                      '${player.name}: ${player.score}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isWinner ? FontWeight.bold : FontWeight.normal,
                        color: isWinner
                            ? AppTheme.accentGold
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
