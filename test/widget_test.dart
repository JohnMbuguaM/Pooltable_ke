import 'package:flutter_test/flutter_test.dart';
import 'package:pooltable_ke/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PoolTableKEApp());
    expect(find.text('Pool Table KE'), findsOneWidget);
  });
}
