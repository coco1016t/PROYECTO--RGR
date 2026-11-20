import 'package:flutter/material.dart';

import '../theme_mode_buttons.dart';

class BlogTopBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String userName;
  final bool darkMode;
  final bool showSidebar;
  final bool isAdmin;
  final VoidCallback onLightMode;
  final VoidCallback onDarkMode;
  final VoidCallback onMessages;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const BlogTopBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.userName,
    required this.darkMode,
    required this.showSidebar,
    required this.isAdmin,
    required this.onLightMode,
    required this.onDarkMode,
    required this.onMessages,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showDirectMessages = width >= 440;
    final showTopSearch = width >= 900;
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 68,
      automaticallyImplyLeading: !showSidebar || isAdmin,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RGR', style: TextStyle(letterSpacing: 1.1)),
              Text(
                'Comunidad',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: .62),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        if (showDirectMessages)
          IconButton(
            tooltip: 'Mensajes',
            onPressed: onMessages,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ThemeModeButtons(
          darkMode: darkMode,
          onLightMode: onLightMode,
          onDarkMode: onDarkMode,
        ),
        PopupMenuButton<String>(
          tooltip: 'Más opciones',
          onSelected: (value) {
            switch (value) {
              case 'messages':
                onMessages();
              case 'refresh':
                onRefresh();
              case 'logout':
                onLogout();
            }
          },
          itemBuilder: (context) => [
            if (!showDirectMessages)
              const PopupMenuItem(
                value: 'messages',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.chat_bubble_outline_rounded),
                  title: Text('Mensajes'),
                ),
              ),
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.refresh_rounded),
                title: Text('Actualizar'),
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded),
                title: Text('Cerrar sesi\u00F3n'),
              ),
            ),
          ],
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
