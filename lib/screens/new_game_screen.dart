import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'game_screen.dart';

class NewGameScreen extends StatefulWidget {
  final bool isOnline;

  const NewGameScreen({super.key, this.isOnline = false});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
    // Start with 2 players
    _addPlayerField();
    _addPlayerField();
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayerField() {
    if (_controllers.length >= AppConstants.maxPlayers) return;
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    if (_controllers.length <= AppConstants.minPlayers) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _startGame() async {
    if (!_formKey.currentState!.validate()) return;

    final names = _controllers.map((c) => c.text.trim()).toList();
    final provider = context.read<GameProvider>();
    await provider.createGame(names);

    // If online game, convert to online before navigating
    if (widget.isOnline) {
      try {
        final onlineGame = await provider.createOnlineGame();
        if (!mounted) return;

        // Show game code before navigating
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Game Created!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share this code with other players:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.feltGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.feltGreen),
                  ),
                  child: Text(
                    onlineGame.gameCode ?? '',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You can also share the QR code from the game screen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.feltGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Playing'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating online game: $e')),
        );
        return;
      }
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
        title: const Text('New Game'),
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOut,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Title section
              Container(
                padding: const EdgeInsets.all(20),
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
                    const Icon(
                      Icons.sports_esports_rounded,
                      size: 40,
                      color: AppTheme.feltGreen,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ChalkMan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add ${AppConstants.minPlayers}+ players to start',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Players section
              Row(
                children: [
                  Icon(Icons.people_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Players (${_controllers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Player input fields
              ...List.generate(_controllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlayerInput(
                    controller: _controllers[index],
                    index: index,
                    canRemove: _controllers.length > AppConstants.minPlayers,
                    onRemove: () => _removePlayerField(index),
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Add player button
              if (_controllers.length < AppConstants.maxPlayers)
                OutlinedButton.icon(
                  onPressed: _addPlayerField,
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Add Player'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

              const SizedBox(height: 32),

              // Start button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.feltGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Start Game',
                        style: TextStyle(
                          fontSize: 18,
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
      ),
    );
  }
}

class _PlayerInput extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  const _PlayerInput({
    required this.controller,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF43E97B),
      const Color(0xFFFA8BFF),
      const Color(0xFFFFA751),
      const Color(0xFF00C9FF),
      const Color(0xFFFF5E62),
      const Color(0xFF20E3B2),
    ];

    return Row(
      children: [
        // Player number badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                avatarColors[index % avatarColors.length].withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: avatarColors[index % avatarColors.length],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Player ${index + 1} name',
              prefixIcon:
                  const Icon(Icons.person_outline_rounded, size: 20),
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
        if (canRemove) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.remove_circle_outline,
                color: Colors.red.withValues(alpha: 0.6)),
            iconSize: 22,
          ),
        ],
      ],
    );
  }
}
