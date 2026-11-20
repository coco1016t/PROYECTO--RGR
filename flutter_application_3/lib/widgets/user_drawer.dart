import 'package:flutter/material.dart';

import '../services/sesion_service.dart';

const Color _menuSurface = Color(0xFFFFFFFF);
const Color _menuText = Color(0xFF243341);
const Color _menuMuted = Color(0xFF667483);
const Color _menuAccent = Color(0xFF527D7B);
const Color _menuSelected = Color(0xFFEEF5F4);
const Color _menuBorder = Color(0xFFDCE3E8);

/// Menú desplegable del usuario normal para móvil y tablet estrecha.
class UserDrawer extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final int tabActual;
  final ValueChanged<int> onCambiarTab;

  const UserDrawer({
    super.key,
    required this.usuario,
    required this.tabActual,
    required this.onCambiarTab,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _menuSurface,
      child: _UserNavigationContent(
        usuario: usuario,
        tabActual: tabActual,
        onCambiarTab: onCambiarTab,
        isDrawer: true,
      ),
    );
  }
}

/// Presentación persistente del mismo menú para el ancho de escritorio.
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
    return SizedBox(
      width: 216,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _menuSurface,
          border: Border(right: BorderSide(color: _menuBorder)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: _UserNavigationContent(
            usuario: usuario,
            tabActual: tabActual,
            onCambiarTab: onCambiarTab,
            isDrawer: false,
          ),
        ),
      ),
    );
  }
}

class _UserNavigationContent extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final int tabActual;
  final ValueChanged<int> onCambiarTab;
  final bool isDrawer;

  const _UserNavigationContent({
    required this.usuario,
    required this.tabActual,
    required this.onCambiarTab,
    required this.isDrawer,
  });

  String get nombre => usuario['nom_usr']?.toString() ?? 'Usuario';
  String get correo => usuario['mail']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          if (isDrawer)
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(color: _menuAccent),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: _menuAccent, size: 34),
              ),
              accountName: Text(nombre),
              accountEmail: Text(correo),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 16, 24),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: _menuSelected,
                    child: Icon(Icons.person_outline, color: _menuAccent),
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
                          style: const TextStyle(
                            color: _menuText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (correo.isNotEmpty)
                          Text(
                            correo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _menuMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _opcion(
            icono: Icons.home_outlined,
            titulo: 'Inicio',
            seleccionado: tabActual == 0,
            onTap: () => _cambiarPestana(context, 0),
          ),
          _opcion(
            icono: Icons.article_outlined,
            titulo: 'Mis posts',
            seleccionado: tabActual == 1,
            onTap: () => _cambiarPestana(context, 1),
          ),
          _opcion(
            icono: Icons.forum_outlined,
            titulo: 'Chats',
            seleccionado: false,
            onTap: () {
              _cerrarDrawer(context);
              Navigator.pushNamed(context, '/mensajes');
            },
          ),
          const Spacer(),
          const Divider(color: _menuBorder, height: 1),
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
    );
  }

  void _cambiarPestana(BuildContext context, int indice) {
    _cerrarDrawer(context);
    onCambiarTab(indice);
  }

  void _cerrarDrawer(BuildContext context) {
    if (isDrawer) Navigator.pop(context);
  }

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return ListTile(
      horizontalTitleGap: 12,
      minLeadingWidth: 24,
      leading: Icon(
        icono,
        color: seleccionado ? _menuAccent : _menuMuted,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          color: seleccionado ? _menuAccent : _menuText,
          fontWeight: seleccionado ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: seleccionado,
      selectedTileColor: _menuSelected,
      onTap: onTap,
    );
  }
}
