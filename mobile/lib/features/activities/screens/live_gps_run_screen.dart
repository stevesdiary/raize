import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/screens/home_dashboard_screen.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';

class LiveGpsRunScreen extends ConsumerStatefulWidget {
  final bool autoStartTimer;
  final bool syncBackend;
  final bool enablePulseAnimation;

  const LiveGpsRunScreen({
    super.key,
    this.autoStartTimer = false,
    this.syncBackend = false,
    this.enablePulseAnimation = true,
  });

  @override
  ConsumerState<LiveGpsRunScreen> createState() => _LiveGpsRunScreenState();
}

class _LiveGpsRunScreenState extends ConsumerState<LiveGpsRunScreen>
    with SingleTickerProviderStateMixin {
  late final ActivityNotifier _notifier;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(activityProvider.notifier);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.enablePulseAnimation) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.autoStartTimer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notifier.startRun();
        }
      });
    }
  }

  @override
  void dispose() {
    _notifier.cancelTimers();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activityProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Top System & Status Header
              _buildTopStatusHeader(session),

              // 2. Map Canvas View (~38% of screen)
              Expanded(
                flex: 40,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: _MapTrackPainter(
                        pulseValue: _pulseController.value,
                        headingDegrees: session.headingDegrees,
                        colors: colors,
                      ),
                    ),
                    // Floating ergonomic controls on the right
                    Positioned(
                      top: 12,
                      right: 14,
                      child: Column(
                        children: [
                          _buildMapIconButton(Icons.layers_outlined, () {}),
                          const SizedBox(height: 8),
                          _buildMapIconButton(
                            Icons.my_location,
                            () {},
                            iconColor: colors.neonEmerald,
                          ),
                          const SizedBox(height: 8),
                          _buildMapIconButton(Icons.fullscreen, () {}),
                        ],
                      ),
                    ),
                    // Segment Lap Notice Chip at bottom-left of map
                    Positioned(
                      left: 14,
                      bottom: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.cardElevated.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.neonEmerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              session.segmentNotice,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Telemetry HUD Dashboard (Bottom 60%)
              Expanded(
                flex: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                        color: colors.border,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    child: Column(
                      children: [
                        // Grab bar indicator
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.borderSubtle,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Hero Distance Card
                        _buildHeroDistanceCard(session),
                        const SizedBox(height: 12),

                        // 6-Metric High-Density Grid
                        _buildTelemetryGrid(session),
                        const SizedBox(height: 12),

                        // Split Performance Strip
                        _buildSplitPerformanceStrip(session),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 4. Fixed Ergonomic Action Dock (Bottom Thumb Zone)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionDock(session),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusHeader(GpsRunSession session) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top Navigation Bar Row with Return / Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Tooltip(
                    message: 'Back to Dashboard',
                    child: InkWell(
                      key: const Key('gps_run_back_button'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.cardElevated,
                          border: Border.all(
                            color: colors.border,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.neonEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GPS RUN TELEMETRY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Audio Coach Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq, size: 14, color: colors.kineticIndigo),
                    const SizedBox(width: 4),
                    Text(
                      'COACH ON',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.kineticIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // GPS Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // GPS Locked Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.cardElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.neonEmerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.neonEmerald.withValues(
                            alpha: 0.4 + (_pulseController.value * 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSignalBar(4),
                        const SizedBox(width: 2),
                        _buildSignalBar(6),
                        const SizedBox(width: 2),
                        _buildSignalBar(8),
                        const SizedBox(width: 2),
                        _buildSignalBar(10),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GPS LOCKED',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.neonEmerald,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 1, height: 10, color: colors.border),
                    const SizedBox(width: 6),
                    Text(
                      'KALMAN FILTER',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Telemetry Precision Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.cardElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt_rounded, size: 13, color: colors.neonEmerald),
                    const SizedBox(width: 4),
                    Text(
                      '10 HZ RTK',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: colors.neonEmerald,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 250m Privacy Mask Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.cardElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: colors.neonEmerald),
                    const SizedBox(width: 6),
                    Text(
                      '250m Home Privacy Mask Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ZONE 1 MASKED',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBar(double height) {
    final colors = context.colors;
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: colors.neonEmerald,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildMapIconButton(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.cardElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (iconColor ?? colors.border).withValues(alpha: colors.isDark ? 0.4 : 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: iconColor ?? colors.textPrimary),
      ),
    );
  }

  Widget _buildHeroDistanceCard(GpsRunSession session) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'DISTANCE TRAVELED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.15 : 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: colors.neonEmerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'OUTDOOR RUN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colors.neonEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        session.distanceKm.toStringAsFixed(2),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'KM',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PROJECTED 10K',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.projected10kTime,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 12, color: colors.neonEmerald),
                      const SizedBox(width: 2),
                      Text(
                        '-0:42 PR PACE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET: ${session.targetDistanceKm.toStringAsFixed(2)} KM',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: colors.textMuted,
                ),
              ),
              Text(
                '${session.progressPercentage.toStringAsFixed(1)}% COMPLETED',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.neonEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: session.progressRatio,
              minHeight: 6,
              backgroundColor: colors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(colors.neonEmerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(GpsRunSession session) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        // 1. PACE
        _buildMetricTile(
          title: 'PACE',
          value: session.formattedPace,
          unit: '/km',
          subtitle: '▼ 0:04 vs avg',
          subtitleColor: AppColors.neonEmerald,
          icon: Icons.speed,
          iconColor: AppColors.kineticIndigo,
        ),
        // 2. DURATION
        _buildMetricTile(
          title: 'DURATION',
          value: session.formattedDuration,
          unit: 'elapsed',
          subtitle: 'MOVING: ${session.formattedMovingDuration}',
          subtitleColor: AppColors.textMuted,
          icon: Icons.timer_outlined,
          iconColor: Colors.white70,
        ),
        // 3. HEART RATE
        _buildHeartRateMetricTile(session),
        // 4. CALORIES
        _buildMetricTile(
          title: 'CALORIES',
          value: '${session.activeKcal}',
          unit: 'ACTIVE KCAL',
          subtitle: 'EFFORT: ${session.effortScore} / 10',
          subtitleColor: AppColors.neonEmerald,
          icon: Icons.local_fire_department,
          iconColor: AppColors.neonEmerald,
        ),
        // 5. CADENCE
        _buildMetricTile(
          title: 'CADENCE',
          value: '${session.cadenceSpm}',
          unit: 'SPM',
          subtitle: '● OPTIMAL ZONE',
          subtitleColor: AppColors.neonEmerald,
          icon: Icons.directions_run,
          iconColor: AppColors.kineticIndigo,
        ),
        // 6. ELEVATION
        _buildMetricTile(
          title: 'ELEVATION',
          value: '+${session.elevationGainMeters}',
          unit: 'METERS GAIN',
          subtitle: 'GRADE: +${session.gradePercent}%',
          subtitleColor: AppColors.textMuted,
          icon: Icons.terrain,
          iconColor: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateMetricTile(GpsRunSession session) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HEART RATE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.textMuted,
                ),
              ),
              Icon(Icons.favorite, size: 14, color: colors.destructive),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${session.heartRateBpm}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'BPM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Mini live ECG wave representation
              SizedBox(
                height: 12,
                child: CustomPaint(
                  size: const Size(60, 12),
                  painter: _EcgWavePainter(color: colors.destructive),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colors.destructive.withValues(alpha: colors.isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colors.destructive.withValues(alpha: colors.isDark ? 0.5 : 0.4),
              ),
            ),
            child: Text(
              'ZONE ${session.heartRateZone} • THRESHOLD',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: colors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPerformanceStrip(GpsRunSession session) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    'KM ${session.fastestSplitKm}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.neonEmerald,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.currentSplitPace,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.15 : 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⚡ FASTEST SPLIT',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: colors.neonEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Split 4 was 5:21 • +9s pace surge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Pacing visualizer bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.neonEmerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: colors.neonEmerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(GpsRunSession session) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.background.withValues(alpha: 0.0),
            colors.background.withValues(alpha: 0.95),
            colors.background,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Photo / Milestone Camera
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route milestone captured!')),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.cardElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Icon(Icons.photo_camera_outlined, color: colors.textPrimary, size: 22),
            ),
          ),

          // Center: Start Run Trigger (when standby) OR Giant Kinetic Pause / Resume Button (when active)
          if (!session.isStarted)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const Key('start_gps_run_button'),
                  onTap: () {
                    _notifier.startRun();
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.neonEmerald,
                          Color(0xFF34D399),
                          AppColors.kineticIndigo,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonEmerald.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.neonEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 42,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'START RUN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonEmerald,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const Key('pause_resume_gps_run_button'),
                  onTap: () {
                    final willBePaused = !session.isPaused;
                    _notifier.togglePause();
                    if (willBePaused) {
                      _showFinishBottomSheet(ref.read(activityProvider));
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.neonEmerald, colors.kineticIndigo],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.neonEmerald.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.card,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          session.isPaused ? Icons.play_arrow : Icons.pause,
                          size: 32,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.isPaused ? 'TAP TO RESUME' : 'TAP TO PAUSE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

          // Right: Screen Lock Toggle
          GestureDetector(
            onTap: () => _notifier.toggleScreenLock(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.cardElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: session.isScreenLocked
                      ? colors.kineticIndigo
                      : colors.border,
                ),
              ),
              child: Icon(
                session.isScreenLocked ? Icons.lock : Icons.lock_open,
                color: session.isScreenLocked ? colors.kineticIndigo : colors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishBottomSheet(GpsRunSession session) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.border),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Run Paused',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${session.distanceKm} km • Time: ${session.formattedDuration}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.neonEmerald,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _notifier.togglePause();
              },
              child: Text(
                'Resume Workout',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.destructive,
                side: BorderSide(color: colors.destructive),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _notifier.completeSession(syncBackend: widget.syncBackend);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Finish & Save Run',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTrackPainter extends CustomPainter {
  final double pulseValue;
  final int headingDegrees;
  final AppColorsExtension colors;

  _MapTrackPainter({
    required this.pulseValue,
    required this.headingDegrees,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = colors.isDark;

    // 0. Base Map Canvas Fill (Sleek light map in light mode, stealth dark in dark mode)
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0A0E18) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 1. Grid pattern lines
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF313540).withValues(alpha: 0.3)
          : const Color(0xFF94A3B8).withValues(alpha: 0.25)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Road Street Network
    if (!isDark) {
      final roadCasingPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(size.width * 0.1, size.height),
        Offset(size.width * 0.2, 0),
        roadCasingPaint,
      );
      canvas.drawLine(
        Offset(size.width * 0.5, size.height),
        Offset(size.width * 0.45, 0),
        roadCasingPaint,
      );
      canvas.drawLine(
        Offset(0, size.height * 0.4),
        Offset(size.width, size.height * 0.55),
        roadCasingPaint,
      );
    }

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1F2A) : Colors.white
      ..strokeWidth = isDark ? 5 : 5.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height),
      Offset(size.width * 0.2, 0),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.45, 0),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );

    // 3. Park Green Pocket
    final parkPaint = Paint()
      ..color = isDark
          ? const Color(0xFF003824).withValues(alpha: 0.3)
          : const Color(0xFF10B981).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final parkPath = Path()
      ..moveTo(size.width * 0.55, size.height * 0.15)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.1, size.width * 0.85, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.45, size.width * 0.53, size.height * 0.35)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    if (!isDark) {
      final parkBorderPaint = Paint()
        ..color = const Color(0xFF059669).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(parkPath, parkBorderPaint);
    }

    // 4. GPS Polyline Track
    final trackPath = Path();
    final p0 = Offset(size.width * 0.12, size.height * 0.85);
    final p1 = Offset(size.width * 0.25, size.height * 0.65);
    final p2 = Offset(size.width * 0.45, size.height * 0.55);
    final p3 = Offset(size.width * 0.60, size.height * 0.42);
    final p4 = Offset(size.width * 0.72, size.height * 0.48);
    final pCurrent = Offset(size.width * 0.82, size.height * 0.30);

    trackPath.moveTo(p0.dx, p0.dy);
    trackPath.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
    trackPath.quadraticBezierTo(p3.dx, p3.dy, p4.dx, p4.dy);
    trackPath.lineTo(pCurrent.dx, pCurrent.dy);

    // Glow track
    final glowPaint = Paint()
      ..color = (isDark ? colors.neonEmerald : const Color(0xFF059669))
          .withValues(alpha: isDark ? 0.35 : 0.25)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, glowPaint);

    // Core sharp trajectory line
    final coreTrackPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [colors.neonEmerald, colors.kineticIndigo]
            : const [Color(0xFF059669), Color(0xFF4F46E5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, coreTrackPaint);

    // 5. Mile / KM split markers (1-5)
    final splitPoints = [p0, p1, p2, p3, p4];
    for (int i = 0; i < splitPoints.length; i++) {
      final isLast = i == splitPoints.length - 1;
      final splitCenter = splitPoints[i];
      final splitCirclePaint = Paint()
        ..color = isLast
            ? (isDark ? colors.neonEmerald : const Color(0xFF059669))
            : (isDark ? colors.surfaceContainerHigh : Colors.white);
      canvas.drawCircle(splitCenter, 8, splitCirclePaint);

      final borderPaint = Paint()
        ..color = isLast
            ? (isDark ? Colors.white : const Color(0xFF047857))
            : (isDark ? colors.border : const Color(0xFF94A3B8))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(splitCenter, 8, borderPaint);

      final textSpan = TextSpan(
        text: '${i + 1}',
        style: TextStyle(
          color: isLast ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          splitCenter.dx - (textPainter.width / 2),
          splitCenter.dy - (textPainter.height / 2),
        ),
      );
    }

    // 6. Current Runner Position Marker with Pulsing Halo and 312° Heading Arrow
    final radarHaloPaint = Paint()
      ..color = (isDark ? colors.neonEmerald : const Color(0xFF059669))
          .withValues(alpha: (isDark ? 0.2 : 0.25) * (1.0 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pCurrent, 18 + (pulseValue * 10), radarHaloPaint);

    final runnerBgPaint = Paint()
      ..color = isDark ? colors.background : Colors.white;
    canvas.drawCircle(pCurrent, 13, runnerBgPaint);

    final runnerRingPaint = Paint()
      ..color = isDark ? colors.neonEmerald : const Color(0xFF059669)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pCurrent, 13, runnerRingPaint);

    // Heading Chevron rotated by heading angle
    canvas.save();
    canvas.translate(pCurrent.dx, pCurrent.dy);
    canvas.rotate((headingDegrees - 45) * math.pi / 180);

    final arrowPaint = Paint()
      ..color = isDark ? colors.neonEmerald : const Color(0xFF059669)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(0, -6)
      ..lineTo(5, 5)
      ..lineTo(0, 2)
      ..lineTo(-5, 5)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapTrackPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.colors != colors;
  }
}

class _EcgWavePainter extends CustomPainter {
  final Color? color;

  _EcgWavePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? AppColors.destructiveCoral
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.38, size.height * 0.1)
      ..lineTo(size.width * 0.44, size.height * 0.9)
      ..lineTo(size.width * 0.50, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.65)
      ..lineTo(size.width * 0.60, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
