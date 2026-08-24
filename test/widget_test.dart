import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/navigation/main_navigation_screen.dart';

void main() {
  testWidgets('main navigation switches between all five sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    expect(find.text('Home'), findsNWidgets(2));

    await tester.tap(find.text('Careers'));
    await tester.pumpAndSettle();
    expect(find.text('Careers'), findsNWidgets(2));

    await tester.tap(find.text('Assessment'));
    await tester.pumpAndSettle();
    expect(find.text('Assessment'), findsNWidgets(2));

    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    expect(find.text('My Career Goal'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNWidgets(2));
  });
}
