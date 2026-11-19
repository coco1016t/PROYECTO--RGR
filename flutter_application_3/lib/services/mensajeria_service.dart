import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/mensaje_model.dart';
import 'sesion_service.dart';

class MensajeriaService {
  static const String baseUrl = ApiConfig.baseUrl;
  final http.Client _cliente;

  MensajeriaService({http.Client? cliente})
      : _cliente = cliente ?? http.Client();

  void dispose() => _cliente.close();

  Future<List<ContactoMensajeria>> obtenerContactos() async {
    final respuesta = await _cliente
        .get(
          Uri.parse('$baseUrl/mensajes/contactos'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode != 200) {
      throw Exception(_mensajeError(respuesta));
    }

    final datos = jsonDecode(respuesta.body) as List<dynamic>;
    return datos
        .map(
          (fila) => ContactoMensajeria.fromJson(
            fila as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<ConversacionMensajeria>> obtenerConversaciones() async {
    final respuesta = await _cliente
        .get(
          Uri.parse('$baseUrl/mensajes/conversaciones'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode != 200) {
      throw Exception(_mensajeError(respuesta));
    }

    final datos = jsonDecode(respuesta.body) as List<dynamic>;
    return datos
        .map(
          (fila) => ConversacionMensajeria.fromJson(
            fila as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ConversacionMensajeria> abrirConversacion(int usuarioId) async {
    final respuesta = await _cliente
        .post(
          Uri.parse('$baseUrl/mensajes/conversaciones/$usuarioId'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
      return ConversacionMensajeria.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_mensajeError(respuesta));
  }

  Future<PaginaMensajes> obtenerMensajes(
    int conversacionId, {
    int limite = 50,
    int? antesDeId,
    int? despuesDeId,
  }) async {
    if (antesDeId != null && despuesDeId != null) {
      throw ArgumentError('Usa solo un cursor de mensajes a la vez.');
    }

    final parametros = <String, String>{'limite': '$limite'};
    if (antesDeId != null) parametros['antes_de_id'] = '$antesDeId';
    if (despuesDeId != null) parametros['despues_de_id'] = '$despuesDeId';
    final uri = Uri.parse(
      '$baseUrl/mensajes/conversaciones/$conversacionId/mensajes',
    ).replace(queryParameters: parametros);
    final respuesta = await _cliente
        .get(uri, headers: SesionService.instance.headers())
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode != 200) {
      throw Exception(_mensajeError(respuesta));
    }
    return PaginaMensajes.fromJson(
      jsonDecode(respuesta.body) as Map<String, dynamic>,
    );
  }

  Future<MensajeChat> enviarMensaje(
    int conversacionId,
    String contenido,
  ) async {
    final respuesta = await _cliente
        .post(
          Uri.parse(
            '$baseUrl/mensajes/conversaciones/$conversacionId/mensajes',
          ),
          headers: SesionService.instance.headers(json: true),
          body: jsonEncode({'contenido': contenido}),
        )
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode == 201) {
      return MensajeChat.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_mensajeError(respuesta));
  }

  Future<int> marcarLeidos(int conversacionId) async {
    final respuesta = await _cliente
        .post(
          Uri.parse(
            '$baseUrl/mensajes/conversaciones/$conversacionId/leidos',
          ),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));
    _validarSesion(respuesta);
    if (respuesta.statusCode != 200) {
      throw Exception(_mensajeError(respuesta));
    }
    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return (datos['actualizados'] as num?)?.toInt() ?? 0;
  }

  void _validarSesion(http.Response respuesta) {
    SesionService.instance.verificarSesion(respuesta.statusCode);
  }

  String _mensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);
      if (datos is Map && datos['detail'] != null) {
        return datos['detail'].toString();
      }
    } catch (_) {
      // El servidor pudo devolver una respuesta no JSON.
    }
    return 'Error HTTP ${respuesta.statusCode}: ${respuesta.body}';
  }
}
