
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'sesion_service.dart';

class AuthService {
  static const String baseUrl = ApiConfig.baseUrl;

  String? validarLogin({
    required String usuario,
    required String password,
  }) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }
    return null;
  }

  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarpassword,
  }) {
    if (nombre.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        confirmarpassword.isEmpty) {
      return 'Completa todos los campos';
    }

    if (!correo.contains('@')) {
      return 'Ingresa un correo válido';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (password != confirmarpassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Inicia sesión: la API responde {access_token, token_type, usuario}.
  /// Se guarda el token en SesionService y se devuelve solo el usuario,
  /// así LoginPage sigue funcionando igual que antes.
  Future<Map<String, dynamic>> autenticar({
    required String correo,
    required String password,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'mail': correo.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic resultado = jsonDecode(respuesta.body);

    if (respuesta.statusCode == 200 &&
        resultado is Map<String, dynamic> &&
        resultado['access_token'] != null &&
        resultado['usuario'] is Map<String, dynamic>) {
      final usuario = resultado['usuario'] as Map<String, dynamic>;
      await SesionService.instance.iniciar(
        resultado['access_token'] as String,
        usuario,
      );
      return usuario;
    }

    if (respuesta.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }

    if (resultado is Map && resultado['detail'] != null) {
      throw Exception(resultado['detail'].toString());
    }

    throw Exception(
      'Error al iniciar sesión: HTTP ${respuesta.statusCode}',
    );
  }
}
