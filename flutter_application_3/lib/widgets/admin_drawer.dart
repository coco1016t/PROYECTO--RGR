import 'package:flutter/material.dart';

import '../services/sesion_service.dart';

class AdminDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String rutaActual;

  const AdminDrawer({
    super.key,
    required this.usuario,
    required this.rutaActual,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Administrador';
  String get correo => usuario['mail']?.toString() ?? '';

  void _navegar(BuildContext context, String ruta) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (ruta == rutaActual) return;
    if (ruta == '/mapa') {
      navigator.pushNamed(ruta);
      return;
    }
    navigator.pushReplacementNamed(
      ruta,
      arguments: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: scheme.primary),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: scheme.surface,
                      child: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: scheme.primary,
                        size: 32,
                      ),
                    ),
                    accountName:
                        Text(nombre, style: TextStyle(color: scheme.onPrimary)),
                    accountEmail:
                        Text(correo, style: TextStyle(color: scheme.onPrimary)),
                  ),
                  _opcion(
                    context,
                    Icons.people_alt_outlined,
                    'Gestión de usuarios',
                    '/users',
                  ),
                  _opcion(
                      context, Icons.forum_outlined, 'Mensajes', '/mensajes'),
                  _opcion(
                      context, Icons.map_outlined, 'Mapa de lugares', '/mapa'),
                  _opcion(
                    context,
                    Icons.person_add_alt_1_outlined,
                    'Registrar usuario',
                    '/register',
                  ),
                  _opcion(context, Icons.post_add_outlined, 'Agregar blog',
                      '/add-blog'),
                  _opcion(
                    context,
                    Icons.account_circle_outlined,
                    'Mi perfil',
                    '/profile',
                  ),
                ],
              ),
            ),
            Divider(color: scheme.outline.withValues(alpha: .5), height: 1),
            ListTile(
              leading: Icon(Icons.logout_rounded,
                  color: scheme.onSecondaryContainer),
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
      ),
    );
  }

  Widget _opcion(
    BuildContext context,
    IconData icono,
    String titulo,
    String ruta,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final seleccionado = ruta == rutaActual;

    return ListTile(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => _navegar(context, ruta),
    );
  }
}
