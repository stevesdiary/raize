import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/auth/models/user_model.dart';
import 'package:raize_mobile/features/auth/providers/auth_provider.dart';
import 'package:raize_mobile/features/profile/screens/account_settings_screen.dart';
import 'package:raize_mobile/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget(Widget child, {UserModel? user, bool isSubscribed = true}) {
    return ProviderScope(
      overrides: [
        if (user != null)
          authProvider.overrideWith(() {
            final notifier = AuthNotifier();
            return notifier;
          }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: child,
      ),
    );
  }

  group('Profile & Account Settings Feature Tests', () {
    testWidgets('1. ProfileScreen renders athlete profile, telemetry stats, and Account Settings tile', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileScreen()));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Athlete Profile'), findsOneWidget);
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('WORKOUTS'), findsOneWidget);
      expect(find.byKey(const Key('profile_account_settings_tile')), findsOneWidget);
      expect(find.byKey(const Key('profile_membership_tile')), findsOneWidget);
      expect(find.byKey(const Key('profile_sign_out_button')), findsOneWidget);
    });

    testWidgets('2. ProfileScreen navigates to AccountSettingsScreen on tile tap', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('profile_account_settings_tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AccountSettingsScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AccountSettingsScreen),
          matching: find.text('Account Settings'),
        ),
        findsOneWidget,
      );
      expect(find.text('NDPA 2023 SEC. 24'), findsOneWidget);
    });

    testWidgets('3. AccountSettingsScreen displays membership details, Cancel Subscription, and Delete Account', (tester) async {
      await tester.pumpWidget(createTestWidget(const AccountSettingsScreen(syncBackend: false)));
      await tester.pump();

      expect(find.byType(AccountSettingsScreen), findsOneWidget);
      expect(find.text('MEMBERSHIP & SUBSCRIPTION'), findsOneWidget);
      expect(find.byKey(const Key('cancel_subscription_button')), findsOneWidget);
      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
    });

    testWidgets('4. Cancel Subscription opens confirmation dialog and updates status banner upon confirm', (tester) async {
      await tester.pumpWidget(createTestWidget(const AccountSettingsScreen(syncBackend: false)));
      await tester.pump();

      // Tap Cancel Subscription
      await tester.tap(find.byKey(const Key('cancel_subscription_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify dialog is visible
      expect(find.byKey(const Key('cancel_subscription_dialog')), findsOneWidget);
      expect(find.text('Cancel Subscription?'), findsOneWidget);
      expect(find.byKey(const Key('keep_subscription_button')), findsOneWidget);
      expect(find.byKey(const Key('confirm_cancel_subscription_button')), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.byKey(const Key('confirm_cancel_subscription_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify success banner appears
      expect(find.textContaining('Subscription auto-renewal has been cancelled'), findsOneWidget);
    });

    testWidgets('5. Delete Account opens verification dialog requiring DELETE input to confirm', (tester) async {
      await tester.pumpWidget(createTestWidget(const AccountSettingsScreen(syncBackend: false)));
      await tester.pump();

      // Ensure button is visible in scrollview before tapping
      final deleteBtnFinder = find.byKey(const Key('delete_account_button'));
      await tester.ensureVisible(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(deleteBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify dialog is visible
      expect(find.byKey(const Key('delete_account_dialog')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('delete_account_dialog')),
          matching: find.text('Delete Account'),
        ),
        findsOneWidget,
      );
      expect(find.text('IRREVERSIBLE ACTION • NDPA SEC. 24'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('confirm_delete_account_button'));
      expect(confirmBtn, findsOneWidget);

      // Button is disabled when input is empty
      final btnWidgetBefore = tester.widget<ElevatedButton>(confirmBtn);
      expect(btnWidgetBefore.onPressed, isNull);

      // Enter "DELETE"
      await tester.enterText(find.byKey(const Key('delete_account_confirm_input')), 'DELETE');
      await tester.pump();

      // Button is now enabled
      final btnWidgetAfter = tester.widget<ElevatedButton>(confirmBtn);
      expect(btnWidgetAfter.onPressed, isNotNull);

      // Tap Cancel to dismiss cleanly
      await tester.tap(find.byKey(const Key('cancel_delete_account_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('delete_account_dialog')), findsNothing);
    });
  });
}
