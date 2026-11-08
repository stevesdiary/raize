import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class VolumeTonnageFooter extends StatelessWidget {
  final double totalVolumeKg;
  final int completedSets;
  final int totalSets;
  final bool isLastExercise;
  final VoidCallback onNextOrFinish;

  const VolumeTonnageFooter({
    super.key,
    required this.totalVolumeKg,
    required this.completedSets,
    required this.totalSets,
    required this.isLastExercise,
    required this.onNextOrFinish,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 28),
          decoration: BoxDecoration(
            color: colors.background.withAlpha(220),
            border: Border(top: BorderSide(color: colors.border, width: 1)),
          ),
          child: Row(
            children: [
              // Live Volume Tonnage Metrics
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL VOLUME TONNAGE',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${totalVolumeKg.toInt()} kg',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($completedSets/$totalSets sets)',
                          style: TextStyle(
                            color: colors.emerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button (Next Exercise or Finish)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onNextOrFinish();
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLastExercise
                          ? [colors.emerald, const Color(0xFF059669)]
                          : [colors.primary, const Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isLastExercise ? colors.emerald : colors.primary).withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastExercise ? 'Finish Workout' : 'Next Exercise',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastExercise ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
