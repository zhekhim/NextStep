import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/navigation/main_navigation_screen.dart';

void main() {
  testWidgets('main navigation switches between all five sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainNavigationScreen()),
    );

    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('Careers'));
    await tester.pumpAndSettle();
    expect(find.text('Careers'), findsWidgets);

    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Learning'), findsWidgets);

    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
  });
}
