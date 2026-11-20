import 'package:flutter/material.dart';
import '../services/sesion_service.dart';

/// Barra lateral del usuario normal (misma estructura que AdminDrawer):
/// Inicio, Mis posts y Chats, con "Cerrar sesión" al final.
class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;

  /// Pestaña activa del blog: 0 = Todos, 1 = Mis posts.
  final int tabActual;

  /// Cambia de pestaña en BlogPage.
  final ValueChanged<int> onCambiarTab;

  const UserDrawer({
    super.key,
    required this.usuario,
    required this.tabActual,
    required this.onCambiarTab,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Usuario';
  String get correo => usuario['mail']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF08245C)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Color(0xFF08245C),
                  size: 34,
                ),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            ),
            _opcion(
              icono: Icons.home_outlined,
              titulo: 'Inicio',
              seleccionado: tabActual == 0,
              onTap: () {
                Navigator.pop(context);
                onCambiarTab(0);
              },
            ),
            _opcion(
              icono: Icons.article_outlined,
              titulo: 'Mis posts',
              seleccionado: tabActual == 1,
              onTap: () {
                Navigator.pop(context);
                onCambiarTab(1);
              },
            ),
            _opcion(
              icono: Icons.forum_outlined,
              titulo: 'Chats',
              seleccionado: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mensajes');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              horizontalTitleGap: 12,
              minLeadingWidth: 24,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
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

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return ListTile(
      // Icono pegado al texto (separación corta, como en el ejemplo).
      horizontalTitleGap: 12,
      minLeadingWidth: 24,
      leading: Icon(
        icono,
        color: seleccionado ? const Color(0xFF08245C) : null,
      ),
      title: Text(titulo),
      selected: seleccionado,
      onTap: onTap,
    );
  }
}