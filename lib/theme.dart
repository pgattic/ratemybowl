import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Colors.lightBlueAccent;

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).copyWith(
        onSurface: Colors.white,
        onBackground: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
      );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  static final TextTheme _baseLightTextTheme = GoogleFonts.quicksandTextTheme(
    ThemeData.light().textTheme,
  ).apply(bodyColor: Colors.white, displayColor: Colors.white);
  static final TextTheme _baseDarkTextTheme = GoogleFonts.quicksandTextTheme(
    ThemeData.dark().textTheme,
  );

  static TextTheme _boldTextTheme(TextTheme base) {
    TextStyle? makeBold(TextStyle? style) {
      if (style == null) return null;
      return GoogleFonts.quicksand(
        fontSize: style.fontSize,
        fontWeight: FontWeight.bold, // ensures bold variant
        color: style.color,
        letterSpacing: style.letterSpacing,
        height: style.height,
      );
    }

    return base.copyWith(
      displayLarge: makeBold(base.displayLarge),
      displayMedium: makeBold(base.displayMedium),
      displaySmall: makeBold(base.displaySmall),
      headlineLarge: makeBold(base.headlineLarge),
      headlineMedium: makeBold(base.headlineMedium),
      headlineSmall: makeBold(base.headlineSmall),
      titleLarge: makeBold(base.titleLarge),
      titleMedium: makeBold(base.titleMedium),
      titleSmall: makeBold(base.titleSmall),
      bodyLarge: makeBold(base.bodyLarge),
      bodyMedium: makeBold(base.bodyMedium),
      bodySmall: makeBold(base.bodySmall),
      labelLarge: makeBold(base.labelLarge),
      labelMedium: makeBold(base.labelMedium),
      labelSmall: makeBold(base.labelSmall),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme.copyWith(
        onSurface: Colors.white,
        primary: Colors.white,
      ),
      scaffoldBackgroundColor: _seedColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColor,
        foregroundColor: _lightColorScheme.onPrimary,
      ),
      textTheme: _boldTextTheme(_baseLightTextTheme),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: TextStyle(fontWeight: FontWeight.bold), // Add this
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        // Add this
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(
            255,
            38,
            117,
            153,
          ), // Text color matches background
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // Add this
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(),
      ),
      // Add this to make TextField text dark
      textSelectionTheme: TextSelectionThemeData(cursorColor: _seedColor),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: _seedColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColor,
        foregroundColor: _darkColorScheme.onPrimary,
      ),
      textTheme: _boldTextTheme(_baseDarkTextTheme),
    );
  }
}
