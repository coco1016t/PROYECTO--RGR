class ValoracionModel {
  final double promedio;
  final int total;
  final int? miPuntuacion;

  const ValoracionModel({
    required this.promedio,
    required this.total,
    this.miPuntuacion,
  });

  factory ValoracionModel.fromJson(Map<String, dynamic> json) {
    return ValoracionModel(
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      miPuntuacion: (json['mi_puntuacion'] as num?)?.toInt(),
    );
  }
}
