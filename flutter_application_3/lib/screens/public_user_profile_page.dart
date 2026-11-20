import 'package:flutter/material.dart';

import '../models/public_user_profile_model.dart';
import '../services/user_service.dart';
import '../theme/blog_theme.dart';
import '../widgets/public_profile/public_user_post_card.dart';

class PublicUserProfilePage extends StatefulWidget {
  final int userId;
  final String initialName;

  const PublicUserProfilePage({
    super.key,
    required this.userId,
    required this.initialName,
  });

  @override
  State<PublicUserProfilePage> createState() => _PublicUserProfilePageState();
}

class _PublicUserProfilePageState extends State<PublicUserProfilePage> {
  final UserService _userService = UserService();
  late Future<PublicUserProfileModel> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = _userService.obtenerPerfilPublico(widget.userId);
  }

  void _recargar() {
    setState(() {
      _perfil = _userService.obtenerPerfilPublico(widget.userId);
    });
  }

  Widget _barraSeccion(BuildContext context, String titulo) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        titulo,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<PublicUserProfileModel>(
      future: _perfil,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No se pudo cargar el perfil: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _recargar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final perfil = snapshot.data!;
        final inicial = perfil.nombre.trim().isEmpty
            ? '?'
            : perfil.nombre.trim()[0].toUpperCase();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline.withValues(alpha: .6)),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.primary,
                    child: Text(
                      inicial,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Miembro de la comunidad',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: .65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _barraSeccion(context, 'Datos públicos'),
            Container(
              color: scheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _dato(context, 'Nombre', perfil.nombre),
                  Divider(color: scheme.outline),
                  _dato(
                    context,
                    'Publicaciones',
                    '${perfil.publicaciones.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _barraSeccion(
              context,
              'Publicaciones (${perfil.publicaciones.length})',
            ),
            if (perfil.publicaciones.isEmpty)
              Container(
                color: scheme.surface,
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Este usuario todavía no tiene publicaciones.',
                  style:
                      TextStyle(color: scheme.onSurface.withValues(alpha: .7)),
                ),
              )
            else
              for (final post in perfil.publicaciones)
                PublicUserPostCard(post: post),
          ],
        );
      },
    );
  }

  Widget _dato(BuildContext context, String etiqueta, String valor) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: .65)),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BlogTheme.darkMode,
      builder: (context, darkMode, _) => Theme(
        data: BlogTheme.forMode(darkMode),
        child: Scaffold(
          appBar: AppBar(title: Text(widget.initialName)),
          body: _contenido(context),
        ),
      ),
    );
  }
}
