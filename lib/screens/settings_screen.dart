import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/rules_provider.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'rules_editor_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = SoundService.instance.isEnabled;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info section
          _buildSection(
            context,
            'App Info',
            Icons.info_outline_rounded,
            [
              _buildInfoTile(
                context,
                'Version',
                AppConstants.appVersion,
                Icons.tag_rounded,
              ),
              _buildInfoTile(
                context,
                'App Name',
                AppConstants.appName,
                Icons.sports_esports_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Appearance section
          _buildSection(
            context,
            'Appearance',
            Icons.palette_outlined,
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeProvider.isDark ? 'Dark theme active' : 'Light theme active',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: AppTheme.feltGreen,
                secondary: Icon(
                  themeProvider.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Game Sounds'),
                subtitle: Text(
                  _soundEnabled
                      ? 'Sound effects active'
                      : 'Sound effects muted',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                  SoundService.instance.setEnabled(value);
                },
                activeTrackColor: AppTheme.feltGreen,
                secondary: Icon(
                  _soundEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: _soundEnabled
                      ? AppTheme.feltGreen
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Game Rules section
          _buildSection(
            context,
            'Game Rules',
            Icons.rule_rounded,
            [
              Consumer<RulesProvider>(
                builder: (context, rulesProvider, _) {
                  if (!rulesProvider.isLoaded) {
                    return const ListTile(
                      dense: true,
                      title: Text('Loading rules...'),
                    );
                  }

                  final rules = rulesProvider.rules;
                  return Column(
                    children: [
                      _buildInfoTile(
                        context,
                        'Starting Ball',
                        'Ball ${rules.startingBall}',
                        Icons.format_list_numbered_rounded,
                      ),
                      _buildInfoTile(
                        context,
                        'Total Points',
                        '${rules.totalBallPoints} points available',
                        Icons.monetization_on_outlined,
                      ),
                      _buildInfoTile(
                        context,
                        'Standard Penalty',
                        '${rules.wrongBallPenalty} points per foul',
                        Icons.warning_amber_rounded,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: AppTheme.accentGold,
                        ),
                        title: const Text(
                          'Edit Rules',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Customize ball values and penalties',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RulesEditorScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Point values reference
          _buildSection(
            context,
            'Ball Point Values',
            Icons.sports_bar_rounded,
            [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.ballSequence.map((ball) {
                    final value = AppConstants.getBallValue(ball);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(AppConstants.ballColors[ball] ?? 0xFF000000)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(
                                  AppConstants.ballColors[ball] ?? 0xFF000000)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Ball $ball = $value pts',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legal section
          _buildSection(
            context,
            'Legal',
            Icons.gavel_rounded,
            [
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.privacy_tip_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Credits
          Center(
            child: Column(
              children: [
                Text(
                  'Pool Table KE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pool Scoring Application',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, IconData icon, List<Widget> children) {
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
                Icon(icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary),
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

  Widget _buildInfoTile(
      BuildContext context, String title, String value, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.4)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
