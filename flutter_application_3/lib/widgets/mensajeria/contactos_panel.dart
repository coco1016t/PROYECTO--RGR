import 'package:flutter/material.dart';

import '../../models/mensaje_model.dart';

class ContactosPanel extends StatelessWidget {
  final List<ConversacionMensajeria> conversaciones;
  final int? conversacionSeleccionadaId;
  final TextEditingController busquedaController;
  final bool cargando;
  final String? error;
  final String Function(ContactoMensajeria) nombreVisible;
  final String Function(DateTime?) hora;
  final VoidCallback onNuevaConversacion;
  final ValueChanged<ConversacionMensajeria> onSeleccionarConversacion;
  final ValueChanged<String> onCambiarBusqueda;

  const ContactosPanel({
    super.key,
    required this.conversaciones,
    required this.conversacionSeleccionadaId,
    required this.busquedaController,
    required this.cargando,
    required this.error,
    required this.nombreVisible,
    required this.hora,
    required this.onNuevaConversacion,
    required this.onSeleccionarConversacion,
    required this.onCambiarBusqueda,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final consulta = busquedaController.text.trim().toLowerCase();
    final filtradas = conversaciones.where((conversacion) {
      return consulta.isEmpty ||
          conversacion.contacto.nombre.toLowerCase().contains(consulta) ||
          (conversacion.ultimoMensaje ?? '').toLowerCase().contains(consulta);
    }).toList();

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 10, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensajes',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tus conversaciones privadas',
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: .62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Buscar usuario para un nuevo chat',
                  onPressed: onNuevaConversacion,
                  icon: const Icon(Icons.edit_square),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: busquedaController,
              onChanged: onCambiarBusqueda,
              decoration: InputDecoration(
                hintText: 'Buscar en tus chats',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: busquedaController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          busquedaController.clear();
                          onCambiarBusqueda('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'No se pudieron actualizar los chats: $error',
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ),
          if (cargando && conversaciones.isEmpty && error == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filtradas.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 38,
                        color: scheme.primary.withValues(alpha: .75),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        conversaciones.isEmpty
                            ? 'Aún no tienes chats.'
                            : 'No encontramos chats con ese texto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (conversaciones.isEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Usa el botón de nuevo chat o Enviar mensaje en una publicación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: .62),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _SectionHeading(title: 'Chats', count: filtradas.length),
                  for (final conversacion in filtradas)
                    _ConversationTile(
                      conversacion: conversacion,
                      nombre: nombreVisible(conversacion.contacto),
                      hora: hora(conversacion.fechaUltimoMensaje),
                      seleccionado:
                          conversacionSeleccionadaId == conversacion.id,
                      onTap: () => onSeleccionarConversacion(conversacion),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeading({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: .58),
                letterSpacing: .8,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: .5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversacionMensajeria conversacion;
  final String nombre;
  final String hora;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversacion,
    required this.nombre,
    required this.hora,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendientes = conversacion.noLeidos;

    return ListTile(
      selected: seleccionado,
      selectedTileColor: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _ContactAvatar(name: conversacion.contacto.nombre),
      title: Text(
        nombre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: pendientes > 0 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conversacion.ultimoMensaje ?? 'Chat iniciado',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: pendientes > 0 ? .86 : .6),
          fontWeight: pendientes > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            hora,
            style: TextStyle(
              color: pendientes > 0
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: .56),
              fontSize: 10,
              fontWeight: pendientes > 0 ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          if (pendientes > 0) ...[
            const SizedBox(height: 5),
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pendientes > 99 ? '99+' : '$pendientes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final String name;

  const _ContactAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.primary,
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
