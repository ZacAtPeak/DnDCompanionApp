import 'package:flutter_test/flutter_test.dart';

import 'package:dndappcompanion/main.dart';

void main() {
  testWidgets('App displays persistent top strip', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('D&D Companion'), findsOneWidget);
  });

  testWidgets('App displays tab bar with 6 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Abilities/Skills'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Spells'), findsOneWidget);
    expect(find.text('Features'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('Tapping tab switches content', (WidgetTester tester) async {
    await tester.pumpWidget(const DndCompanionApp());

    expect(find.text('Ability Scores'), findsOneWidget);

    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();

    expect(find.text('Actions Tab'), findsOneWidget);
  });
}
