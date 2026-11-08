import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/services/credential_cache_service.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/auth/screens/sign_in_screen.dart';
import 'package:raize_mobile/features/workouts/screens/live_workout_screen.dart';
import 'package:raize_mobile/features/workouts/providers/workout_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remember Me & Start Activity Feature Verification Tests', () {
    setUp(() async {
      await CredentialCacheService.clearCredentials();
    });

    test('1. CredentialCacheService saves, reads, and clears login credentials', () async {
      expect(await CredentialCacheService.getSavedCredentials(), isNull);

      await CredentialCacheService.saveCredentials(
        email: 'saved_athlete@raize.fit',
        password: 'SecurePassword123!',
      );

      final creds = await CredentialCacheService.getSavedCredentials();
      expect(creds, isNotNull);
      expect(creds!.email, 'saved_athlete@raize.fit');
      expect(creds.password, 'SecurePassword123!');
      expect(creds.rememberMe, isTrue);

      await CredentialCacheService.clearCredentials();
      expect(await CredentialCacheService.getSavedCredentials(), isNull);
    });

    testWidgets('2. SignInScreen pre-fills email and password when Remember Me credentials exist in cache', (tester) async {
      await CredentialCacheService.saveCredentials(
        email: 'cached_user@raize.fit',
        password: 'CachedSecretPass!',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SignInScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cached_user@raize.fit'), findsOneWidget);
      expect(find.text('CachedSecretPass!'), findsOneWidget);
    });

    testWidgets('3. LiveWorkoutScreen displays prominent START ACTIVITY button when not started', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('start_workout_activity_button')), findsOneWidget);
      expect(find.text('START ACTIVITY'), findsOneWidget);
      expect(find.text('WORKOUT ACTIVITY READY'), findsOneWidget);
    });

    testWidgets('4. Tapping START ACTIVITY triggers session start and removes start banner', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LiveWorkoutScreen(autoStartTimer: false, syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(liveWorkoutProvider).isStarted, isFalse);

      final startBtn = find.byKey(const Key('start_workout_activity_button'));
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pump();

      expect(container.read(liveWorkoutProvider).isStarted, isTrue);
      expect(find.byKey(const Key('start_workout_activity_button')), findsNothing);
    });
  });
}

