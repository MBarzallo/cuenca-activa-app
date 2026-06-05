class IncidentStatusHistoryModel {
  final String idHistorial;
  final String codigoEstadoAnterior;
  final String nombreEstadoAnterior;
  final String codigoEstadoNuevo;
  final String nombreEstadoNuevo;
  final String aliasUsuarioAccion;
  final String observacion;
  final String origenCambio;
  final DateTime? cambiadoEn;

  const IncidentStatusHistoryModel({
    required this.idHistorial,
    required this.codigoEstadoAnterior,
    required this.nombreEstadoAnterior,
    required this.codigoEstadoNuevo,
    required this.nombreEstadoNuevo,
    required this.aliasUsuarioAccion,
    required this.observacion,
    required this.origenCambio,
    required this.cambiadoEn,
  });

  factory IncidentStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return IncidentStatusHistoryModel(
      idHistorial: json['idHistorial']?.toString() ?? '',
      codigoEstadoAnterior: json['codigoEstadoAnterior']?.toString() ?? '',
      nombreEstadoAnterior: json['nombreEstadoAnterior']?.toString() ?? '',
      codigoEstadoNuevo: json['codigoEstadoNuevo']?.toString() ?? '',
      nombreEstadoNuevo: json['nombreEstadoNuevo']?.toString() ?? '',
      aliasUsuarioAccion: json['aliasUsuarioAccion']?.toString() ?? '',
      observacion: json['observacion']?.toString() ?? '',
      origenCambio: json['origenCambio']?.toString() ?? '',
      cambiadoEn: DateTime.tryParse(json['cambiadoEn']?.toString() ?? ''),
    );
  }
}
