import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/game.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/widgets/ball_tracker.dart';
import 'package:pooltable_ke/widgets/ball_painter.dart';
import 'package:pooltable_ke/utils/constants.dart';
import 'package:pooltable_ke/utils/theme.dart';

void main() {
  Widget makeTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  Game makeGame({
    List<int>? remainingBalls,
    List<int>? pocketedBalls,
    int currentBallSequenceIndex = 0,
  }) {
    return Game(
      id: 'g1',
      players: [
        Player(id: 'p1', name: 'Alice'),
        Player(id: 'p2', name: 'Bob'),
      ],
      remainingBalls: remainingBalls,
      pocketedBalls: pocketedBalls,
      currentBallSequenceIndex: currentBallSequenceIndex,
    );
  }

  group('BallTracker', () {
    testWidgets('shows Ball Tracker heading', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.text('Ball Tracker'), findsOneWidget);
    });

    testWidgets('renders all 15 balls at game start', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.byType(BallWidget), findsNWidgets(15));
    });

    testWidgets('displays current target ball number', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.text('Target: 3'), findsOneWidget);
    });

    testWidgets('shows correct remaining count at start', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      // '15' appears as both a ball number and stat - check Remaining label exists
      expect(find.text('Remaining'), findsOneWidget);
      // Ball 15 exists + stat "15" = findsNWidgets(2)
      expect(find.text('15'), findsNWidgets(2));
    });

    testWidgets('shows correct pocketed count at start', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.text('Pocketed'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // 0 pocketed
    });

    testWidgets('shows updated target after balls pocketed', (tester) async {
      final game = makeGame(
        remainingBalls: [7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2],
        pocketedBalls: [3, 4, 5, 6],
        currentBallSequenceIndex: 4, // Points to ball 7
      );

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.text('Target: 7'), findsOneWidget);
    });

    testWidgets('shows Game Over when no balls remain', (tester) async {
      final game = makeGame(
        remainingBalls: [],
        pocketedBalls: AppConstants.allBalls,
      );

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      expect(find.text('Game Over'), findsOneWidget);
    });

    testWidgets('shows remaining balls value as Points Left', (tester) async {
      final game = makeGame();

      await tester.pumpWidget(makeTestable(BallTracker(game: game)));

      // Total ball points = 156
      expect(find.text('${AppConstants.totalBallPoints}'), findsOneWidget);
    });

    testWidgets('onBallTap callback fires for remaining ball', (tester) async {
      int? tappedBall;
      final game = makeGame();

      await tester.pumpWidget(makeTestable(
        BallTracker(
          game: game,
          onBallTap: (ball) => tappedBall = ball,
        ),
      ));

      // Tap ball 5
      await tester.tap(find.text('5'));
      expect(tappedBall, 5);
    });
  });
}
