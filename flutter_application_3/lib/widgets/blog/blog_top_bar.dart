import 'package:flutter/material.dart';

import '../theme_mode_button.dart';

class BlogTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool hasDrawer;
  final VoidCallback onRefresh;

  const BlogTopBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.hasDrawer,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showTopSearch = width >= 900;
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 68,
      automaticallyImplyLeading: hasDrawer,
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
            ),
            child: Icon(Icons.forum_rounded, color: scheme.primary, size: 19),
          ),
          const SizedBox(width: 11),
          Flexible(
            flex: showTopSearch ? 0 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RGR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'Comunidad',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: .62),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showTopSearch) ...[
            const SizedBox(width: 24),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (width * .4).clamp(460.0, 980.0).toDouble(),
                ),
                child: BlogSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  dense: true,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        const ThemeModeButton(),
        IconButton(
          tooltip: 'Actualizar publicaciones',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: ColoredBox(
          color: scheme.primary,
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ),
    );
  }
}

class BlogSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool dense;

  const BlogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: scheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar publicaciones o temas',
        fillColor: scheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        isDense: dense,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: .7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
    );
  }
}
