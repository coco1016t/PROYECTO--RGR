
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'sesion_service.dart';

class UserService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<UserModel>> obtenerUsuarios() async {
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl/usuarios'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al consultar usuarios: ${_mensajeError(respuesta)}',
      );
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => UserModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Registro público (sin token) o alta hecha por un admin (con token).
  Future<UserModel> agregarUsuario(UserModel usuario) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/usuarios'),
          headers: SesionService.instance.headers(json: true),
          body: jsonEncode(usuario.toJsonCrear()),
        )
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 201) {
      return UserModel.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_mensajeError(respuesta));
  }

  Future<UserModel> actualizarUsuario(UserModel usuario) async {
    final respuesta = await http
        .put(
          Uri.parse('$baseUrl/usuarios/${usuario.id}'),
          headers: SesionService.instance.headers(json: true),
          body: jsonEncode({
            'nom_usr': usuario.nombre,
            'mail': usuario.correo,
            'dir_usr': usuario.direccion,
            'tip_usu': usuario.tipoUsuario,
          }),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode == 200) {
      return UserModel.fromJson(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_mensajeError(respuesta));
  }

  Future<void> eliminarUsuario(int id) async {
    final respuesta = await http
        .delete(
          Uri.parse('$baseUrl/usuarios/$id'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200 &&
        respuesta.statusCode != 204) {
      throw Exception(_mensajeError(respuesta));
    }
  }

  String _mensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);

      if (datos is Map && datos['detail'] != null) {
        return datos['detail'].toString();
      }
    } catch (_) {
      // La respuesta no contiene JSON.
    }

    return 'Error HTTP ${respuesta.statusCode}: ${respuesta.body}';
  }
}
