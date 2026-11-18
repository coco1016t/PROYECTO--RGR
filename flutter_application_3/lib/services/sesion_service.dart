import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token JWT y los datos del usuario que inició sesión.
/// El token se persiste en almacenamiento seguro del dispositivo
/// (Keystore en Android, Keychain en iOS) y se envía en el header
/// Authorization de cada petición a la API.
class SesionService {
  SesionService._();
  static final SesionService instance = SesionService._();

  /// Permite volver al login desde cualquier servicio cuando el token expira.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String _claveToken = 'token_jwt';
  static const String _claveUsuario = 'usuario_json';

  final FlutterSecureStorage _almacen = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _usuario;

  bool get activa => _token != null && _usuario != null;
  Map<String, dynamic> get usuario => _usuario ?? <String, dynamic>{};
  int? get idUsuario => (usuario['id_usr'] as num?)?.toInt();
  int get tipoUsuario => (usuario['tip_usu'] as num?)?.toInt() ?? 2;

  /// Se llama al abrir la app: recupera la sesión guardada si no ha expirado.
  Future<void> cargar() async {
    try {
      final token = await _almacen.read(key: _claveToken);
      final usuarioJson = await _almacen.read(key: _claveUsuario);
      if (token == null || usuarioJson == null || _expirado(token)) {
        await _almacen.deleteAll();
        return;
      }
      _token = token;
      _usuario = jsonDecode(usuarioJson) as Map<String, dynamic>;
    } catch (_) {
      _token = null;
      _usuario = null;
    }
  }

  Future<void> iniciar(String token, Map<String, dynamic> usuario) async {
    _token = token;
    _usuario = usuario;
    try {
      await _almacen.write(key: _claveToken, value: token);
      await _almacen.write(key: _claveUsuario, value: jsonEncode(usuario));
    } catch (_) {
      // Si el almacenamiento falla, la sesión sigue activa en memoria.
    }
  }

  /// Cierra sesión: la memoria se limpia de inmediato.
  Future<void> cerrar() async {
    _token = null;
    _usuario = null;
    try {
      await _almacen.deleteAll();
    } catch (_) {}
  }

  /// Headers para la API. Si hay sesión agrega "Authorization: Bearer ...".
  Map<String, String> headers({bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Llamar con el statusCode de las respuestas protegidas:
  /// si es 401 (token vencido o inválido) cierra sesión y manda al login.
  void verificarSesion(int statusCode) {
    if (statusCode == 401) {
      cerrar();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
      throw Exception('Tu sesión expiró. Inicia sesión de nuevo.');
    }
  }

  bool _expirado(String token) {
    try {
      final partes = token.split('.');
      final carga = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      ) as Map<String, dynamic>;
      final exp = (carga['exp'] as num).toInt();
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true;
    }
  }
}
