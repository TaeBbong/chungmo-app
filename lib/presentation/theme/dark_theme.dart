import 'package:flutter/material.dart';
import 'palette.dart';

abstract class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Palette.burgundy,
      scaffoldBackgroundColor: Palette.grey900,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Palette.beige, fontSize: 18),
        bodyMedium: TextStyle(color: Palette.grey300, fontSize: 16),
        bodySmall: TextStyle(color: Palette.grey400, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Palette.black,
        foregroundColor: Palette.beige,
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Palette.burgundy,
        textTheme: ButtonTextTheme.primary,
      ),
      iconTheme: IconThemeData(
        color: Palette.beige,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.grey800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Palette.beige),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Palette.beige, width: 2),
        ),
        hintStyle: TextStyle(color: Palette.grey500),
      ),
    );
  }
}
