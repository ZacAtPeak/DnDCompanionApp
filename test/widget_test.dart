import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dndappcompanion/main.dart';

void main() {
  testWidgets('App displays top bar with settings, search, and dice', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.casino), findsNWidgets(2));
  });

  testWidgets('App displays tab bar with 4 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Dice'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
  });

  testWidgets('Tapping tab switches content', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Home Tab'), findsOneWidget);

    await tester.tap(find.text('Dice'));
    await tester.pumpAndSettle();

    expect(find.text('Dice Tab'), findsOneWidget);
  });
}
