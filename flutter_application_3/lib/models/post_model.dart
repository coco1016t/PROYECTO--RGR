class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String tags;
  final int? usuarioId;
  final String autor;
  final double promedio;
  final int totalValoraciones;

  const PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tags,
    this.usuarioId,
    this.autor = '',
    this.promedio = 0.0,
    this.totalValoraciones = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id_blog'] as num).toInt(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagen: json['img']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      usuarioId: (json['usr_id'] as num?)?.toInt(),
      autor: json['autor']?.toString() ?? '',
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0.0,
      totalValoraciones: (json['total_valoraciones'] as num?)?.toInt() ?? 0,
    );
  }
}