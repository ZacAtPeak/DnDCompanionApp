import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dndappcompanion/main.dart';

void main() {
  testWidgets('App displays persistent top strip', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('D&D Companion'), findsOneWidget);
  });

  testWidgets('App displays tab bar with 5 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Dice'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Tapping tab switches content', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Home Tab'), findsOneWidget);

    await tester.tap(find.text('Dice'));
    await tester.pumpAndSettle();

    expect(find.text('Dice Tab'), findsOneWidget);
  });
}
