import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/workout_models.dart';

class ExerciseHeroCard extends StatelessWidget {
  final ExerciseSessionItem exerciseItem;
  final VoidCallback onWatchFormCue;

  const ExerciseHeroCard({
    super.key,
    required this.exerciseItem,
    required this.onWatchFormCue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exercise = exerciseItem.exercise;

    // Calculate best estimated 1RM among completed sets
    double bestOneRepMax = 0;
    for (final s in exerciseItem.sets) {
      if (s.isCompleted && s.estimatedOneRepMax > bestOneRepMax) {
        bestOneRepMax = s.estimatedOneRepMax;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(colors.isDark ? 25 : 12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag & 1RM Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exercise.primaryMuscle.toUpperCase()} • ${exercise.equipment.toUpperCase()}',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (bestOneRepMax > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.amber.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, size: 14, color: colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Est. 1RM: ${bestOneRepMax.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise Name & Form Preview
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exerciseItem.target,
                      style: TextStyle(
                        color: colors.emerald,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Video Cue Button
              GestureDetector(
                key: const Key('exercise_video_demo_button'),
                behavior: HitTestBehavior.opaque,
                onTap: onWatchFormCue,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.cardElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Center(
                    child: Icon(Icons.play_circle_fill_rounded, color: colors.primary, size: 28),
                  ),
                ),
              ),
            ],
          ),

          // Form cues if available
          if (exercise.formCues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.cardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.formCues.first,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Video Demonstration Interactive Action Bar
          const SizedBox(height: 12),
          InkWell(
            key: const Key('hero_video_demo_action'),
            borderRadius: BorderRadius.circular(14),
            onTap: onWatchFormCue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.videocam_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WATCH VIDEO DEMONSTRATION',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '4K Kinematics • 3 Angles • Form & Rep Tempo Pacing',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: colors.primary, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

