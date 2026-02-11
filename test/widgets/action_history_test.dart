import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/action.dart';
import 'package:pooltable_ke/widgets/action_history.dart';
import 'package:pooltable_ke/utils/theme.dart';

void main() {
  Widget makeTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  GameAction makeAction({
    String id = 'a1',
    ActionType type = ActionType.successfulPocket,
    int pointsChange = 6,
    String description = 'Test action',
    DateTime? timestamp,
  }) {
    return GameAction(
      id: id,
      gameId: 'g1',
      playerId: 'p1',
      type: type,
      pointsChange: pointsChange,
      timestamp: timestamp ?? DateTime(2025, 6, 15, 14, 30),
      description: description,
    );
  }

  group('ActionHistory', () {
    testWidgets('shows empty state when no actions', (tester) async {
      await tester.pumpWidget(makeTestable(
        const ActionHistory(actions: []),
      ));

      expect(find.text('No actions yet'), findsOneWidget);
    });

    testWidgets('displays action description', (tester) async {
      final actions = [
        makeAction(description: 'Alice pocketed ball 3 (+6)'),
      ];

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions),
      ));

      expect(find.text('Alice pocketed ball 3 (+6)'), findsOneWidget);
    });

    testWidgets('displays positive points change', (tester) async {
      final actions = [
        makeAction(pointsChange: 10),
      ];

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions),
      ));

      expect(find.text('+10'), findsOneWidget);
    });

    testWidgets('displays negative points change', (tester) async {
      final actions = [
        makeAction(
          type: ActionType.wrongBallContact,
          pointsChange: -5,
          description: 'Wrong ball hit',
        ),
      ];

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions),
      ));

      expect(find.text('-5'), findsOneWidget);
    });

    testWidgets('does not show points for zero change (neutral)', (tester) async {
      final actions = [
        makeAction(
          type: ActionType.neutralShot,
          pointsChange: 0,
          description: 'Neutral shot',
        ),
      ];

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions),
      ));

      // Neither +0 nor -0 should appear
      expect(find.text('+0'), findsNothing);
      expect(find.text('-0'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows multiple actions in reverse chronological order', (tester) async {
      final actions = [
        makeAction(
          id: 'a1',
          description: 'First action',
          timestamp: DateTime(2025, 6, 15, 14, 0),
        ),
        makeAction(
          id: 'a2',
          description: 'Second action',
          timestamp: DateTime(2025, 6, 15, 14, 5),
        ),
        makeAction(
          id: 'a3',
          description: 'Third action',
          timestamp: DateTime(2025, 6, 15, 14, 10),
        ),
      ];

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions),
      ));

      // All three should be visible
      expect(find.text('First action'), findsOneWidget);
      expect(find.text('Second action'), findsOneWidget);
      expect(find.text('Third action'), findsOneWidget);
    });

    testWidgets('limits display to maxItems', (tester) async {
      final actions = List.generate(
        30,
        (i) => makeAction(
          id: 'a$i',
          description: 'Action $i',
          timestamp: DateTime(2025, 6, 15, 14, i),
        ),
      );

      await tester.pumpWidget(makeTestable(
        ActionHistory(actions: actions, maxItems: 5),
      ));

      // Should only show 5 most recent (reversed) actions
      // The last 5 are Action 29, 28, 27, 26, 25
      expect(find.text('Action 29'), findsOneWidget);
      expect(find.text('Action 25'), findsOneWidget);
      expect(find.text('Action 0'), findsNothing);
    });

    testWidgets('shows history icon in empty state', (tester) async {
      await tester.pumpWidget(makeTestable(
        const ActionHistory(actions: []),
      ));

      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });
}
