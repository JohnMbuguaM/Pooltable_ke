import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/widgets/player_card.dart';
import 'package:pooltable_ke/utils/theme.dart';

void main() {
  Widget makeTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('PlayerCard', () {
    testWidgets('displays player name', (tester) async {
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays player score', (tester) async {
      final player = Player(id: 'p1', name: 'Alice', score: 42);

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays zero score', (tester) async {
      final player = Player(id: 'p1', name: 'Alice', score: 0);

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('displays negative score', (tester) async {
      final player = Player(id: 'p1', name: 'Alice', score: -10);

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('-10'), findsOneWidget);
    });

    testWidgets('shows TURN badge for current player', (tester) async {
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player, isCurrentPlayer: true),
      ));

      expect(find.text('TURN'), findsOneWidget);
    });

    testWidgets('does NOT show TURN badge for non-current player', (tester) async {
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player, isCurrentPlayer: false),
      ));

      expect(find.text('TURN'), findsNothing);
    });

    testWidgets('shows OUT badge for eliminated player', (tester) async {
      final player = Player(id: 'p1', name: 'Alice', isEliminated: true);

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('OUT'), findsOneWidget);
    });

    testWidgets('does NOT show OUT badge for active player', (tester) async {
      final player = Player(id: 'p1', name: 'Alice', isEliminated: false);

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('OUT'), findsNothing);
    });

    testWidgets('shows player initials in avatar', (tester) async {
      final player = Player(id: 'p1', name: 'Alice Wonderland');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player),
      ));

      expect(find.text('AW'), findsOneWidget);
    });

    testWidgets('shows rank when provided', (tester) async {
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player, rank: 1),
      ));

      expect(find.text('1st'), findsOneWidget);
    });

    testWidgets('does NOT show rank when rank is 0', (tester) async {
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player, rank: 0),
      ));

      expect(find.text('0th'), findsNothing);
    });

    testWidgets('onTap callback fires when tapped', (tester) async {
      bool tapped = false;
      final player = Player(id: 'p1', name: 'Alice');

      await tester.pumpWidget(makeTestable(
        PlayerCard(player: player, onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(PlayerCard));
      expect(tapped, true);
    });
  });
}
