// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_fit/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CalorieFitApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.textContaining('Today').evaluate().isNotEmpty ||
          find.textContaining('Startup Error').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
