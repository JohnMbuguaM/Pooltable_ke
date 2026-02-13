import 'dart:math';

class GameCodeGenerator {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude similar chars (I,1,O,0)
  static final Random _random = Random();

  /// Generate a unique 6-character game code
  /// Format: ABC123 (3 letters + 3 numbers for easy reading)
  static String generate() {
    final letters = List.generate(
      3,
      (_) => _chars[_random.nextInt(23)], // First 23 chars are letters
    );

    final numbers = List.generate(
      3,
      (_) => _chars[23 + _random.nextInt(8)], // Last 8 chars are numbers
    );

    return '${letters.join()}${numbers.join()}';
  }

  /// Validate a game code format
  static bool isValid(String code) {
    if (code.length != 6) return false;

    // First 3 should be letters
    for (int i = 0; i < 3; i++) {
      if (!_chars.substring(0, 23).contains(code[i])) return false;
    }

    // Last 3 should be numbers
    for (int i = 3; i < 6; i++) {
      if (!_chars.substring(23).contains(code[i])) return false;
    }

    return true;
  }

  /// Format code for display (ABC-123)
  static String format(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)}-${code.substring(3)}';
  }

  /// Remove formatting from code
  static String unformat(String formattedCode) {
    return formattedCode.replaceAll('-', '').toUpperCase();
  }
}
