import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/post_model.dart';
import 'sesion_service.dart';

class PostService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<PostModel> agregarPost({
    required String titulo,
    required String descripcion,
    required Uint8List imagenBytes,
    required String nombreImagen,
    String? tags,
  }) =>
      _guardarPost(
        http.MultipartRequest('POST', Uri.parse('$baseUrl/blog')),
        titulo: titulo,
        descripcion: descripcion,
        tags: tags,
        imagen: http.MultipartFile.fromBytes(
          'imagen',
          imagenBytes,
          filename: nombreImagen,
        ),
      );

  Future<PostModel> editarPost({
    required int id,
    required String titulo,
    required String descripcion,
    required String tags,
    Uint8List? imagenBytes,
    String? nombreImagen,
  }) =>
      _guardarPost(
        http.MultipartRequest('PUT', Uri.parse('$baseUrl/blog/$id')),
        titulo: titulo,
        descripcion: descripcion,
        tags: tags,
        imagen: imagenBytes == null
            ? null
            : http.MultipartFile.fromBytes(
                'imagen',
                imagenBytes,
                filename: nombreImagen,
              ),
      );

  Future<PostModel> _guardarPost(
    http.MultipartRequest request, {
    required String titulo,
    required String descripcion,
    required String? tags,
    required http.MultipartFile? imagen,
  }) async {
    request
      ..headers.addAll(SesionService.instance.headers())
      ..fields['titulo'] = titulo.trim()
      ..fields['descripcion'] = descripcion.trim();

    if (tags != null && tags.trim().isNotEmpty) {
      request.fields['tags'] = tags.trim();
    }

    if (imagen != null) request.files.add(imagen);

    final respuesta = await request.send().timeout(
          const Duration(seconds: 30),
        );
    final cuerpo = await respuesta.stream.bytesToString().timeout(
          const Duration(seconds: 10),
        );

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
      return PostModel.fromJson(jsonDecode(cuerpo) as Map<String, dynamic>);
    }
    throw Exception(_detalleError(
      cuerpo,
      'No se pudo guardar la publicación (HTTP: ${respuesta.statusCode})',
    ));
  }

  Future<void> eliminarPost(int id) async {
    final respuesta = await http
        .delete(
          Uri.parse('$baseUrl/blog/$id'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));
    SesionService.instance.verificarSesion(respuesta.statusCode);
    if (respuesta.statusCode != 204) {
      throw Exception(_detalleError(
        utf8.decode(respuesta.bodyBytes, allowMalformed: true),
        'No se pudo eliminar la publicación (HTTP: ${respuesta.statusCode})',
      ));
    }
  }

  String _detalleError(String cuerpo, String mensaje) {
    try {
      final resultado = jsonDecode(cuerpo);
      if (resultado is Map && resultado['detail'] is String) {
        return resultado['detail'] as String;
      }
    } on FormatException {
      return mensaje;
    }
    return mensaje;
  }

  static Uri urlImagen(String rutaImagen) {
    final uri = Uri.parse(rutaImagen);
    return uri.hasScheme ? uri : Uri.parse(baseUrl).resolve(rutaImagen);
  }

  /// GET /blog -> todas las publicaciones (propias y de otros).
  Future<List<PostModel>> obtenerPosts() => _listar('/blog');

  /// GET /blog/mios -> solo las publicaciones del usuario con sesión.
  Future<List<PostModel>> obtenerMisPosts() => _listar('/blog/mios');

  Future<List<PostModel>> _listar(String ruta) async {
    final respuesta = await http
        .get(
          Uri.parse('$baseUrl$ruta'),
          headers: SesionService.instance.headers(),
        )
        .timeout(const Duration(seconds: 10));

    SesionService.instance.verificarSesion(respuesta.statusCode);

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar publicaciones');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map(
          (json) => PostModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
