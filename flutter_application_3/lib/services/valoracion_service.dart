import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/valoracion_model.dart';
import 'sesion_service.dart';

class ValoracionService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// GET /blog/{id}/valoracion -> promedio, total y mi puntuación.
  Future<ValoracionModel> obtener(int blogId) async {
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl/blog/$blogId/valoracion'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar la valoración');
    }

    return ValoracionModel.fromJson(
      jsonDecode(respuesta.body) as Map<String, dynamic>,
    );
  }

  /// PUT /blog/{id}/valoracion -> registra o cambia mi puntuación (1 a 5).
  Future<ValoracionModel> enviar(int blogId, int puntos) async {
    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/blog/$blogId/valoracion'),
          headers: SesionService.instance.headers(json: true),
          body: jsonEncode({'puntos': puntos}),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo registrar tu valoración');
    }

    return ValoracionModel.fromJson(
      jsonDecode(respuesta.body) as Map<String, dynamic>,
    );
  }
}