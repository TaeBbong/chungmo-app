import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'dimens.dart';
import 'palette.dart';

abstract class DarkTheme {
  static ThemeData get theme {
    final Color textPrimary = Palette.grey100;
    final Color textSecondary = Palette.grey400;
    final Color surface = Palette.grey900;
    final Color surfaceMuted = Palette.grey850;

    final ColorScheme colorScheme = ColorScheme.dark(
      primary: Palette.burgundy200,
      onPrimary: Palette.grey900,
      primaryContainer: Palette.burgundy600,
      onPrimaryContainer: Palette.burgundy100,
      secondary: Palette.beige,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outlineVariant: Palette.grey800,
      error: Palette.error,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      primaryColor: Palette.burgundy,
      scaffoldBackgroundColor: surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        headlineMedium: AppTypography.display.copyWith(color: textPrimary),
        headlineSmall: AppTypography.headline.copyWith(color: textPrimary),
        titleMedium: AppTypography.title.copyWith(color: textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: textPrimary),
        bodyMedium: AppTypography.bodySmall.copyWith(color: textSecondary),
        bodySmall: AppTypography.caption.copyWith(color: Palette.grey500),
        labelLarge: AppTypography.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.burgundy,
          foregroundColor: Palette.white,
          disabledBackgroundColor: Palette.grey800,
          disabledForegroundColor: Palette.grey600,
          minimumSize: const Size.fromHeight(Dimens.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusLg),
          ),
          textStyle: AppTypography.label,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.burgundy600,
          foregroundColor: Palette.burgundy100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusMd),
          ),
          textStyle: AppTypography.label.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: AppTypography.label.copyWith(fontSize: 14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
        titleTextStyle: AppTypography.body.copyWith(color: textPrimary),
        subtitleTextStyle:
            AppTypography.bodySmall.copyWith(color: textSecondary),
        iconColor: textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: Palette.grey850,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceMuted,
        showDragHandle: true,
        dragHandleColor: Palette.grey700,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Dimens.radiusSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.grey200,
        contentTextStyle:
            AppTypography.bodySmall.copyWith(color: Palette.grey900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceMuted,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: textPrimary),
        contentTextStyle:
            AppTypography.body.copyWith(color: textSecondary),
      ),
      iconTheme: IconThemeData(
        color: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: Dimens.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          borderSide: BorderSide(color: Palette.burgundy200, width: 1.5),
        ),
        hintStyle: AppTypography.bodySmall.copyWith(color: Palette.grey600),
      ),
    );
  }
}
