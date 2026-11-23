import 'package:flutter/material.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';

ThemeData buildStudySpaceTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? StudySpaceColors.dark : StudySpaceColors.light;

  final baseTextTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: c.inkPrimary,
      letterSpacing: -0.6,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: c.inkPrimary,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: c.inkPrimary,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: c.inkPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: c.inkPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: c.inkPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: c.inkSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: c.inkPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: c.inkSecondary,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: c.inkSecondary,
      letterSpacing: 0.5,
    ),
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.mint,
    onSecondary: c.onPrimary,
    error: c.danger,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.inkPrimary,
    outline: c.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: c.canvas,
    colorScheme: colorScheme,
    textTheme: baseTextTheme,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: c.inkPrimary,
      titleTextStyle: baseTextTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: baseTextTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.inkPrimary,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: c.border,
      thickness: 1,
      space: 1,
    ),
  );
}
