class IncidentStatusOptionModel {
  final String idEstado;
  final String codigo;
  final String nombre;
  final String descripcion;
  final int ordenFlujo;
  final bool esEstadoFinal;

  const IncidentStatusOptionModel({
    required this.idEstado,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.ordenFlujo,
    required this.esEstadoFinal,
  });

  factory IncidentStatusOptionModel.fromJson(Map<String, dynamic> json) {
    return IncidentStatusOptionModel(
      idEstado: json['idEstado']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      ordenFlujo: _toInt(json['ordenFlujo']),
      esEstadoFinal: json['esEstadoFinal'] == true,
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
