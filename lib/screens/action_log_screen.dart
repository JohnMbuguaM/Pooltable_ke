import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/action_history.dart';

class ActionLogScreen extends StatelessWidget {
  final Game game;

  const ActionLogScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Action Log (${game.actions.length})'),
      ),
      body: game.actions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text(
                    'No actions yet',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ActionHistory(
                actions: game.actions,
                players: game.players,
              ),
            ),
    );
  }
}
