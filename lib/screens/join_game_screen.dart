import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/online_game_service.dart';
import '../utils/theme.dart';
import 'game_screen.dart';
import 'qr_scanner_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a game code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final game = await OnlineGameService.joinGameByCode(code);

      if (game == null) {
        setState(() => _errorMessage = 'Game not found');
        return;
      }

      if (!mounted) return;

      // Load game into provider and start real-time listener
      final gameProvider = context.read<GameProvider>();
      await gameProvider.joinOnlineGame(game);

      if (!mounted) return;

      // Navigate to game screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Error joining game: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Game'),
        backgroundColor: AppTheme.feltGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: AppTheme.feltGreen.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Game Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the host for the 6-character code',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'ABC-123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
                errorText: _errorMessage,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 7,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  String text = newValue.text.toUpperCase().replaceAll('-', '');
                  if (text.length > 3) {
                    text = '${text.substring(0, 3)}-${text.substring(3)}';
                  }
                  return TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              onSubmitted: (_) => _joinGame(),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _joinGame,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_isLoading ? 'Joining...' : 'Join Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.feltGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                );
                if (code != null && mounted) {
                  // Format code with hyphen for display
                  final formatted = code.length == 6
                      ? '${code.substring(0, 3)}-${code.substring(3)}'
                      : code;
                  _codeController.text = formatted;
                  _joinGame();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner),
                  const SizedBox(width: 8),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: AppTheme.feltGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
