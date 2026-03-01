import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_rules.dart';
import '../providers/rules_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/ball_painter.dart';

class RulesEditorScreen extends StatelessWidget {
  const RulesEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Game Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: Consumer<RulesProvider>(
        builder: (context, rulesProvider, _) {
          if (!rulesProvider.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = rulesProvider.rules;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Starting Ball Section
              _buildSection(
                context,
                'Ball Sequence',
                Icons.format_list_numbered_rounded,
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Ball',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Ball selector
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AppConstants.allBalls.map((ball) {
                            final isSelected = rules.startingBall == ball;
                            return GestureDetector(
                              onTap: () => rulesProvider.updateStartingBall(ball),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: AppTheme.feltGreen, width: 3)
                                      : null,
                                ),
                                child: BallWidget(
                                  ballNumber: ball,
                                  size: isSelected ? 34 : 36,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        // Sequence preview
                        Text(
                          'Play Order',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: rules.ballSequence.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final ball = entry.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BallWidget(ballNumber: ball, size: 28),
                                  if (idx < 14)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ball Values Section
              _buildSection(
                context,
                'Ball Point Values',
                Icons.sports_bar_rounded,
                AppConstants.allBalls.map((ball) {
                  return _buildBallValueEditor(
                    context,
                    ball,
                    rules.getBallValue(ball),
                    (newValue) => rulesProvider.updateBallValue(ball, newValue),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Penalties Section
              _buildSection(
                context,
                'Foul Penalties',
                Icons.warning_amber_rounded,
                [
                  _buildPenaltyInfo(
                    context,
                    'Wrong Ball Contact',
                    Icons.error_outline,
                    'Contact ball\'s points',
                  ),
                  _buildPenaltyInfo(
                    context,
                    'Scratch (Cue Ball)',
                    Icons.cancel,
                    'Ball being played\'s points',
                  ),
                  _buildPenaltyInfo(
                    context,
                    'Carry Ball',
                    Icons.swipe,
                    'Ball being played\'s points',
                  ),
                  _buildPenaltyInfo(
                    context,
                    'Ball Touched',
                    Icons.touch_app,
                    'Ball being touched\'s points',
                  ),
                  _buildBallJumpOffEditor(
                    context,
                    rules.ballJumpOffMode,
                    (mode) => rulesProvider.updateBallJumpOffMode(mode),
                  ),
                  _buildPenaltyInfo(
                    context,
                    'Cue Ball Jumped Off',
                    Icons.call_made_rounded,
                    'Ball being played\'s points',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Info
              Center(
                child: Text(
                  'Changes are saved automatically',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBallValueEditor(
    BuildContext context,
    int ballNumber,
    int currentValue,
    Function(int) onChanged,
  ) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(AppConstants.ballColors[ballNumber] ?? 0xFF000000)
              .withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(AppConstants.ballColors[ballNumber] ?? 0xFF000000)
                .withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$ballNumber',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: Text(
        'Ball $ballNumber',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: SizedBox(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: currentValue > 1
                  ? () => onChanged(currentValue - 1)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              '$currentValue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: currentValue < 50
                  ? () => onChanged(currentValue + 1)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
      onTap: () => _showValueDialog(
        context,
        'Ball $ballNumber Points',
        currentValue,
        onChanged,
      ),
    );
  }

  /// Read-only row describing how a foul penalty is calculated.
  Widget _buildPenaltyInfo(
    BuildContext context,
    String label,
    IconData icon,
    String description,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.red.withValues(alpha: 0.7)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '− $description',
        style: TextStyle(
          fontSize: 11,
          color: Colors.red.shade300,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Editable row for Ball Jump Off mode (deduct / neutral / add).
  Widget _buildBallJumpOffEditor(
    BuildContext context,
    BallJumpOffMode currentMode,
    Function(BallJumpOffMode) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.call_made, size: 20,
              color: Colors.red.withValues(alpha: 0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ball Jumped Off',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<BallJumpOffMode>(
                  initialValue: currentMode,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: BallJumpOffMode.deduct,
                      child: Text('− Deduct jumped ball\'s points',
                          style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: BallJumpOffMode.neutral,
                      child: Text('  Neutral — no score change',
                          style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: BallJumpOffMode.add,
                      child: Text('+ Add jumped ball\'s points',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) onChanged(mode);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showValueDialog(
    BuildContext context,
    String title,
    int currentValue,
    Function(int) onChanged,
  ) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Points',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final newValue = int.tryParse(value);
            if (newValue != null && newValue >= 0 && newValue <= 50) {
              onChanged(newValue);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null && newValue >= 0 && newValue <= 50) {
                onChanged(newValue);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid value (0-50)')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.feltGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all ball values and penalties to the standard pool scoring rules. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RulesProvider>().resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rules reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
