class IncidentRelatedModel {
  final String idRelacion;
  final String idIncidenciaRelacionada;
  final String titulo;
  final String nombreCategoria;
  final String nombreEstado;
  final String tipoRelacion;
  final double distanciaMetros;
  final DateTime creadaEn;

  const IncidentRelatedModel({
    required this.idRelacion,
    required this.idIncidenciaRelacionada,
    required this.titulo,
    required this.nombreCategoria,
    required this.nombreEstado,
    required this.tipoRelacion,
    required this.distanciaMetros,
    required this.creadaEn,
  });

  factory IncidentRelatedModel.fromJson(Map<String, dynamic> json) {
    return IncidentRelatedModel(
      idRelacion: json['idRelacion']?.toString() ?? '',
      idIncidenciaRelacionada: json['idIncidenciaRelacionada']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      nombreCategoria: json['nombreCategoria']?.toString() ?? '',
      nombreEstado: json['nombreEstado']?.toString() ?? '',
      tipoRelacion: json['tipoRelacion']?.toString() ?? '',
      distanciaMetros: (json['distanciaMetros'] as num?)?.toDouble() ?? 0.0,
      creadaEn: DateTime.tryParse(json['creadaEn']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
