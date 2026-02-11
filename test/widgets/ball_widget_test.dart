import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/widgets/ball_painter.dart';

void main() {
  Widget makeTestable(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('BallWidget', () {
    testWidgets('displays ball number', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 8),
      ));

      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('displays ball number for each ball 1-15', (tester) async {
      for (int i = 1; i <= 15; i++) {
        await tester.pumpWidget(makeTestable(
          BallWidget(ballNumber: i),
        ));
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 5),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 5, size: 60),
      ));

      expect(find.byType(BallWidget), findsOneWidget);
    });

    testWidgets('isPocketed reduces opacity', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 3, isPocketed: true),
      ));

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.25);
    });

    testWidgets('non-pocketed ball has full opacity', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 3, isPocketed: false),
      ));

      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('isTarget shows amber border', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 7, isTarget: true),
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('onTap callback fires when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(makeTestable(
        BallWidget(ballNumber: 5, onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(BallWidget));
      expect(tapped, true);
    });

    testWidgets('onTap is null by default', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 5),
      ));

      // Should not throw when tapped without callback
      await tester.tap(find.byType(GestureDetector));
    });

    testWidgets('solid ball uses RadialGradient', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 3), // Solid (1-8)
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<RadialGradient>());
    });

    testWidgets('striped ball uses LinearGradient', (tester) async {
      await tester.pumpWidget(makeTestable(
        const BallWidget(ballNumber: 12), // Striped (9-15)
      ));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });
  });

  group('CueBallWidget', () {
    testWidgets('renders successfully', (tester) async {
      await tester.pumpWidget(makeTestable(
        const CueBallWidget(),
      ));

      expect(find.byType(CueBallWidget), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(makeTestable(
        const CueBallWidget(size: 50),
      ));

      expect(find.byType(CueBallWidget), findsOneWidget);
    });

    testWidgets('uses white/grey gradient', (tester) async {
      await tester.pumpWidget(makeTestable(
        const CueBallWidget(),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CueBallWidget),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<RadialGradient>());
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
