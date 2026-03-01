import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/game_provider.dart';
import 'providers/prize_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/rules_provider.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/firebase_service.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Future.wait([
    FirebaseService.initialize(),
    SoundService.instance.loadPreference(),
  ]);

  // Route all Flutter framework errors to Crashlytics in release builds.
  if (FirebaseService.isInitialized && !kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Also catch async/platform errors that Flutter doesn't catch.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ChalkManApp());
}

class ChalkManApp extends StatelessWidget {
  const ChalkManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RulesProvider()..loadRules()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => PrizeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ChalkMan',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashWrapper(),
          );
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  static const _kOnboardingKey = 'onboarding_complete';

  // Tracks which screen to show: 'splash' | 'onboarding' | 'home'
  String _screen = 'splash';

  Future<void> _onSplashComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_kOnboardingKey) ?? false;
    if (mounted) {
      setState(() => _screen = done ? 'home' : 'onboarding');
    }
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (mounted) {
      setState(() => _screen = 'home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_screen) {
      'onboarding' => OnboardingScreen(onComplete: _onOnboardingComplete),
      'home'       => const HomeScreen(),
      _            => SplashScreen(onComplete: _onSplashComplete),
    };
  }
}
