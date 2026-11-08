import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raize_mobile/features/activities/screens/live_gps_run_screen.dart';

void main() {
  group('Live GPS Run Telemetry Screen Tests', () {
    testWidgets('1. LiveGpsRunScreen renders GPS status, 250m privacy pill and distance metrics',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveGpsRunScreen(
              autoStartTimer: false,
              syncBackend: false,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // GPS Status & Privacy Mask
      expect(find.text('GPS LOCKED'), findsOneWidget);
      expect(find.text('KALMAN FILTER'), findsOneWidget);
      expect(find.text('COACH ON'), findsOneWidget);
      expect(find.text('250m Home Privacy Mask Active'), findsOneWidget);
      expect(find.text('ZONE 1 MASKED'), findsOneWidget);

      // Hero distance & Projected 10k
      expect(find.text('DISTANCE TRAVELED'), findsOneWidget);
      expect(find.text('5.42'), findsOneWidget);
      expect(find.text('KM'), findsOneWidget);
      expect(find.text('PROJECTED 10K'), findsOneWidget);
      expect(find.text('53:20'), findsOneWidget);
      expect(find.text('-0:42 PR PACE'), findsOneWidget);
    });

    testWidgets('2. Telemetry grid renders 6 high-density cards and fastest split indicator',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveGpsRunScreen(
              autoStartTimer: false,
              syncBackend: false,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 6 metric titles
      expect(find.text('PACE'), findsOneWidget);
      expect(find.text('5:18'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('28:44'), findsOneWidget);
      expect(find.text('HEART RATE'), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
      expect(find.text('ZONE 4 • THRESHOLD'), findsOneWidget);
      expect(find.text('CALORIES'), findsOneWidget);
      expect(find.text('382'), findsOneWidget);
      expect(find.text('CADENCE'), findsOneWidget);
      expect(find.text('168'), findsOneWidget);
      expect(find.text('ELEVATION'), findsOneWidget);
      expect(find.text('+42'), findsOneWidget);

      // Split strip
      expect(find.text('KM 5'), findsOneWidget);
      expect(find.text('⚡ FASTEST SPLIT'), findsOneWidget);
    });

    testWidgets('3. Standby start trigger initiates tracking, transitions to pause, and opens finish modal',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveGpsRunScreen(
              autoStartTimer: false,
              syncBackend: false,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standby mode: START RUN button is displayed
      final startButton = find.byKey(const Key('start_gps_run_button'));
      expect(startButton, findsOneWidget);
      expect(find.text('START RUN'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byKey(const Key('pause_resume_gps_run_button')), findsNothing);

      // Tap START RUN
      await tester.tap(startButton);
      await tester.pump();

      // Active mode: Pause button is displayed
      final pauseButton = find.byKey(const Key('pause_resume_gps_run_button'));
      expect(pauseButton, findsOneWidget);
      expect(find.text('TAP TO PAUSE'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byKey(const Key('start_gps_run_button')), findsNothing);

      // Tap pause button (Center kinetic button)
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      // Bottom sheet should open with run summary
      expect(find.text('Run Paused'), findsOneWidget);
      expect(find.text('Resume Workout'), findsOneWidget);
      expect(find.text('Finish & Save Run'), findsOneWidget);

      // Resume
      await tester.tap(find.text('Resume Workout'));
      await tester.pumpAndSettle();

      expect(find.text('Run Paused'), findsNothing);
    });

    testWidgets('4. Screen lock toggle alternates state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveGpsRunScreen(
              autoStartTimer: false,
              syncBackend: false,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open), findsOneWidget);

      await tester.tap(find.byIcon(Icons.lock_open));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('5. LiveGpsRunScreen back button pops and returns to previous screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LiveGpsRunScreen(
                          autoStartTimer: false,
                          syncBackend: false,
                          enablePulseAnimation: false,
                        ),
                      ),
                    );
                  },
                  child: const Text('Start Run'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveGpsRunScreen), findsOneWidget);

      final backBtn = find.byKey(const Key('gps_run_back_button'));
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LiveGpsRunScreen), findsNothing);
      expect(find.text('Start Run'), findsOneWidget);
    });

    testWidgets('6. LiveGpsRunScreen autoStartTimer starts active session immediately when true',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveGpsRunScreen(
              autoStartTimer: true,
              syncBackend: false,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // When autoStartTimer is true, it starts immediately into active tracking
      expect(find.byKey(const Key('pause_resume_gps_run_button')), findsOneWidget);
      expect(find.text('TAP TO PAUSE'), findsOneWidget);
      expect(find.byKey(const Key('start_gps_run_button')), findsNothing);
    });
  });
}
