import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../theme/theme_provider.dart';

/// A sleek, kinetic theme toggle button that switches between Light and Dark modes.
class ThemeToggleButton extends ConsumerWidget {
  final double size;

  const ThemeToggleButton({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final colors = context.colors;

    return Tooltip(
      message: isDark ? 'Switch to Sleek Light Mode' : 'Switch to AMOLED Dark Mode',
      child: InkWell(
        key: const Key('theme_toggle_button'),
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
        borderRadius: BorderRadius.circular(size / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.cardElevated,
            border: Border.all(
              color: isDark
                  ? colors.primary.withValues(alpha: 0.3)
                  : colors.amber.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.amber.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: size * 0.48,
                color: isDark ? colors.amber : colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A segmented selector for choosing between System, Light, and Dark mode explicitly.
class ThemeModeSegmentedSelector extends ConsumerWidget {
  const ThemeModeSegmentedSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildSegment(
            context,
            ref,
            label: 'Light',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            isSelected: currentMode == ThemeMode.light,
            colors: colors,
          ),
          _buildSegment(
            context,
            ref,
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            isSelected: currentMode == ThemeMode.dark,
            colors: colors,
          ),
          _buildSegment(
            context,
            ref,
            label: 'System',
            icon: Icons.settings_brightness_rounded,
            mode: ThemeMode.system,
            isSelected: currentMode == ThemeMode.system,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    required AppColorsExtension colors,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

