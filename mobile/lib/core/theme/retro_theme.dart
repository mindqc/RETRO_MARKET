import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';

/// Material 3 theme for RETRO MARKET (izithrift).
///
/// Built from the approved Cozy Vintage Editorial reference:
/// - Warm parchment linen canvas (#F6F1E9)
/// - Crisp white elevated cards with soft warm hairline borders (#E7DFD2)
/// - Deep Pine Green primary actions & burnt terracotta editorial CTAs
/// - Crimson price & active-navigation accents
class RetroTheme {
  RetroTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.pineBanner,
      onPrimary: AppColors.textLight,
      primaryContainer: AppColors.primaryForestGreenLight,
      onPrimaryContainer: AppColors.pineDeep,
      secondary: AppColors.ctaTerracotta,
      onSecondary: AppColors.textLight,
      tertiary: AppColors.starGold,
      onTertiary: AppColors.textCharcoal,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textCharcoal,
      error: AppColors.statusDanger,
      onError: AppColors.textLight,
      outline: AppColors.borderWarm,
      outlineVariant: AppColors.borderSubtle,
    );

    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
    );

    final roundedCardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvasParchment,
      fontFamily: AppTypography.fontBody,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textCharcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: DesignTokens.spaceLg,
        titleTextStyle: AppTypography.headingMedium,
        iconTheme: IconThemeData(color: AppColors.textCharcoal, size: 22),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pineDeep,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.borderWarm,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: pillShape,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ctaTerracotta,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.borderWarm,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          textStyle: AppTypography.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: pillShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pineDeep,
          backgroundColor: AppColors.surfaceCard,
          side: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
          textStyle: AppTypography.buttonMedium,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: pillShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pineDeep,
          textStyle: AppTypography.buttonMedium,
          shape: pillShape,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderWarm,
            width: DesignTokens.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.pineDeep,
            width: DesignTokens.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.statusDanger,
            width: DesignTokens.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.statusDanger,
            width: DesignTokens.borderMedium,
          ),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.pineDeep,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.pineDeep,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.borderWarm,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption.copyWith(
            color: selected ? AppColors.pineDeep : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.pineDeep : AppColors.textMuted,
          );
        }),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ctaTerracotta,
        foregroundColor: AppColors.textLight,
        elevation: 3,
        shape: StadiumBorder(),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pineBanner;
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
            return AppColors.pineBanner;
          }
          return AppColors.textMuted;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.surfaceCard;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.pineBanner;
          }
          return AppColors.borderWarm;
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: roundedCardShape,
        titleTextStyle: AppTypography.headingMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.pineDeep,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.pineBanner,
        linearTrackColor: AppColors.surfaceWarm,
        circularTrackColor: AppColors.surfaceWarm,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.pineBanner,
        selectionColor: Color(0x3324412E),
        selectionHandleColor: AppColors.pineBanner,
      ),
    );
  }
}
