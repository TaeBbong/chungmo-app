import 'package:flutter/material.dart';
import 'palette.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Palette.burgundy,
      scaffoldBackgroundColor: Palette.white,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Palette.grey900, fontSize: 18),
        bodyMedium: TextStyle(color: Palette.grey800, fontSize: 16),
        bodySmall: TextStyle(color: Palette.grey700, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.burgundy,
        foregroundColor: Palette.white,
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Palette.burgundy,
        textTheme: ButtonTextTheme.primary,
      ),
      iconTheme: IconThemeData(
        color: Palette.burgundy,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Palette.burgundy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Palette.burgundy, width: 2),
        ),
        hintStyle: TextStyle(color: Palette.grey500),
      ),
    );
  }
}
