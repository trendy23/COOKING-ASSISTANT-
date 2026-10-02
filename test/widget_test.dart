import 'package:cooking_assistant/virtual_kitchen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cooking flow waits for the user to continue', (tester) async {
    const recipe = KitchenRecipe(
      id: 'test-recipe',
      name: 'Test Soup',
      culture: 'Test',
      minutes: 10,
      isStarter: true,
      color: Colors.green,
      icon: Icons.soup_kitchen,
      steps: [
        KitchenStep('Prepare', 'Chop the vegetables.', Icons.content_cut),
        KitchenStep('Cook', 'Simmer until tender.', Icons.soup_kitchen),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: VirtualKitchenCookingScreen(recipe: recipe)),
    );

    expect(find.text('Chop the vegetables.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Chop the vegetables.'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause cooking'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pause-status')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('next-step')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Resume cooking'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('next-step')));
    await tester.pumpAndSettle();

    expect(find.text('Simmer until tender.'), findsOneWidget);
  });

  testWidgets('recipe with missing steps shows a safe empty state', (
    tester,
  ) async {
    const recipe = KitchenRecipe(
      id: 'empty-recipe',
      name: 'Recipe without saved steps',
      culture: 'Test',
      minutes: 0,
      isStarter: true,
      color: Colors.green,
      icon: Icons.restaurant,
      steps: [],
    );

    await tester.pumpWidget(
      const MaterialApp(home: VirtualKitchenCookingScreen(recipe: recipe)),
    );

    expect(
      find.text('No cooking steps are saved for this recipe yet.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
