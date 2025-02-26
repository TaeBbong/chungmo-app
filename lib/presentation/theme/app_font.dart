import 'package:flutter/material.dart';

class AppFont {
  final String fontFamily;
  final Color fontColor;

  AppFont({required this.fontFamily, required this.fontColor});

  TextStyle get title => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: fontColor,
      );

  TextStyle get body => TextStyle(
        fontSize: 16,
        color: fontColor,
      );

  TextStyle get caption => TextStyle(
        fontSize: 14,
        color: fontColor.withValues(red: 0, blue: 0, green: 0, alpha: 0.7),
      );
}
