import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDark ? 'Activar modo claro' : 'Activar modo oscuro',
      onPressed: () => AppTheme.darkMode.value = !AppTheme.darkMode.value,
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
