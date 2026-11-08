import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/features/billing/screens/paywall_screen.dart';

void main() {
  group('Elite Subscription Paywall Journey Tests', () {
    testWidgets('1. PaywallScreen renders brand header, VO2 MAX insignia, headline, and subtitle',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand pill and Restore
      expect(find.text('RAIZE PRO • ELITE ACCESS'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      // Insignia & Headline
      expect(find.text('VO2 MAX'), findsOneWidget);
      expect(find.text('7-DAY FREE TRIAL'), findsOneWidget);
      expect(find.text('Unlock Your Full\nAthletic Potential'), findsOneWidget);
    });

    testWidgets('2. Bento matrix renders 5 elite telemetry features', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ELITE TELEMETRY SUITE'), findsOneWidget);
      expect(find.text('INCLUDED IN PRO'), findsOneWidget);

      expect(find.text('Adaptive 7-Day Training Blueprint'), findsOneWidget);
      expect(find.text('Live GPS & Route Telemetry'), findsOneWidget);
      expect(find.text('Full Resistance Library & Video Coaching'), findsOneWidget);
      expect(find.text('Nigerian & Global Nutrition Diary'), findsOneWidget);
      expect(find.text('Live Challenges & Community Kudos'), findsOneWidget);
    });

    testWidgets('3. Plan selector updates CTA button text when switching to monthly or coach',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is Annual
      expect(
        find.text('Start 7-Day Free Trial (₦45,000/yr)'),
        findsOneWidget,
      );

      // Scroll to Monthly Flexible
      await tester.scrollUntilVisible(
        find.text('Monthly Flexible'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monthly Flexible'));
      await tester.pumpAndSettle();

      // CTA label updates
      expect(find.text('Subscribe Monthly (₦5,000/mo)'), findsOneWidget);

      // Select Coach Tier
      await tester.tap(find.text('1-on-1 Certified Coach Tier'));
      await tester.pumpAndSettle();

      expect(find.text('Join Coach Tier (₦25,000/mo)'), findsOneWidget);
    });

    testWidgets('4. Trust badges, localized payment gateways, and checkout tap work cleanly',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trust badges
      expect(find.text('256-BIT BANK ENCRYPTION'), findsOneWidget);
      expect(find.text('INSTANT CANCELLATION'), findsOneWidget);

      // Payment badges
      expect(find.text('Paystack Secured'), findsOneWidget);
      expect(find.text('Visa'), findsOneWidget);
      expect(find.text('Mastercard'), findsOneWidget);
      expect(find.text('Verve'), findsOneWidget);
      expect(find.text('Apple Pay'), findsOneWidget);

      // Tap checkout CTA
      await tester.tap(find.text('Start 7-Day Free Trial (₦45,000/yr)'));
      await tester.pumpAndSettle();

      expect(
        find.text('Subscription activated: Annual Athletic Pass!'),
        findsOneWidget,
      );
    });

    testWidgets('5. PaywallScreen does not overflow on compact iOS viewport (375x667)', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaywallScreen(syncBackend: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start 7-Day Free Trial (₦45,000/yr)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

