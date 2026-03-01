import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;
  static String? _userId;

  static bool get isInitialized => _initialized;
  static String? get currentUserId => _userId;

  /// Initialize Firebase and sign in anonymously
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Sign in anonymously to enable Firestore access
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _userId = userCredential.user?.uid;

      _initialized = true;
      debugPrint('Firebase initialized successfully. User ID: $_userId');
    } catch (e) {
      // Firebase failure must never crash the app — local-only mode continues.
      debugPrint('Firebase initialization failed (offline or misconfigured): $e');
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Get current user ID
  static String getUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  /// Sign out (mainly for testing/debugging)
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _userId = null;
  }
}
