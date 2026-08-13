import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic Material 3 widget renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Home Money'))));
    expect(find.text('Home Money'), findsOneWidget);
  });
}
