import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onStartGpsRun;
  final VoidCallback onLogMeal;
  final VoidCallback onLogWorkout;

  const QuickActionsBar({
    super.key,
    required this.onStartGpsRun,
    required this.onLogMeal,
    required this.onLogWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            context,
            title: 'GPS Run',
            subtitle: '250m Safe',
            icon: Icons.navigation_rounded,
            color: colors.emerald,
            onTap: onStartGpsRun,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            context,
            title: 'Log Meal',
            subtitle: 'Local Diet',
            icon: Icons.restaurant_rounded,
            color: colors.amber,
            onTap: onLogMeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            context,
            title: 'Workout',
            subtitle: 'LADDER Sets',
            icon: Icons.fitness_center_rounded,
            color: colors.primary,
            onTap: onLogWorkout,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(30),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

