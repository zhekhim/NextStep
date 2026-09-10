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

  testWidgets('navigation labels fit on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    final assessmentLabel = tester.widget<Text>(find.text('Assessment').first);
    expect(assessmentLabel.maxLines, 1);
    expect(tester.takeException(), isNull);
  });
}
