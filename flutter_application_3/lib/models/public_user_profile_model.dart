import 'post_model.dart';

class PublicUserProfileModel {
  final int id;
  final String nombre;
  final List<PostModel> publicaciones;

  const PublicUserProfileModel({
    required this.id,
    required this.nombre,
    required this.publicaciones,
  });

  factory PublicUserProfileModel.fromJson(Map<String, dynamic> json) {
    final publicaciones = json['publicaciones'] as List<dynamic>? ?? const [];

    return PublicUserProfileModel(
      id: (json['id_usr'] as num).toInt(),
      nombre: json['nom_usr']?.toString() ?? 'Usuario',
      publicaciones: publicaciones
          .map(
            (post) => PostModel.fromJson(post as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
