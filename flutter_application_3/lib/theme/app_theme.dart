import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const loginGreen = Color(0xFF527D7B);
    final accent = isDark ? const Color(0xFF9DCCC7) : loginGreen;
    final onAccent = isDark ? const Color(0xFF123734) : Colors.white;
    final background =
        isDark ? const Color(0xFF121C1B) : const Color(0xFFF7F9F8);
    final surface = isDark ? const Color(0xFF1C2928) : Colors.white;
    final text = isDark ? const Color(0xFFE8F2F0) : const Color(0xFF243341);
    final muted = isDark ? const Color(0xFFB3C8C6) : const Color(0xFF667483);
    final border = isDark ? const Color(0xFF3D5653) : const Color(0xFFDCE3E8);
    final accentSurface =
        isDark ? const Color(0xFF284744) : const Color(0xFFEEF5F4);
    final onAccentSurface =
        isDark ? const Color(0xFFC5E7E2) : const Color(0xFF355F5C);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: loginGreen,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: accentSurface,
      onPrimaryContainer: onAccentSurface,
      secondary: accent,
      onSecondary: onAccent,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      secondaryContainer: accentSurface,
      onSecondaryContainer: onAccentSurface,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: border),
    );
    final panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: border),
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
        iconTheme: IconThemeData(color: onAccentSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: panelShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: panelShape,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
      ),
    );
  }
}
