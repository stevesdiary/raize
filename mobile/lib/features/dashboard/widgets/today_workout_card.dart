import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_model.dart';

class TodayWorkoutCard extends StatelessWidget {
  final DashboardWorkout? workout;
  final VoidCallback onStart;

  const TodayWorkoutCard({
    super.key,
    required this.workout,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (workout == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.nightlight_round, size: 36, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              'Rest & Recovery Day',
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'No workouts scheduled. Hydrate and hit your protein target.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primary.withAlpha(colors.isDark ? 80 : 60),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.isDark
                ? colors.primary.withAlpha(30)
                : colors.primary.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(colors.isDark ? 35 : 25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "TODAY'S AGENDA • LADDER PROGRESSION",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primary,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  '${workout!.durationMinutes} min',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Workout Title
          Text(
            workout!.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${workout!.exerciseCount} Exercises • Barbell Bench, Incline DB, Dips',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // CTA Action Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onStart();
            },
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryHover],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        'Start Workout Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

