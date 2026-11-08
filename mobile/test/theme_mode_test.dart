import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:raize_mobile/core/constants/app_colors.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/core/theme/theme_provider.dart';
import 'package:raize_mobile/core/widgets/theme_toggle_button.dart';
import 'package:raize_mobile/features/dashboard/screens/home_dashboard_screen.dart';
import 'package:raize_mobile/features/nutrition/screens/nutrition_diary_screen.dart';
import 'package:raize_mobile/features/workouts/screens/live_workout_screen.dart';
import 'package:raize_mobile/features/billing/screens/paywall_screen.dart';
import 'package:raize_mobile/features/auth/screens/sign_in_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Sleek Light & Dark Theme System Tests', () {
    test('1. AppColorsExtension exposes balanced palettes for Light and Dark modes', () {
      const light = AppColorsExtension.light;
      const dark = AppColorsExtension.dark;

      expect(light.isDark, isFalse);
      expect(dark.isDark, isTrue);

      // Light mode canvas & typography checks
      expect(light.background, equals(AppLightColors.background));
      expect(light.card, equals(AppLightColors.card));
      expect(light.textPrimary, equals(AppLightColors.textPrimary));
      expect(light.border, equals(AppLightColors.border));

      // Dark mode canvas & typography checks
      expect(dark.background, equals(AppDarkColors.background));
      expect(dark.card, equals(AppDarkColors.card));
      expect(dark.textPrimary, equals(AppDarkColors.textPrimary));
      expect(dark.border, equals(AppDarkColors.border));

      // Brand accents are present in both
      expect(light.primary, isNotNull);
      expect(light.emerald, isNotNull);
      expect(light.amber, isNotNull);
      expect(light.destructive, isNotNull);
    });

    test('2. AppTheme.lightTheme and darkTheme provide consistent Material 3 foundations', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.brightness, equals(Brightness.light));
      expect(darkTheme.brightness, equals(Brightness.dark));

      expect(lightTheme.scaffoldBackgroundColor, equals(AppLightColors.background));
      expect(darkTheme.scaffoldBackgroundColor, equals(AppDarkColors.background));

      // ThemeExtensions registered
      expect(lightTheme.extension<AppColorsExtension>(), isNotNull);
      expect(darkTheme.extension<AppColorsExtension>(), isNotNull);
    });

    test('3. ThemeModeNotifier toggles between dark, light, and system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      notifier.setSystem();
      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      notifier.setLight();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    testWidgets('4. HomeDashboardScreen renders cleanly under AppTheme.lightTheme without overflow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const HomeDashboardScreen(autoFetch: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeDashboardScreen), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Tapping ThemeToggleButton toggles active theme mode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: Center(
                child: ThemeToggleButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      final toggle = find.byKey(const Key('theme_toggle_button'));
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
    });

    testWidgets('6. NutritionDiaryScreen renders cleanly under AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const NutritionDiaryScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NutritionDiaryScreen), findsOneWidget);
      expect(find.text('RAIZE NUTRITION OS'), findsOneWidget);
      expect(find.text('Meal Schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. LiveWorkoutScreen renders cleanly under AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveWorkoutScreen), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. PaywallScreen renders cleanly under AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.text('Unlock Your Full\nAthletic Potential'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. SignInScreen renders cleanly under AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: const SignInScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. ThemeModeSegmentedSelector switches themes on segment tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Center(
                child: ThemeModeSegmentedSelector(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      // Tap Light
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), equals(ThemeMode.light));

      // Tap System
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      // Tap Dark
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
    });
  });
}
