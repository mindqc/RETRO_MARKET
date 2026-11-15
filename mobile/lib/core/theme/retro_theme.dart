import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// RetroTheme provides the Material 3 light theme for RETRO MARKET (izithrift)
/// Embracing the Warm Editorial Archive aesthetic with terracotta and vintage paper tones.
class RetroTheme {
  RetroTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryTerracotta,
      onPrimary: AppColors.textLight,
      primaryContainer: AppColors.surfaceWarm,
      onPrimaryContainer: AppColors.primaryTerracottaDark,
      secondary: AppColors.secondaryPineGreen,
      onSecondary: AppColors.textLight,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textCharcoal,
      error: AppColors.statusDanger,
      onError: AppColors.textLight,
      outline: AppColors.borderWarm,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundCream,
      fontFamily: AppTypography.fontBody,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headingMedium,
        iconTheme: IconThemeData(color: AppColors.textCharcoal),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: const BorderSide(color: AppColors.borderWarm, width: DesignTokens.borderThin),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTerracotta,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTerracotta,
          side: const BorderSide(color: AppColors.primaryTerracotta, width: DesignTokens.borderThin),
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryTerracotta,
          textStyle: AppTypography.buttonMedium,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderWarm, width: DesignTokens.borderThin),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.borderWarm, width: DesignTokens.borderThin),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryTerracotta, width: DesignTokens.borderMedium),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.statusDanger, width: DesignTokens.borderThin),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.statusDanger, width: DesignTokens.borderMedium),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceWarm,
        labelStyle: AppTypography.caption.copyWith(color: AppColors.textCharcoal, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.borderWarm, width: DesignTokens.borderThin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusFull)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.surfaceWarm,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              color: AppColors.primaryTerracotta,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryTerracotta);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
