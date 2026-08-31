// CupertinoPageTransitionsBuilder moved out of material in Flutter 3.47.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'dimens.dart';
import 'palette.dart';

abstract class LightTheme {
  static ThemeData get theme {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: Palette.burgundy,
      onPrimary: Palette.white,
      primaryContainer: Palette.burgundy50,
      onPrimaryContainer: Palette.burgundy,
      secondary: Palette.burgundy,
      surface: Palette.surface,
      onSurface: Palette.textPrimary,
      onSurfaceVariant: Palette.textSecondary,
      outlineVariant: Palette.grey200,
      error: Palette.error,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      primaryColor: Palette.burgundy,
      scaffoldBackgroundColor: Palette.surface,
      splashFactory: InkSparkle.splashFactory,
      // iOS-style horizontal slide on both platforms, Toss-like.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      textTheme: TextTheme(
        headlineMedium: AppTypography.display.copyWith(color: Palette.textPrimary),
        headlineSmall: AppTypography.headline.copyWith(color: Palette.textPrimary),
        titleMedium: AppTypography.title.copyWith(color: Palette.textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: Palette.textPrimary),
        bodyMedium: AppTypography.bodySmall.copyWith(color: Palette.textSecondary),
        bodySmall: AppTypography.caption.copyWith(color: Palette.textTertiary),
        labelLarge: AppTypography.label,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.surface,
        foregroundColor: Palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: Palette.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.burgundy,
          foregroundColor: Palette.white,
          disabledBackgroundColor: Palette.grey200,
          disabledForegroundColor: Palette.grey400,
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
          backgroundColor: Palette.burgundy50,
          foregroundColor: Palette.burgundy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusMd),
          ),
          textStyle: AppTypography.label.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.textSecondary,
          textStyle: AppTypography.label.copyWith(fontSize: 14),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Dimens.screenPadding),
        titleTextStyle: AppTypography.body.copyWith(color: Palette.textPrimary),
        subtitleTextStyle:
            AppTypography.bodySmall.copyWith(color: Palette.textSecondary),
        iconColor: Palette.textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: Palette.grey150,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Palette.surface,
        showDragHandle: true,
        dragHandleColor: Palette.grey250,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Dimens.radiusSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.grey800,
        contentTextStyle:
            AppTypography.bodySmall.copyWith(color: Palette.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXl),
        ),
        titleTextStyle: AppTypography.title.copyWith(color: Palette.textPrimary),
        contentTextStyle:
            AppTypography.body.copyWith(color: Palette.textSecondary),
      ),
      iconTheme: IconThemeData(
        color: Palette.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: Dimens.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          borderSide: BorderSide(color: Palette.burgundy, width: 1.5),
        ),
        hintStyle: AppTypography.bodySmall.copyWith(color: Palette.grey600),
      ),
    );
  }
}
