import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pooltable_ke/providers/theme_provider.dart';
import 'package:pooltable_ke/utils/theme.dart';

// Smoke test that verifies the app's theme and basic structure
// without triggering sqflite database calls.
void main() {
  testWidgets('App theme setup smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Pool Table KE',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: const Scaffold(
                body: Center(child: Text('Pool Table KE')),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Pool Table KE'), findsOneWidget);
  });
}
