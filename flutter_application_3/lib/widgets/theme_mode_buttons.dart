import 'package:flutter/material.dart';

class ThemeModeButtons extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onLightMode;
  final VoidCallback onDarkMode;

  const ThemeModeButtons({
    super.key,
    required this.darkMode,
    required this.onLightMode,
    required this.onDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeButton(
          tooltip: 'Modo claro',
          icon: Icons.light_mode_outlined,
          selected: !darkMode,
          onPressed: onLightMode,
        ),
        _ModeButton(
          tooltip: 'Modo oscuro',
          icon: Icons.dark_mode_outlined,
          selected: darkMode,
          onPressed: onDarkMode,
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor:
              selected ? scheme.secondaryContainer : Colors.transparent,
          foregroundColor: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: .68),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
