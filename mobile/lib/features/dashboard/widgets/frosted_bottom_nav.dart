import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class FrostedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FrostedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final colors = context.colors;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            bottom: bottomInset > 0 ? bottomInset + 4 : 14,
            left: 12,
            right: 12,
          ),
          decoration: BoxDecoration(
            color: colors.isDark
                ? colors.background.withAlpha(200)
                : Colors.white.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: colors.borderSubtle, width: 1),
            ),
            boxShadow: colors.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, 'Home', Icons.grid_view_rounded),
              _buildNavItem(context, 1, 'Workouts', Icons.fitness_center_rounded),
              _buildNavItem(context, 2, 'GPS Run', Icons.navigation_rounded),
              _buildNavItem(context, 3, 'Nutrition', Icons.restaurant_rounded),
              _buildNavItem(context, 4, 'Profile', Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String label, IconData icon) {
    final colors = context.colors;
    final isSelected = currentIndex == index;
    final color = isSelected ? colors.primary : colors.textMuted;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTabSelected(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

