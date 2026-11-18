import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/comentario_model.dart';
import 'sesion_service.dart';

class ComentarioService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// GET /blog/{id}/comentarios -> comentarios de una publicación.
  Future<List<ComentarioModel>> obtenerComentarios(int blogId) async {
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl/blog/$blogId/comentarios'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar comentarios');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => ComentarioModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// POST /comentarios. El autor lo determina la API con el token.
  Future<ComentarioModel> agregarComentario({
    required int blogId,
    required String texto,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/comentarios'),
          headers: SesionService.instance.headers(json: true),
          body: jsonEncode({
            'comentario': texto.trim(),
            'blog_id': blogId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 201) {
      throw Exception(
        'No se pudo registrar el comentario: ${respuesta.body}',
      );
    }

    return ComentarioModel.fromJson(
      jsonDecode(respuesta.body) as Map<String, dynamic>,
    );
  }
}
