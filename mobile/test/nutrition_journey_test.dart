import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/features/nutrition/screens/nutrition_diary_screen.dart';

void main() {
  group('Nutrition Diary & Food Log Journey Tests', () {
    testWidgets('1. NutritionDiaryScreen renders header, calorie equation, and macro breakdown',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NutritionDiaryScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand & Mode
      expect(find.text('RAIZE NUTRITION OS'), findsOneWidget);
      expect(find.text('CALORIC DEFICIT MODE'), findsOneWidget);
      expect(find.text('Today, Nov 7'), findsOneWidget);

      // Energy Expenditure
      expect(find.text('ENERGY EXPENDITURE'), findsOneWidget);
      expect(find.text('Mifflin-St Jeor'), findsOneWidget);
      expect(find.text('1420'), findsOneWidget);
      expect(find.text('/ 2045 kcal'), findsOneWidget);
      expect(find.text('69%'), findsOneWidget);
      expect(find.text('625 kcal left'), findsOneWidget);

      // Macro cluster
      expect(find.text('PROTEIN'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('/110g'), findsOneWidget);
      expect(find.text('CARBS'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);
      expect(find.text('/230g'), findsOneWidget);
      expect(find.text('FAT'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('/55g'), findsOneWidget);
    });

    testWidgets('2. Hydration quick-log increments water consumed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NutritionDiaryScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2.2L / 3.0L'), findsOneWidget);
      await tester.tap(find.text('+ 250ml'));
      await tester.pumpAndSettle();

      expect(find.text('2.5L / 3.0L'), findsOneWidget);
    });

    testWidgets('3. Meal schedule renders logged meals and Nigerian portion calibration note',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NutritionDiaryScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meal Schedule'), findsOneWidget);
      expect(find.text('2 OF 4 LOGGED'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Rolled Oats with Greek Yogurt & Honey'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Jollof Rice with Grilled Chicken Breast'), findsOneWidget);
      expect(
        find.text('1.5 plates • Nigerian Standard Portion Calibration'),
        findsOneWidget,
      );
    });

    testWidgets('4. Rapid food logger renders Nigerian staple portions and allows logging',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NutritionDiaryScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to rapid food logger
      await tester.scrollUntilVisible(
        find.text('RAPID FOOD LOGGER'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('RAPID FOOD LOGGER'), findsOneWidget);
      expect(find.text('Nigerian Staples v2.4'), findsOneWidget);
      expect(find.text('Pounded Yam'), findsWidgets);
      expect(find.text('Verified Carbs'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('1.5 Wraps'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Wrap (200g)'), findsOneWidget);
      expect(find.text('1.5 Wraps'), findsOneWidget);
      expect(find.text('1 Derica Raw'), findsOneWidget);

      // Select 1.5 Wraps
      await tester.tap(find.text('1.5 Wraps'));
      await tester.pumpAndSettle();

      // Scroll to Add button
      await tester.scrollUntilVisible(
        find.text('+ Add to Dinner (590 kcal)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap + Add to Dinner
      await tester.tap(find.text('+ Add to Dinner (590 kcal)'));
      await tester.pumpAndSettle();

      expect(find.text('Added to Dinner!'), findsOneWidget);
    });

    testWidgets('5. NutritionDiaryScreen back button pops and returns to previous screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NutritionDiaryScreen(syncBackend: false),
                      ),
                    );
                  },
                  child: const Text('Open Nutrition'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Nutrition'));
      await tester.pumpAndSettle();

      expect(find.byType(NutritionDiaryScreen), findsOneWidget);

      final backBtn = find.byKey(const Key('nutrition_back_button'));
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(NutritionDiaryScreen), findsNothing);
      expect(find.text('Open Nutrition'), findsOneWidget);
    });
  });
}
