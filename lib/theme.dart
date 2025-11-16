import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Colors.lightBlueAccent;

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  static final TextTheme _baseLightTextTheme = GoogleFonts.quicksandTextTheme();
  static final TextTheme _baseDarkTextTheme = GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme);

  static TextTheme _boldTextTheme(TextTheme base) {
    TextStyle? makeBold(TextStyle? style) =>
        style?.copyWith(fontWeight: FontWeight.bold);

    return base.copyWith(
      displayLarge:   makeBold(base.displayLarge),
      displayMedium:  makeBold(base.displayMedium),
      displaySmall:   makeBold(base.displaySmall),
      headlineLarge:  makeBold(base.headlineLarge),
      headlineMedium: makeBold(base.headlineMedium),
      headlineSmall:  makeBold(base.headlineSmall),
      titleLarge:     makeBold(base.titleLarge),
      titleMedium:    makeBold(base.titleMedium),
      titleSmall:     makeBold(base.titleSmall),
      bodyLarge:      makeBold(base.bodyLarge),
      bodyMedium:     makeBold(base.bodyMedium),
      bodySmall:      makeBold(base.bodySmall),
      labelLarge:     makeBold(base.labelLarge),
      labelMedium:    makeBold(base.labelMedium),
      labelSmall:     makeBold(base.labelSmall),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: _seedColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColor,
        foregroundColor: _lightColorScheme.onPrimary,
      ),
      textTheme: _boldTextTheme(_baseLightTextTheme),
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
