import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/assessment/screens/assessment_screen.dart';
import 'package:raize_mobile/features/assessment/screens/blueprint_screen.dart';
import 'package:raize_mobile/features/assessment/providers/assessment_provider.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('User Journey: Assessment & Blueprint Flow Tests', () {
    testWidgets('1. AssessmentScreen renders Stage A and progresses through options', (tester) async {
      await tester.pumpWidget(createTestWidget(const AssessmentScreen()));
      await tester.pump();

      // Check stage header & verified account banner
      expect(find.text('STAGE A OF 6'), findsOneWidget);
      expect(find.text('VERIFIED ACCOUNT DATA'), findsOneWidget);
      expect(find.textContaining('Auto-linked from registration'), findsOneWidget);

      // Verify date of birth is NOT asked again in the questionnaire
      expect(find.text('What is your date of birth?'), findsNothing);

      // Check biological sex question
      expect(find.text('What is your biological sex?'), findsOneWidget);

      // Select Male option
      await tester.tap(find.text('Male'));
      await tester.pump();

      // Tap Continue to Stage B
      await tester.tap(find.text('Continue to Stage B'));
      await tester.pumpAndSettle();

      // Stage B check (Goals)
      expect(find.text('STAGE B OF 6'), findsOneWidget);
      expect(find.text('What is your primary fitness goal?'), findsOneWidget);
      expect(find.text('Weight Management'), findsOneWidget);
      expect(find.text('Build Muscle'), findsOneWidget);
    });

    testWidgets('2. Stage E Cardiac Circuit Breaker displays safety alert when triggered', (tester) async {
      final container = ProviderContainer();
      // Set to Stage E
      container.read(assessmentProvider.notifier).nextStage(); // B
      container.read(assessmentProvider.notifier).nextStage(); // C
      container.read(assessmentProvider.notifier).nextStage(); // D
      container.read(assessmentProvider.notifier).nextStage(); // E

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AssessmentScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('STAGE E OF 6'), findsOneWidget);
      expect(find.text('SAFETY CIRCUIT BREAKER ACTIVE'), findsNothing);

      // Scroll list up so E05 is clearly visible in center
      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pumpAndSettle();

      final optionFinder = find.text('Yes, I have experienced these');
      await tester.tap(optionFinder);
      await tester.pump();

      // Verify Safety Circuit Breaker Active
      expect(find.text('SAFETY CIRCUIT BREAKER ACTIVE'), findsOneWidget);
      expect(find.textContaining('chest pain, fainting, or dizziness'), findsOneWidget);
    });

    testWidgets('3. BlueprintScreen renders 6-D classification, caloric budget, and 7-day schedule', (tester) async {
      await tester.pumpWidget(createTestWidget(const BlueprintScreen()));
      await tester.pump();

      expect(find.text('Your Fitness Blueprint'), findsOneWidget);
      expect(find.text('6-DIMENSION ATHLETIC CLASSIFICATION'), findsOneWidget);
      expect(find.text('Energy & Nutrition Budget'), findsOneWidget);
      expect(find.text('Daily Caloric Target'), findsOneWidget);
      expect(find.text('Recommended 7-Day Blueprint'), findsOneWidget);

      // Check Schedule entries
      expect(find.textContaining('Upper Body Hypertrophy'), findsOneWidget);
      expect(find.textContaining('Zone 2 GPS Outdoor Run'), findsOneWidget);
      expect(find.text('Accept & Activate Blueprint'), findsOneWidget);
    });
  });
}
