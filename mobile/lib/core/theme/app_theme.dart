import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

export 'app_scroll_behavior.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = Typography.material2021().white;

    final spaceGroteskTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final plusJakartaTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.emerald,
        tertiary: AppColors.amber,
        error: AppColors.destructive,
        surface: AppColors.card,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        // Headers & Tabular Numerals (Space Grotesk)
        displayLarge: spaceGroteskTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: spaceGroteskTheme.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: spaceGroteskTheme.displaySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: spaceGroteskTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: spaceGroteskTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineSmall: spaceGroteskTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: spaceGroteskTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Body & Controls (Plus Jakarta Sans)
        titleMedium: plusJakartaTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: plusJakartaTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: plusJakartaTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: plusJakartaTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: plusJakartaTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: plusJakartaTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: spaceGroteskTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        titleTextStyle: spaceGroteskTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: plusJakartaTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
        ),
      ),
      extensions: const [
        AppColorsExtension.dark,
      ],
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = Typography.material2021().black;

    final spaceGroteskTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final plusJakartaTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

    const colors = AppColorsExtension.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.light(
        primary: AppLightColors.primary,
        secondary: AppLightColors.emerald,
        tertiary: AppLightColors.amber,
        error: AppLightColors.destructive,
        surface: AppLightColors.card,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppLightColors.textPrimary,
        outline: AppLightColors.border,
        outlineVariant: AppLightColors.borderSubtle,
      ),
      extensions: const [
        AppColorsExtension.light,
      ],
      textTheme: TextTheme(
        // Headers & Tabular Numerals (Space Grotesk)
        displayLarge: spaceGroteskTheme.displayLarge?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: spaceGroteskTheme.displayMedium?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: spaceGroteskTheme.displaySmall?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: spaceGroteskTheme.headlineLarge?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: spaceGroteskTheme.headlineMedium?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineSmall: spaceGroteskTheme.headlineSmall?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: spaceGroteskTheme.titleLarge?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        // Body & Controls (Plus Jakarta Sans)
        titleMedium: plusJakartaTheme.titleMedium?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: plusJakartaTheme.titleSmall?.copyWith(
          color: AppLightColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: plusJakartaTheme.bodyLarge?.copyWith(
          color: AppLightColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: plusJakartaTheme.bodyMedium?.copyWith(
          color: AppLightColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: plusJakartaTheme.bodySmall?.copyWith(
          color: AppLightColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: plusJakartaTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: spaceGroteskTheme.labelSmall?.copyWith(
          color: AppLightColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        titleTextStyle: spaceGroteskTheme.titleLarge?.copyWith(
          color: AppLightColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        iconTheme: const IconThemeData(color: AppLightColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppLightColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: plusJakartaTheme.bodyMedium?.copyWith(color: AppLightColors.textMuted),
        prefixIconColor: AppLightColors.textMuted,
        suffixIconColor: AppLightColors.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppLightColors.destructive, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppLightColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppLightColors.border, width: 1),
        ),
      ),
    );
  }
}

