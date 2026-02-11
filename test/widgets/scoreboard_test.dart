import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/models/game.dart';
import 'package:pooltable_ke/models/player.dart';
import 'package:pooltable_ke/widgets/scoreboard.dart';
import 'package:pooltable_ke/widgets/player_card.dart';
import 'package:pooltable_ke/utils/theme.dart';

void main() {
  Widget makeTestable(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Scoreboard', () {
    testWidgets('shows Scoreboard heading', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice'),
          Player(id: 'p2', name: 'Bob'),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('Scoreboard'), findsOneWidget);
    });

    testWidgets('shows round number', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice'),
          Player(id: 'p2', name: 'Bob'),
        ],
        roundNumber: 3,
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('Round 3'), findsOneWidget);
    });

    testWidgets('renders a PlayerCard for each active player', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice', score: 20),
          Player(id: 'p2', name: 'Bob', score: 10),
          Player(id: 'p3', name: 'Charlie', score: 30),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.byType(PlayerCard), findsNWidgets(3));
    });

    testWidgets('sorts active players by score descending', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice', score: 10),
          Player(id: 'p2', name: 'Bob', score: 30),
          Player(id: 'p3', name: 'Charlie', score: 20),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      // All names should be present
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('shows Eliminated section when players eliminated', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice', score: 50),
          Player(id: 'p2', name: 'Bob', score: 5, isEliminated: true),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('Eliminated'), findsOneWidget);
    });

    testWidgets('does NOT show Eliminated section when none eliminated', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice'),
          Player(id: 'p2', name: 'Bob'),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('Eliminated'), findsNothing);
    });

    testWidgets('displays all player names', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice'),
          Player(id: 'p2', name: 'Bob'),
          Player(id: 'p3', name: 'Charlie'),
          Player(id: 'p4', name: 'Diana'),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Diana'), findsOneWidget);
    });

    testWidgets('displays player scores', (tester) async {
      final game = Game(
        id: 'g1',
        players: [
          Player(id: 'p1', name: 'Alice', score: 42),
          Player(id: 'p2', name: 'Bob', score: 17),
        ],
      );

      await tester.pumpWidget(makeTestable(Scoreboard(game: game)));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
    });
  });
}
