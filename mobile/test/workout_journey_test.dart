import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/workouts/screens/live_workout_screen.dart';
import 'package:raize_mobile/features/workouts/widgets/exercise_hero_card.dart';
import 'package:raize_mobile/features/workouts/widgets/exercise_video_demo_sheet.dart';
import 'package:raize_mobile/features/workouts/widgets/set_logging_table.dart';
import 'package:raize_mobile/features/workouts/widgets/rest_timer_hud.dart';
import 'package:raize_mobile/features/workouts/widgets/volume_tonnage_footer.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Screen 04: Live Workout Execution Tracker Tests', () {
    testWidgets('1. LiveWorkoutScreen renders session title, timer, and current exercise', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      expect(find.text('Push Hypertrophy A'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);

      expect(find.byType(ExerciseHeroCard), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNWidgets(2));
      expect(find.text('4 Sets • 8-10 Reps • RPE 8'), findsOneWidget);
      expect(find.textContaining('CHEST • BARBELL'), findsOneWidget);
    });

    testWidgets('2. SetLoggingTable renders set rows and logs completed set with volume calculation', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      expect(find.byType(SetLoggingTable), findsOneWidget);
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('PREVIOUS'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);

      final checkmarkIcons = find.byIcon(Icons.check_rounded);
      expect(checkmarkIcons, findsNWidgets(4));

      // Scroll to ensure checkmark is in view above footer
      await tester.scrollUntilVisible(
        checkmarkIcons.at(1),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      // Tap checkmark on Set 2 (82.5 kg x 10 = 825 kg volume, PR weight > 80kg)
      await tester.tap(checkmarkIcons.at(1));
      await tester.pump();

      // Verify PR badge
      expect(find.textContaining('New 1RM'), findsOneWidget);

      // Verify Rest Timer HUD
      expect(find.byType(RestTimerHud), findsOneWidget);
      expect(find.text('REST INTERVAL'), findsOneWidget);
      expect(find.text('+30s'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Verify Volume Tonnage Footer
      expect(find.byType(VolumeTonnageFooter), findsOneWidget);
      expect(find.text('825 kg'), findsOneWidget);
      expect(find.text('(1/14 sets)'), findsOneWidget);

      // Clean up timer by tapping Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
    });

    testWidgets('3. RestTimerHud handles skip and extends time by 30 seconds', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      // Complete Set 1
      final checkmarks = find.byIcon(Icons.check_rounded);
      await tester.scrollUntilVisible(
        checkmarks.at(0),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(checkmarks.at(0));
      await tester.pump();

      expect(find.byType(RestTimerHud), findsOneWidget);

      // Tap +30s
      await tester.tap(find.text('+30s'));
      await tester.pump();

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(find.byType(RestTimerHud), findsNothing);
    });

    testWidgets('4. Next Exercise navigates to Incline Dumbbell Press', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      expect(find.text('Next Exercise'), findsOneWidget);
      await tester.tap(find.text('Next Exercise'));
      await tester.pump();

      expect(find.text('Incline Dumbbell Press'), findsNWidgets(2));
      expect(find.text('3 Sets • 10-12 Reps • RPE 8'), findsOneWidget);
    });

    testWidgets('5. Tapping video demonstration button opens ExerciseVideoDemoSheet with kinematics and form cues', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      // Find video demonstration button on hero card
      final demoBtn = find.byKey(const Key('hero_video_demo_action'));
      expect(demoBtn, findsOneWidget);
      expect(find.text('WATCH VIDEO DEMONSTRATION'), findsOneWidget);

      await tester.tap(demoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify ExerciseVideoDemoSheet is displayed
      expect(find.byType(ExerciseVideoDemoSheet), findsOneWidget);
      expect(find.text('4K KINEMATIC DEMONSTRATION'), findsOneWidget);
      expect(find.text('AI FORM VETTED'), findsOneWidget);
      expect(find.text('BIOMECHANICS'), findsOneWidget);
      expect(find.text('FORM CUES'), findsOneWidget);
      expect(find.text('RED FLAGS'), findsOneWidget);

      // Dismiss video demonstration modal
      final closeBtn = find.byKey(const Key('close_video_demo_button'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExerciseVideoDemoSheet), findsNothing);
    });

    testWidgets('6. AppBar video demonstration button opens demo sheet and switches tabs', (tester) async {
      await tester.pumpWidget(createTestWidget(const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false)));
      await tester.pump();

      final appBarDemoBtn = find.byKey(const Key('appbar_video_demo_button'));
      expect(appBarDemoBtn, findsOneWidget);

      await tester.tap(appBarDemoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExerciseVideoDemoSheet), findsOneWidget);

      // Tap on FORM CUES tab
      await tester.tap(find.text('FORM CUES'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STEP-BY-STEP EXECUTION PROTOCOL'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExerciseVideoDemoSheet),
          matching: find.textContaining('Retract scapulae'),
        ),
        findsOneWidget,
      );

      // Tap on RED FLAGS tab
      await tester.tap(find.text('RED FLAGS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CRITICAL FORM PITFALLS & RED FLAGS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExerciseVideoDemoSheet),
          matching: find.textContaining('Flaring elbows'),
        ),
        findsOneWidget,
      );

      // Dismiss
      await tester.tap(find.byKey(const Key('close_video_demo_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExerciseVideoDemoSheet), findsNothing);
    });
  });
}
