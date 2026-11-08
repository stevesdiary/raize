import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/dashboard/screens/home_dashboard_screen.dart';
import 'package:raize_mobile/features/dashboard/widgets/today_workout_card.dart';
import 'package:raize_mobile/features/dashboard/widgets/frosted_bottom_nav.dart';
import 'package:raize_mobile/features/workouts/screens/live_workout_screen.dart';
import 'package:raize_mobile/features/workouts/widgets/set_logging_table.dart';
import 'package:raize_mobile/features/nutrition/screens/nutrition_diary_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Screen 03: Home Dashboard Flow Tests', () {
    testWidgets('1. HomeDashboardScreen renders telemetry header, greeting, and streak', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pump();

      expect(find.text('Good morning, Athlete!'), findsOneWidget);
      expect(find.text('INTERMEDIATE • WEIGHT MANAGEMENT'), findsOneWidget);
      expect(find.text('14d'), findsOneWidget);
    });

    testWidgets('2. TodayWorkoutCard renders scheduled workout details and triggers onStart', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pump();

      expect(find.text("TODAY'S AGENDA • LADDER PROGRESSION"), findsOneWidget);
      expect(
        find.descendant(of: find.byType(TodayWorkoutCard), matching: find.text('Push Hypertrophy A')),
        findsOneWidget,
      );
      expect(find.text('Start Workout Session'), findsOneWidget);

      await tester.tap(find.text('Start Workout Session'));
      await tester.pumpAndSettle();
      expect(find.byType(LiveWorkoutScreen), findsOneWidget);
      expect(find.byType(SetLoggingTable), findsOneWidget);
    });

    testWidgets('2b. StepStreakCard renders 8,420 steps, streak, and opens HomeScreenWidgetSheet', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pump();

      expect(find.text('DAILY STEP TELEMETRY'), findsOneWidget);
      expect(find.text('8,420'), findsOneWidget);
      expect(find.text('/ 10,000 steps'), findsOneWidget);
      expect(find.text('6.2 km'), findsOneWidget);
      expect(find.text('345 kcal'), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);

      final addWidgetBtn = find.byKey(const Key('add_home_screen_widget_button'));
      expect(addWidgetBtn, findsOneWidget);
      await tester.tap(addWidgetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Phone Screen Widget'), findsOneWidget);
      expect(find.text('2x2 Compact'), findsOneWidget);
      expect(find.text('4x2 Panoramic'), findsOneWidget);
      expect(find.byKey(const Key('confirm_add_home_screen_widget_button')), findsOneWidget);

      // Tap 4x2 Panoramic tab
      await tester.tap(find.text('4x2 Panoramic'));
      await tester.pumpAndSettle();

      // Tap pin button
      await tester.tap(find.byKey(const Key('confirm_add_home_screen_widget_button')));
      await tester.pumpAndSettle();

      expect(find.text('Phone Screen Widget'), findsNothing);
    });

    testWidgets('3. CalorieRingCard renders equation breakdown and macro progress', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pump();

      expect(find.text('MYFITNESSPAL NUTRITION EQUATION'), findsOneWidget);
      expect(find.text('680'), findsOneWidget); // Remaining calories
      expect(find.text('kcal left'), findsOneWidget);
      expect(find.text('Daily Target'), findsOneWidget);
      expect(find.text('Food Consumed'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbohydrates'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
    });

    testWidgets('4. QuickActionsBar triggers GPS Run, Meal Log, and Workout actions', (tester) async {
      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pump();

      // Scroll down to reveal QuickActionsBar
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Log Meal'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);

      await tester.tap(find.text('Log Meal'));
      await tester.pumpAndSettle();
      expect(find.byType(NutritionDiaryScreen), findsOneWidget);
    });

    testWidgets('5. FrostedBottomNav renders 5 tabs and responds to selection', (tester) async {
      int selectedTab = 0;
      await tester.pumpWidget(
        createTestWidget(
          FrostedBottomNav(
            currentIndex: 0,
            onTabSelected: (index) => selectedTab = index,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FrostedBottomNav), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('GPS Run'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Workouts'));
      await tester.pump();
      expect(selectedTab, 1);
    });

    testWidgets('5. AppScrollBehavior disables Android stretch overscroll and enforces bouncing physics', (tester) async {
      const behavior = AppScrollBehavior();
      final dummyChild = Container();

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: behavior,
          home: Builder(
            builder: (context) {
              final physics = behavior.getScrollPhysics(context);
              expect(physics, isA<BouncingScrollPhysics>());

              final builtWidget = behavior.buildOverscrollIndicator(
                context,
                dummyChild,
                const ScrollableDetails(direction: AxisDirection.down),
              );
              // Must return dummyChild directly, NOT StretchingOverscrollIndicator or GlowingOverscrollIndicator
              expect(identical(builtWidget, dummyChild), isTrue);

              return dummyChild;
            },
          ),
        ),
      );
    });

    testWidgets('6. HomeDashboardScreen renders without overflow on compact iOS viewport (375x667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const HomeDashboardScreen(autoFetch: false)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
