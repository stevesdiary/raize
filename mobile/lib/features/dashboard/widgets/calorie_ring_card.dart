import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/dashboard_model.dart';

class CalorieRingCard extends StatelessWidget {
  final DashboardNutrition nutrition;

  const CalorieRingCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = (nutrition.consumedCalories / nutrition.targetCalories).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
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
                    color: colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MYFITNESSPAL NUTRITION EQUATION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Equation & Circle Arc
          Row(
            children: [
              // Custom Circular Progress Ring
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: colors.cardElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.amber),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${nutrition.remainingCalories}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'kcal left',
                            style: TextStyle(color: colors.textMuted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Breakdown Equation
              Expanded(
                child: Column(
                  children: [
                    _buildRowEquation(context, 'Daily Target', '${nutrition.targetCalories}', colors.textPrimary),
                    const SizedBox(height: 6),
                    _buildRowEquation(context, 'Food Consumed', '- ${nutrition.consumedCalories}', colors.amber),
                    const SizedBox(height: 6),
                    _buildRowEquation(context, 'Exercise Burned', '+ 350', colors.emerald),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 14),

          // Macro Progress Bars
          _buildMacroLinearBar(context, 'Protein', nutrition.proteinGrams, nutrition.targetProteinGrams, colors.primary),
          const SizedBox(height: 10),
          _buildMacroLinearBar(context, 'Carbohydrates', nutrition.carbsGrams, nutrition.targetCarbsGrams, colors.emerald),
          const SizedBox(height: 10),
          _buildMacroLinearBar(context, 'Fats', nutrition.fatGrams, nutrition.targetFatGrams, colors.amber),
        ],
      ),
    );
  }

  Widget _buildRowEquation(BuildContext context, String label, String value, Color color) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMacroLinearBar(BuildContext context, String name, int current, int target, Color color) {
    final colors = context.colors;
    final ratio = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$current / ${target}g',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: colors.cardElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

