import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// Material 3 theme for RETRO MARKET.
///
/// Forest Green is the primary interaction color. Warm Ivory and parchment
/// surfaces establish the editorial vintage marketplace visual language.
class RetroTheme {
  RetroTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryForestGreen,
      onPrimary: AppColors.textLight,
      primaryContainer: AppColors.primaryForestGreenLight,
      onPrimaryContainer: AppColors.primaryForestGreenDark,
      secondary: AppColors.primaryTerracotta,
      onSecondary: AppColors.textLight,
      tertiary: AppColors.accentVintageGold,
      onTertiary: AppColors.textCharcoal,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textCharcoal,
      error: AppColors.statusDanger,
      onError: AppColors.textLight,
      outline: AppColors.borderWarm,
      outlineVariant: AppColors.borderSubtle,
    );

    final shapeSmall = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmIvory,
      fontFamily: AppTypography.fontBody,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.warmIvory,
        foregroundColor: AppColors.textCharcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headingMedium,
        iconTheme: IconThemeData(color: AppColors.textCharcoal),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryForestGreen,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.borderSubtle,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shapeSmall,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryForestGreen,
          side: const BorderSide(
            color: AppColors.primaryForestGreen,
            width: DesignTokens.borderThin,
          ),
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shapeSmall,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryForestGreen,
          textStyle: AppTypography.buttonMedium,
          shape: shapeSmall,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.primaryForestGreen,
            width: DesignTokens.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.statusDanger,
            width: DesignTokens.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.statusDanger,
            width: DesignTokens.borderMedium,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceWarm,
        selectedColor: AppColors.primaryForestGreenLight,
        secondarySelectedColor: AppColors.primaryForestGreenLight,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.textCharcoal,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(
          color: AppColors.borderWarm,
          width: DesignTokens.borderThin,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.primaryForestGreenLight,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption.copyWith(
            color: selected
                ? AppColors.primaryForestGreen
                : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColors.primaryForestGreen
                : AppColors.textMuted,
          );
        }),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryForestGreen,
        foregroundColor: AppColors.textLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(DesignTokens.radiusLg),
          ),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryForestGreen;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryForestGreen;
          }
          return AppColors.textMuted;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryForestGreen;
          }
          return AppColors.textMuted;
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        titleTextStyle: AppTypography.headingMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusLg),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryForestGreen,
        linearTrackColor: AppColors.surfaceWarm,
        circularTrackColor: AppColors.surfaceWarm,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryForestGreen,
        selectionColor: Color(0x332D5A3C),
        selectionHandleColor: AppColors.primaryForestGreen,
      ),
    );
  }
}
