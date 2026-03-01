import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'Information We Collect',
            Icons.info_outline_rounded,
            'ChalkMan stores all game data (scores, player names, game history) '
            'locally on your device using an on-device database (SQLite) and '
            'device storage (SharedPreferences). No personal information is '
            'collected or transmitted to our servers.',
          ),
          _buildSection(
            context,
            'Anonymous Identifiers',
            Icons.fingerprint_rounded,
            'When you use online game features (hosting or joining a game), '
            'the app uses Firebase Anonymous Authentication to assign a temporary '
            'anonymous identifier. This identifier does not link to your name, '
            'email, or any personal account and is used solely to manage '
            'real-time game sessions.',
          ),
          _buildSection(
            context,
            'Crash Reporting',
            Icons.bug_report_outlined,
            'In release builds, ChalkMan uses Firebase Crashlytics to collect '
            'anonymous crash reports. These reports contain device type, OS '
            'version, and the stack trace of the crash — no personal data, '
            'player names, or game scores are included.',
          ),
          _buildSection(
            context,
            'Online Game Data',
            Icons.cloud_outlined,
            'When you create an online game, basic game state (current scores '
            'and ball positions) is temporarily stored in Firebase Firestore to '
            'allow spectators and other devices to follow the game in real time. '
            'This data is not linked to your identity and is not used for '
            'advertising or sold to third parties.',
          ),
          _buildSection(
            context,
            'Data Retention',
            Icons.storage_rounded,
            'Local game history stays on your device until you delete it. '
            'Online game sessions in Firestore are temporary and are not '
            'permanently retained after the session ends.',
          ),
          _buildSection(
            context,
            'Third-Party Services',
            Icons.link_rounded,
            'ChalkMan uses the following third-party services:\n'
            '• Firebase (Google LLC) — anonymous auth, real-time game sync, '
            'and crash reporting.\n'
            'No advertising SDKs or tracking SDKs are included.',
          ),
          _buildSection(
            context,
            'Children\'s Privacy',
            Icons.child_care_rounded,
            'ChalkMan does not knowingly collect personal information from '
            'children under the age of 13. The app does not require account '
            'creation or any form of personal data entry.',
          ),
          _buildSection(
            context,
            'Contact',
            Icons.email_outlined,
            'If you have questions about this privacy policy, please contact '
            'us at:\n\npooltableke@gmail.com',
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Last updated: March 2026',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.feltGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'ChalkMan is committed to protecting your privacy. '
            'This policy explains how the app handles your data.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, IconData icon, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: AppTheme.feltGreen.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
