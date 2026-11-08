import 'package:flutter/material.dart';

/// AppColors provides foundational palette constants and dynamic context-aware
/// semantic theme resolutions for both Dark (AMOLED) and Sleek Light Mode.
class AppColors {
  // Canvas & Surfaces (AMOLED Dark Defaults for backwards compatibility)
  static const Color background = Color(0xFF0B0F19);
  static const Color backgroundDeep = Color(0xFF07090E);
  static const Color card = Color(0xFF111827);
  static const Color cardElevated = Color(0xFF171E2E);
  static const Color border = Color(0xFF1F2937);
  static const Color borderSubtle = Color(0xFF161F30);

  // Stitch Semantic Surface Hierarchy
  static const Color surfaceContainerLowest = Color(0xFF0A0E18);
  static const Color surfaceContainerLow = Color(0xFF171B26);
  static const Color surfaceContainer = Color(0xFF1C1F2A);
  static const Color surfaceContainerHigh = Color(0xFF262A35);
  static const Color surfaceContainerHighest = Color(0xFF313540);
  static const Color outlineVariant = Color(0xFF464554);

  // Brand Accents & Aliases
  static const Color primary = Color(0xFF6366F1); // Kinetic Indigo
  static const Color kineticIndigo = Color(0xFF6366F1);
  static const Color primaryHover = Color(0xFF4F46E5);
  static const Color primaryGlow = Color(0x336366F1);

  static const Color emerald = Color(0xFF10B981); // Neon Emerald (GPS / HR / Done)
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x3310B981);

  static const Color amber = Color(0xFFF59E0B); // Amber Flame (Calories / PR)
  static const Color amberFlame = Color(0xFFF59E0B);
  static const Color amberGlow = Color(0x33F59E0B);

  static const Color destructive = Color(0xFFEF4444); // Error / Circuit Breaker
  static const Color destructiveCoral = Color(0xFFEF4444);
  static const Color destructiveGlow = Color(0x33EF4444);

  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF4B5563);

  /// Resolves the current theme palette (Light or Dark) from the active BuildContext.
  static AppColorsExtension of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.light
        ? AppColorsExtension.light
        : AppColorsExtension.dark;
  }
}

/// Static Light Palette (Sleek High-Performance Athletic Design)
class AppLightColors {
  static const Color background = Color(0xFFF8FAFC); // Slate 50 Porcelain
  static const Color backgroundDeep = Color(0xFFF1F5F9); // Slate 100
  static const Color card = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color cardElevated = Color(0xFFF8FAFC); // Elevated Tile Surface
  static const Color border = Color(0xFFE2E8F0); // Slate 200 Hairline Border
  static const Color borderSubtle = Color(0xFFEEF2F6); // Slate 150

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainer = Color(0xFFF1F5F9);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  static const Color primary = Color(0xFF4F46E5); // Deep Kinetic Indigo
  static const Color kineticIndigo = Color(0xFF4F46E5);
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color primaryGlow = Color(0x224F46E5);

  static const Color emerald = Color(0xFF059669); // Vivid Emerald (High-contrast on light)
  static const Color neonEmerald = Color(0xFF059669);
  static const Color emeraldGlow = Color(0x22059669);

  static const Color amber = Color(0xFFD97706); // Energetic Gold / Amber
  static const Color amberFlame = Color(0xFFD97706);
  static const Color amberGlow = Color(0x22D97706);

  static const Color destructive = Color(0xFFDC2626); // Alert Red
  static const Color destructiveCoral = Color(0xFFDC2626);
  static const Color destructiveGlow = Color(0x22DC2626);

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 Obsidian
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textSubtle = Color(0xFF94A3B8); // Slate 400
}

/// Static Dark Palette (AMOLED Stealth)
class AppDarkColors {
  static const Color background = Color(0xFF0B0F19);
  static const Color backgroundDeep = Color(0xFF07090E);
  static const Color card = Color(0xFF111827);
  static const Color cardElevated = Color(0xFF171E2E);
  static const Color border = Color(0xFF1F2937);
  static const Color borderSubtle = Color(0xFF161F30);

  static const Color surfaceContainerLowest = Color(0xFF0A0E18);
  static const Color surfaceContainerLow = Color(0xFF171B26);
  static const Color surfaceContainer = Color(0xFF1C1F2A);
  static const Color surfaceContainerHigh = Color(0xFF262A35);
  static const Color surfaceContainerHighest = Color(0xFF313540);
  static const Color outlineVariant = Color(0xFF464554);

  static const Color primary = Color(0xFF6366F1);
  static const Color kineticIndigo = Color(0xFF6366F1);
  static const Color primaryHover = Color(0xFF4F46E5);
  static const Color primaryGlow = Color(0x336366F1);

  static const Color emerald = Color(0xFF10B981);
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x3310B981);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberFlame = Color(0xFFF59E0B);
  static const Color amberGlow = Color(0x33F59E0B);

  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveCoral = Color(0xFFEF4444);
  static const Color destructiveGlow = Color(0x33EF4444);

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF4B5563);
}

/// ThemeExtension allowing Flutter widgets to read context-dependent semantic colors
/// with smooth cross-fade animation when switching themes.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color backgroundDeep;
  final Color card;
  final Color cardElevated;
  final Color border;
  final Color borderSubtle;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outlineVariant;
  final Color primary;
  final Color kineticIndigo;
  final Color primaryHover;
  final Color primaryGlow;
  final Color emerald;
  final Color neonEmerald;
  final Color emeraldGlow;
  final Color amber;
  final Color amberFlame;
  final Color amberGlow;
  final Color destructive;
  final Color destructiveCoral;
  final Color destructiveGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textSubtle;
  final bool isDark;

  const AppColorsExtension({
    required this.background,
    required this.backgroundDeep,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.borderSubtle,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outlineVariant,
    required this.primary,
    required this.kineticIndigo,
    required this.primaryHover,
    required this.primaryGlow,
    required this.emerald,
    required this.neonEmerald,
    required this.emeraldGlow,
    required this.amber,
    required this.amberFlame,
    required this.amberGlow,
    required this.destructive,
    required this.destructiveCoral,
    required this.destructiveGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.isDark,
  });

  static const AppColorsExtension light = AppColorsExtension(
    background: AppLightColors.background,
    backgroundDeep: AppLightColors.backgroundDeep,
    card: AppLightColors.card,
    cardElevated: AppLightColors.cardElevated,
    border: AppLightColors.border,
    borderSubtle: AppLightColors.borderSubtle,
    surfaceContainerLowest: AppLightColors.surfaceContainerLowest,
    surfaceContainerLow: AppLightColors.surfaceContainerLow,
    surfaceContainer: AppLightColors.surfaceContainer,
    surfaceContainerHigh: AppLightColors.surfaceContainerHigh,
    surfaceContainerHighest: AppLightColors.surfaceContainerHighest,
    outlineVariant: AppLightColors.outlineVariant,
    primary: AppLightColors.primary,
    kineticIndigo: AppLightColors.kineticIndigo,
    primaryHover: AppLightColors.primaryHover,
    primaryGlow: AppLightColors.primaryGlow,
    emerald: AppLightColors.emerald,
    neonEmerald: AppLightColors.neonEmerald,
    emeraldGlow: AppLightColors.emeraldGlow,
    amber: AppLightColors.amber,
    amberFlame: AppLightColors.amberFlame,
    amberGlow: AppLightColors.amberGlow,
    destructive: AppLightColors.destructive,
    destructiveCoral: AppLightColors.destructiveCoral,
    destructiveGlow: AppLightColors.destructiveGlow,
    textPrimary: AppLightColors.textPrimary,
    textSecondary: AppLightColors.textSecondary,
    textMuted: AppLightColors.textMuted,
    textSubtle: AppLightColors.textSubtle,
    isDark: false,
  );

  static const AppColorsExtension dark = AppColorsExtension(
    background: AppDarkColors.background,
    backgroundDeep: AppDarkColors.backgroundDeep,
    card: AppDarkColors.card,
    cardElevated: AppDarkColors.cardElevated,
    border: AppDarkColors.border,
    borderSubtle: AppDarkColors.borderSubtle,
    surfaceContainerLowest: AppDarkColors.surfaceContainerLowest,
    surfaceContainerLow: AppDarkColors.surfaceContainerLow,
    surfaceContainer: AppDarkColors.surfaceContainer,
    surfaceContainerHigh: AppDarkColors.surfaceContainerHigh,
    surfaceContainerHighest: AppDarkColors.surfaceContainerHighest,
    outlineVariant: AppDarkColors.outlineVariant,
    primary: AppDarkColors.primary,
    kineticIndigo: AppDarkColors.kineticIndigo,
    primaryHover: AppDarkColors.primaryHover,
    primaryGlow: AppDarkColors.primaryGlow,
    emerald: AppDarkColors.emerald,
    neonEmerald: AppDarkColors.neonEmerald,
    emeraldGlow: AppDarkColors.emeraldGlow,
    amber: AppDarkColors.amber,
    amberFlame: AppDarkColors.amberFlame,
    amberGlow: AppDarkColors.amberGlow,
    destructive: AppDarkColors.destructive,
    destructiveCoral: AppDarkColors.destructiveCoral,
    destructiveGlow: AppDarkColors.destructiveGlow,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textMuted: AppDarkColors.textMuted,
    textSubtle: AppDarkColors.textSubtle,
    isDark: true,
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? backgroundDeep,
    Color? card,
    Color? cardElevated,
    Color? border,
    Color? borderSubtle,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? outlineVariant,
    Color? primary,
    Color? kineticIndigo,
    Color? primaryHover,
    Color? primaryGlow,
    Color? emerald,
    Color? neonEmerald,
    Color? emeraldGlow,
    Color? amber,
    Color? amberFlame,
    Color? amberGlow,
    Color? destructive,
    Color? destructiveCoral,
    Color? destructiveGlow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textSubtle,
    bool? isDark,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      backgroundDeep: backgroundDeep ?? this.backgroundDeep,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primary: primary ?? this.primary,
      kineticIndigo: kineticIndigo ?? this.kineticIndigo,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      emerald: emerald ?? this.emerald,
      neonEmerald: neonEmerald ?? this.neonEmerald,
      emeraldGlow: emeraldGlow ?? this.emeraldGlow,
      amber: amber ?? this.amber,
      amberFlame: amberFlame ?? this.amberFlame,
      amberGlow: amberGlow ?? this.amberGlow,
      destructive: destructive ?? this.destructive,
      destructiveCoral: destructiveCoral ?? this.destructiveCoral,
      destructiveGlow: destructiveGlow ?? this.destructiveGlow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      backgroundDeep: Color.lerp(backgroundDeep, other.backgroundDeep, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      kineticIndigo: Color.lerp(kineticIndigo, other.kineticIndigo, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      neonEmerald: Color.lerp(neonEmerald, other.neonEmerald, t)!,
      emeraldGlow: Color.lerp(emeraldGlow, other.emeraldGlow, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberFlame: Color.lerp(amberFlame, other.amberFlame, t)!,
      amberGlow: Color.lerp(amberGlow, other.amberGlow, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveCoral: Color.lerp(destructiveCoral, other.destructiveCoral, t)!,
      destructiveGlow: Color.lerp(destructiveGlow, other.destructiveGlow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Convenience extensions on BuildContext to quickly access theme colors.
extension ThemeContextExtension on BuildContext {
  AppColorsExtension get colors => AppColors.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}


