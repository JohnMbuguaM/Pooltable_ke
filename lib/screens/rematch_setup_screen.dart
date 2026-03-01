import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../providers/game_provider.dart';
import '../providers/prize_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class RematchSetupScreen extends StatefulWidget {
  final Game previousGame;

  const RematchSetupScreen({super.key, required this.previousGame});

  @override
  State<RematchSetupScreen> createState() => _RematchSetupScreenState();
}

class _RematchSetupScreenState extends State<RematchSetupScreen> {
  // Players from previous game sorted ascending by score (lowest first)
  late List<_RematchPlayer> _players;
  final List<TextEditingController> _newPlayerControllers = [];
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _wagerController;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    // Sort by score ascending: lowest scorer starts, winner plays last
    final sorted = List<Player>.from(widget.previousGame.players)
      ..sort((a, b) => a.score.compareTo(b.score));

    _players = sorted
        .map((p) => _RematchPlayer(
              name: p.name,
              previousScore: p.score,
              included: true,
            ))
        .toList();

    // Initialise wager field from the active prize session (if any).
    final prizeSession = context.read<PrizeProvider>().session;
    _hasSession = prizeSession != null;
    final currentWager = prizeSession?.config.wagerPerPlayer ?? 0.0;
    _wagerController = TextEditingController(
      text: currentWager > 0 ? currentWager.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    for (final c in _newPlayerControllers) {
      c.dispose();
    }
    _wagerController.dispose();
    super.dispose();
  }

  void _addNewPlayer() {
    final totalPlayers = _includedCount + _newPlayerControllers.length;
    if (totalPlayers >= AppConstants.maxPlayers) return;
    setState(() {
      _newPlayerControllers.add(TextEditingController());
    });
  }

  void _removeNewPlayer(int index) {
    setState(() {
      _newPlayerControllers[index].dispose();
      _newPlayerControllers.removeAt(index);
    });
  }

  int get _includedCount => _players.where((p) => p.included).length;

  int get _totalPlayers => _includedCount + _newPlayerControllers.length;

  bool get _canStart => _totalPlayers >= AppConstants.minPlayers;

  Future<void> _startRematch() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canStart) return;

    // Build player list: new players first, then returning players (ascending score order)
    final names = <String>[];

    // New players go first in the queue
    for (final c in _newPlayerControllers) {
      final name = c.text.trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    // Returning players in ascending score order (already sorted)
    for (final p in _players) {
      if (p.included) {
        names.add(p.name);
      }
    }

    final provider = context.read<GameProvider>();
    await provider.createGame(names);

    // Continue the prize session with the new player list (and optional new wager).
    if (mounted) {
      double? newWager;
      if (_hasSession) {
        final parsed = double.tryParse(_wagerController.text.trim());
        if (parsed != null) newWager = parsed;
      }
      context.read<PrizeProvider>().continueSession(names, newWagerPerPlayer: newWager);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rematch'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.feltGreen.withValues(alpha: 0.15),
                    AppTheme.darkGreen.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.feltGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.replay_rounded,
                      size: 36, color: AppTheme.feltGreen),
                  const SizedBox(height: 6),
                  const Text(
                    'New Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lowest scorer starts, winner plays last',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Wager field (only shown when an active prize session exists) ──
            if (_hasSession) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.monetization_on_rounded,
                            size: 15, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          'Wager Per Player (KSH)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _wagerController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: '0 = no wager',
                        isDense: true,
                        prefixText: 'KSH ',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),

            // New players section
            if (_newPlayerControllers.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.person_add_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  const Text(
                    'New Players (play first)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_newPlayerControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.feltGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.fiber_new_rounded,
                              size: 18, color: AppTheme.feltGreen),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _newPlayerControllers[index],
                          decoration: InputDecoration(
                            hintText: 'New player name',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeNewPlayer(index),
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.red.withValues(alpha: 0.6)),
                        iconSize: 22,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Returning players section
            Row(
              children: [
                Icon(Icons.people_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Returning Players ($_includedCount)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'Prev. score',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Player list sorted by previous score ascending
            ...List.generate(_players.length, (index) {
              final p = _players[index];
              return _ReturningPlayerTile(
                player: p,
                playOrder: index + 1 + _newPlayerControllers.length,
                onToggle: () {
                  setState(() {
                    p.included = !p.included;
                  });
                },
              );
            }),
            const SizedBox(height: 12),

            // Add player button
            if (_totalPlayers < AppConstants.maxPlayers)
              OutlinedButton.icon(
                onPressed: _addNewPlayer,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text('Add New Player'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 24),

            // Player count / validation info
            if (!_canStart)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Need at least ${AppConstants.minPlayers} players to start',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),

            // Start button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canStart ? _startRematch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.feltGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Start Rematch ($_totalPlayers players)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RematchPlayer {
  final String name;
  final int previousScore;
  bool included;

  _RematchPlayer({
    required this.name,
    required this.previousScore,
    required this.included,
  });
}

class _ReturningPlayerTile extends StatelessWidget {
  final _RematchPlayer player;
  final int playOrder;
  final VoidCallback onToggle;

  const _ReturningPlayerTile({
    required this.player,
    required this.playOrder,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Helpers.getPlayerInitials(player.name);
    final isPositive = player.previousScore > 0;
    final isNegative = player.previousScore < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: player.included
                ? Theme.of(context).cardTheme.color
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: player.included
                  ? AppTheme.feltGreen.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: player.included
                      ? AppTheme.feltGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: player.included
                        ? AppTheme.feltGreen
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: player.included
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),

              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: player.included
                      ? _avatarColor(player.name).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: player.included
                          ? _avatarColor(player.name)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name + play order
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: player.included
                            ? null
                            : Colors.white.withValues(alpha: 0.4),
                        decoration:
                            player.included ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    if (player.included)
                      Text(
                        'Plays ${Helpers.getOrdinal(playOrder)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),

              // Previous score
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : isNegative
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${player.previousScore}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPositive
                        ? Colors.green
                        : isNegative
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFFFF6584),
      Color(0xFF43E97B),
      Color(0xFFFA8BFF),
      Color(0xFFFFA751),
      Color(0xFF00C9FF),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
