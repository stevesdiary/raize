import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_model.dart';
import 'home_screen_widget_sheet.dart';

class StepStreakCard extends StatelessWidget {
  final DashboardStepTelemetry steps;
  final int streakDays;

  const StepStreakCard({
    super.key,
    required this.steps,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.35 : 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? colors.neonEmerald.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Badge & Widget Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.neonEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 14, color: colors.neonEmerald),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'DAILY STEP TELEMETRY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: colors.neonEmerald,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Widget Pill / Action
              Tooltip(
                message: 'Add Widget to Phone Screen',
                child: InkWell(
                  key: const Key('add_home_screen_widget_button'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => HomeScreenWidgetSheet(
                        steps: steps,
                        streakDays: streakDays,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.widgets_outlined, size: 13, color: colors.kineticIndigo),
                        const SizedBox(width: 4),
                        Text(
                          'ADD WIDGET',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: colors.kineticIndigo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Step Count Hero & Streak Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatNumber(steps.todayCount),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${_formatNumber(steps.targetCount)} steps',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.amber.withValues(alpha: colors.isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${streakDays}d Streak',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Neon Kinetic Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: steps.progressRatio,
              minHeight: 7,
              backgroundColor: colors.cardElevated,
              valueColor: AlwaysStoppedAnimation<Color>(colors.neonEmerald),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Metrics Sub-Strip (Distance, Calories, Completion)
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.route_rounded,
                  label: 'Distance',
                  value: '${steps.distanceKm.toStringAsFixed(1)} km',
                  color: colors.kineticIndigo,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 20, color: colors.border),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.local_fire_department_rounded,
                  label: 'Active Burn',
                  value: '${steps.caloriesBurned} kcal',
                  color: colors.amber,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 20, color: colors.border),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricItem(
                  context,
                  icon: Icons.verified_rounded,
                  label: 'Progress',
                  value: '${steps.progressPercentage}%',
                  color: colors.neonEmerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
