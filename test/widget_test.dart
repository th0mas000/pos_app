// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/main.dart';

void main() {
  testWidgets('POS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PosApp());

    // Verify that our main screen loads
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('สินค้า'), findsOneWidget);
    expect(find.text('ลูกค้า'), findsOneWidget);
  });
}
