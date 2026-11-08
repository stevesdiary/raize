import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/core/theme/app_theme.dart';
import 'package:raize_mobile/features/auth/screens/splash_screen.dart';
import 'package:raize_mobile/features/auth/screens/onboarding_screen.dart';
import 'package:raize_mobile/features/auth/screens/sign_up_screen.dart';
import 'package:raize_mobile/features/auth/screens/sign_in_screen.dart';
import 'package:raize_mobile/features/auth/widgets/athletic_button.dart';
import 'package:raize_mobile/features/auth/providers/auth_provider.dart';
import 'package:raize_mobile/features/auth/models/user_model.dart';
import 'package:raize_mobile/features/auth/models/auth_state.dart';
import 'package:raize_mobile/features/dashboard/screens/home_dashboard_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('User Journey 1: Auth & Onboarding Flow Tests', () {
    testWidgets('1. SplashScreen renders branding and telemetry tag', (tester) async {
      await tester.pumpWidget(createTestWidget(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RAIZE'), findsOneWidget);
      expect(find.text('UNIFIED ATHLETIC OS'), findsOneWidget);
      expect(find.text('MIFFLIN-ST JEOR & KALMAN TELEMETRY'), findsOneWidget);
    });

    testWidgets('1b. SplashScreen "Get Started" button navigates directly to OnboardingScreen for unauthenticated user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeUnauthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final getStartedBtn = find.widgetWithText(AthleticButton, 'Get Started');
      expect(getStartedBtn, findsOneWidget);

      await tester.tap(getStartedBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('2. OnboardingScreen renders value propositions and CTA buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingScreen()));
      await tester.pump();

      // Check Header & Actions
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('I already have an account • Log In'), findsOneWidget);

      // Check first slide content (MyFitnessPal nutrition capability)
      expect(find.text('MYFITNESSPAL CAPABILITY'), findsOneWidget);
      expect(find.text('1,920 kcal Target'), findsOneWidget);

      // Swipe to next slide (Strava GPS capability)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('STRAVA CAPABILITY'), findsOneWidget);
      expect(find.text('250m Safe Zones'), findsOneWidget);

      // Swipe to third slide (LADDER Training capability)
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('LADDER CAPABILITY'), findsOneWidget);
      expect(find.text('Overload Tonnage'), findsOneWidget);
    });

    testWidgets('2b. OnboardingScreen "Get Started" steps through slides and transitions to SignUp', (tester) async {
      await tester.pumpWidget(createTestWidget(const OnboardingScreen()));
      await tester.pump();

      // Initially on slide 0: MyFitnessPal capability
      expect(find.text('MYFITNESSPAL CAPABILITY'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap "Get Started" on slide 0 -> Advances to slide 1
      await tester.tap(find.widgetWithText(AthleticButton, 'Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('STRAVA CAPABILITY'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap "Continue" on slide 1 -> Advances to slide 2
      await tester.tap(find.widgetWithText(AthleticButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('LADDER CAPABILITY'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap "Get Started" on slide 2 -> Navigates to SignUpScreen
      await tester.tap(find.widgetWithText(AthleticButton, 'Get Started'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('3. SignUpScreen renders form fields, 18+ safeguard, and NDPA consent', (tester) async {
      await tester.pumpWidget(createTestWidget(const SignUpScreen()));
      await tester.pump();

      expect(find.text('Create Account'), findsNWidgets(2)); // AppBar title & Submit button
      expect(find.text('Start Your Athletic Journey'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('18+ Adult Training Platform • Minor Safeguards Enforced'), findsOneWidget);
      expect(find.text('Measurement Preference'), findsOneWidget);
      expect(find.text('Metric (kg, cm, km)'), findsOneWidget);
      expect(find.text('Imperial (lbs, ft, mi)'), findsOneWidget);
      expect(find.textContaining('NDPA 2023 Data Privacy Policy'), findsOneWidget);
    });

    testWidgets('4. SignInScreen renders credential fields, Face ID, and Social Auth', (tester) async {
      await tester.pumpWidget(createTestWidget(const SignInScreen()));
      await tester.pump();

      expect(find.text('Sign In'), findsNWidgets(2)); // AppBar title & CTA button
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email / Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign In with Face ID'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('5. SignInScreen redirects directly to HomeDashboardScreen upon successful login', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeSuccessAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SignInScreen(),
          ),
        ),
      );
      await tester.pump();

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'ada.okonkwo@raize.fit');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!Secure');
      await tester.pump();

      // Tap Sign In CTA button
      final btn = find.widgetWithText(AthleticButton, 'Sign In');
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify that the user was redirected to HomeDashboardScreen
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
    });

    testWidgets('6. SignInScreen accepts username with @ prefix and redirects to HomeDashboardScreen', (tester) async {
      String? submittedIdentifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => FakeCaptureAuthNotifier((id) => submittedIdentifier = id)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SignInScreen(),
          ),
        ),
      );
      await tester.pump();

      // Enter username handle with @
      await tester.enterText(find.byType(TextFormField).at(0), '@ada_runner');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!Secure');
      await tester.pump();

      await tester.tap(find.widgetWithText(AthleticButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(submittedIdentifier, '@ada_runner');
      expect(find.byType(HomeDashboardScreen), findsOneWidget);
    });
  });
}

class FakeCaptureAuthNotifier extends AuthNotifier {
  final void Function(String id) onLogin;
  FakeCaptureAuthNotifier(this.onLogin);

  @override
  AuthState build() => AuthState.unauthenticated();

  @override
  Future<bool> login(String identifier, String password) async {
    onLogin(identifier);
    state = AuthState.authenticated(
      const UserModel(
        id: 'user_01',
        email: 'ada.okonkwo@raize.fit',
        username: 'ada_runner',
        fullName: 'Ada Okonkwo',
      ),
    );
    return true;
  }
}

class FakeSuccessAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated();

  @override
  Future<bool> login(String identifier, String password) async {
    state = AuthState.authenticated(
      const UserModel(
        id: 'user_01',
        email: 'ada.okonkwo@raize.fit',
        username: 'ada_runner',
        fullName: 'Ada Okonkwo',
      ),
    );
    return true;
  }
}

class FakeUnauthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState.unauthenticated();

  @override
  Future<void> checkAuth() async {
    state = AuthState.unauthenticated();
  }
}
