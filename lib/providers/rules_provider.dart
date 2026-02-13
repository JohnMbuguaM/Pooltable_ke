import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_rules.dart';

class RulesProvider with ChangeNotifier {
  static const String _rulesKey = 'game_rules';
  GameRules _rules = GameRules.defaults();
  bool _isLoaded = false;

  GameRules get rules => _rules;
  bool get isLoaded => _isLoaded;

  // Load rules from SharedPreferences
  Future<void> loadRules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getString(_rulesKey);

      if (rulesJson != null) {
        final decoded = jsonDecode(rulesJson) as Map<String, dynamic>;
        _rules = GameRules.fromJson(decoded);
      } else {
        _rules = GameRules.defaults();
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rules: $e');
      _rules = GameRules.defaults();
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Save rules to SharedPreferences
  Future<void> saveRules(GameRules newRules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = jsonEncode(newRules.toJson());
      await prefs.setString(_rulesKey, rulesJson);

      _rules = newRules;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving rules: $e');
      rethrow;
    }
  }

  // Update ball value
  Future<void> updateBallValue(int ballNumber, int points) async {
    final newBallValues = Map<int, int>.from(_rules.ballValues);
    newBallValues[ballNumber] = points;

    final newRules = _rules.copyWith(ballValues: newBallValues);
    await saveRules(newRules);
  }

  // Update penalty
  Future<void> updatePenalty(String penaltyType, int points) async {
    GameRules newRules;

    switch (penaltyType) {
      case 'wrongBall':
        newRules = _rules.copyWith(wrongBallPenalty: points);
        break;
      case 'scratch':
        newRules = _rules.copyWith(scratchPenalty: points);
        break;
      case 'carryBall':
        newRules = _rules.copyWith(carryBallPenalty: points);
        break;
      case 'ballTouched':
        newRules = _rules.copyWith(ballTouchedPenalty: points);
        break;
      case 'ballJumpedOff':
        newRules = _rules.copyWith(ballJumpedOffPenalty: points);
        break;
      case 'cueBallJumpedOff':
        newRules = _rules.copyWith(cueBallJumpedOffPenalty: points);
        break;
      default:
        return;
    }

    await saveRules(newRules);
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await saveRules(GameRules.defaults());
  }
}
