class ContactoMensajeria {
  final int id;
  final String nombre;

  const ContactoMensajeria({required this.id, required this.nombre});

  factory ContactoMensajeria.fromJson(Map<String, dynamic> json) {
    return ContactoMensajeria(
      id: (json['id_usr'] as num).toInt(),
      nombre: json['nom_usr']?.toString() ?? 'Usuario',
    );
  }
}

class ConversacionMensajeria {
  final int id;
  final ContactoMensajeria contacto;
  final String? ultimoMensaje;
  final DateTime? fechaUltimoMensaje;
  final int noLeidos;

  const ConversacionMensajeria({
    required this.id,
    required this.contacto,
    required this.ultimoMensaje,
    required this.fechaUltimoMensaje,
    required this.noLeidos,
  });

  factory ConversacionMensajeria.fromJson(Map<String, dynamic> json) {
    final contactoJson = json['contacto'] as Map<String, dynamic>;
    final fecha = json['fecha_ultimo_mensaje']?.toString();
    return ConversacionMensajeria(
      id: (json['id_conversacion'] as num).toInt(),
      contacto: ContactoMensajeria.fromJson(contactoJson),
      ultimoMensaje: json['ultimo_mensaje']?.toString(),
      fechaUltimoMensaje:
          fecha == null ? null : DateTime.tryParse(fecha)?.toLocal(),
      noLeidos: (json['no_leidos'] as num?)?.toInt() ?? 0,
    );
  }
}

class MensajeChat {
  final int id;
  final int conversacionId;
  final int emisorId;
  final String contenido;
  final DateTime fechaEnvio;

  const MensajeChat({
    required this.id,
    required this.conversacionId,
    required this.emisorId,
    required this.contenido,
    required this.fechaEnvio,
  });

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    final fecha = DateTime.tryParse(json['fecha_envio'].toString());
    return MensajeChat(
      id: (json['id_mensaje'] as num).toInt(),
      conversacionId: (json['id_conversacion'] as num).toInt(),
      emisorId: (json['emisor_id'] as num).toInt(),
      contenido: json['contenido']?.toString() ?? '',
      fechaEnvio: fecha?.toLocal() ?? DateTime.now(),
    );
  }
}

class PaginaMensajes {
  final List<MensajeChat> mensajes;
  final bool hayMasAnteriores;
  final bool hayMasNuevos;

  const PaginaMensajes({
    required this.mensajes,
    required this.hayMasAnteriores,
    required this.hayMasNuevos,
  });

  factory PaginaMensajes.fromJson(Map<String, dynamic> json) {
    final filas = json['mensajes'] as List<dynamic>? ?? const [];
    return PaginaMensajes(
      mensajes: filas
          .map(
            (fila) => MensajeChat.fromJson(fila as Map<String, dynamic>),
          )
          .toList(),
      hayMasAnteriores: json['hay_mas_anteriores'] as bool? ?? false,
      hayMasNuevos: json['hay_mas_nuevos'] as bool? ?? false,
    );
  }
}
