import 'package:flutter/material.dart';

class BlogTheme {
  const BlogTheme._();

  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);

  static ThemeData forMode(bool darkMode) {
    final brightness = darkMode ? Brightness.dark : Brightness.light;
    final accent = darkMode ? const Color(0xFFB7464D) : const Color(0xFFB7474E);
    final background =
        darkMode ? const Color(0xFF151719) : const Color(0xFFF3F5F5);
    final surface =
        darkMode ? const Color(0xFF202326) : const Color(0xFFFFFFFF);
    final text = darkMode ? const Color(0xFFF1F2F3) : const Color(0xFF20272B);
    final muted = darkMode ? const Color(0xFFA5AAAE) : const Color(0xFF697378);
    final border = darkMode ? const Color(0xFF363B3F) : const Color(0xFFDFE4E5);
    final accentSurface =
        darkMode ? const Color(0xFF402829) : const Color(0xFFF7E8E7);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      outline: border,
      secondaryContainer: accentSurface,
      onSecondaryContainer: accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkMode ? const Color(0xFF292D30) : const Color(0xFFEEF1F1),
        hintStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
