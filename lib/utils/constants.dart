class AppConstants {
  AppConstants._();

  static const String appName = 'Pool Table KE';
  static const String appVersion = '1.0.0';

  // Ball sequence: 3,4,5,6,7,8,9,10,11,12,13,14,15,1,2
  static const List<int> ballSequence = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2];

  // All ball numbers
  static const List<int> allBalls = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  // Ball point values
  static const Map<int, int> ballValues = {
    1: 16,
    2: 17,
    3: 6,
    4: 6,
    5: 6,
    6: 6,
    7: 7,
    8: 8,
    9: 9,
    10: 10,
    11: 11,
    12: 12,
    13: 13,
    14: 14,
    15: 15,
  };

  static int getBallValue(int ballNumber) {
    return ballValues[ballNumber] ?? 0;
  }

  // Total points of all balls
  static int get totalBallPoints {
    return ballValues.values.fold(0, (sum, v) => sum + v);
  }

  // Penalty amounts
  static const int wrongBallContactPenalty = 5;
  static const int cueBallScratchPenalty = 5;
  static const int ballTouchedPenalty = 5;
  static const int ballJumpedOffPenalty = 5;
  static const int cueBallJumpedOffPenalty = 5;
  static const int carryBallPenalty = 5;

  // Ball colors for UI
  static const Map<int, int> ballColors = {
    1: 0xFFFFD700,  // Yellow
    2: 0xFF0000FF,  // Blue
    3: 0xFFFF0000,  // Red
    4: 0xFF800080,  // Purple
    5: 0xFFFF8C00,  // Orange
    6: 0xFF006400,  // Green
    7: 0xFF8B0000,  // Maroon
    8: 0xFF000000,  // Black
    9: 0xFFFFD700,  // Yellow stripe
    10: 0xFF0000FF, // Blue stripe
    11: 0xFFFF0000, // Red stripe
    12: 0xFF800080, // Purple stripe
    13: 0xFFFF8C00, // Orange stripe
    14: 0xFF006400, // Green stripe
    15: 0xFF8B0000, // Maroon stripe
  };

  // Balls 9-15 are striped
  static bool isStriped(int ballNumber) => ballNumber >= 9;
  static bool isSolid(int ballNumber) => ballNumber >= 1 && ballNumber <= 8;

  // Database
  static const String dbName = 'pooltable_ke.db';
  static const int dbVersion = 1;

  // Min/Max players
  static const int minPlayers = 2;
  static const int maxPlayers = 20;
}
