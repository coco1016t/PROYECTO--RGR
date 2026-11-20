import 'package:flutter/material.dart';

import '../services/sesion_service.dart';

class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final ValueChanged<int>? onCambiarTab;
  final String rutaActual;

  const UserDrawer({
    super.key,
    required this.usuario,
    this.onCambiarTab,
    this.rutaActual = '/blog',
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: _UserNavigationContent(
        usuario: usuario,
        onCambiarTab: onCambiarTab,
        isDrawer: true,
        rutaActual: rutaActual,
      ),
    );
  }
}

class UserNavigationPanel extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final int tabActual;
  final ValueChanged<int> onCambiarTab;

  const UserNavigationPanel({
    super.key,
    required this.usuario,
    required this.tabActual,
    required this.onCambiarTab,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 224,
      child: Material(
        color: scheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: scheme.outline.withValues(alpha: .5)),
            ),
          ),
          child: _UserNavigationContent(
            usuario: usuario,
            tabActual: tabActual,
            onCambiarTab: onCambiarTab,
            isDrawer: false,
            rutaActual: '/blog',
          ),
        ),
      ),
    );
  }
}

class _UserNavigationContent extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final int? tabActual;
  final ValueChanged<int>? onCambiarTab;
  final bool isDrawer;
  final String rutaActual;

  const _UserNavigationContent({
    required this.usuario,
    this.tabActual,
    required this.onCambiarTab,
    required this.isDrawer,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Usuario';
  String get correo => usuario['mail']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isDrawer)
                  UserAccountsDrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(color: scheme.primary),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: scheme.surface,
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: scheme.primary,
                        size: 30,
                      ),
                    ),
                    accountName:
                        Text(nombre, style: TextStyle(color: scheme.onPrimary)),
                    accountEmail:
                        Text(correo, style: TextStyle(color: scheme.onPrimary)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 16, 26),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (correo.isNotEmpty)
                                Text(
                                  correo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        scheme.onSurface.withValues(alpha: .62),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onCambiarTab != null) ...[
                  _opcion(
                    context,
                    icono: Icons.dynamic_feed_outlined,
                    titulo: 'Inicio',
                    seleccionado: tabActual == 0,
                    onTap: () => _cambiarPestana(context, 0),
                  ),
                  _opcion(
                    context,
                    icono: Icons.article_outlined,
                    titulo: 'Mis publicaciones',
                    seleccionado: tabActual == 1,
                    onTap: () => _cambiarPestana(context, 1),
                  ),
                ],
                _opcion(
                  context,
                  icono: Icons.forum_outlined,
                  titulo: 'Mensajes',
                  seleccionado: false,
                  onTap: () {
                    _cerrarDrawer(context);
                    Navigator.pushNamed(context, '/mensajes');
                  },
                ),
                _opcion(
                  context,
                  icono: Icons.map_outlined,
                  titulo: 'Mapa de lugares',
                  seleccionado: false,
                  onTap: () {
                    _cerrarDrawer(context);
                    Navigator.pushNamed(context, '/mapa');
                  },
                ),
                _opcion(
                  context,
                  icono: Icons.account_circle_outlined,
                  titulo: 'Mi perfil',
                  seleccionado: rutaActual == '/profile',
                  onTap: () {
                    _cerrarDrawer(context);
                    if (rutaActual != '/profile') {
                      Navigator.pushNamed(
                        context,
                        '/profile',
                        arguments: usuario,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(color: scheme.outline.withValues(alpha: .5), height: 1),
          ListTile(
            horizontalTitleGap: 12,
            minLeadingWidth: 24,
            leading:
                Icon(Icons.logout_rounded, color: scheme.onSecondaryContainer),
            title: Text(
              'Cerrar sesi\u00F3n',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            onTap: () {
              SesionService.instance.cerrar();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _cambiarPestana(BuildContext context, int indice) {
    _cerrarDrawer(context);
    onCambiarTab?.call(indice);
  }

  void _cerrarDrawer(BuildContext context) {
    if (isDrawer) Navigator.pop(context);
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      horizontalTitleGap: 12,
      minLeadingWidth: 24,
      leading: Icon(
        icono,
        color: seleccionado
            ? scheme.onSecondaryContainer
            : scheme.onSurface.withValues(alpha: .65),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          color: seleccionado ? scheme.onSecondaryContainer : scheme.onSurface,
          fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: seleccionado,
      selectedTileColor: scheme.secondaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      onTap: onTap,
    );
  }
}
