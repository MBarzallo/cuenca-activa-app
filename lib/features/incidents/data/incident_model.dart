class IncidentModel {
  final String idIncidencia;
  final String aliasUsuarioReporta;
  final String idCategoria;
  final String codigoCategoria;
  final String nombreCategoria;
  final String codigoEstado;
  final String nombreEstado;
  final String titulo;
  final String descripcion;
  final double? latitud;
  final double? longitud;
  final String? direccionReferencial;
  final int prioridadCalculada;
  final int cantidadValidaciones;
  final int cantidadComentarios;
  final int cantidadSeguidores;
  final int cantidadConfirmaciones;
  final DateTime? fechaReporte;

  const IncidentModel({
    required this.idIncidencia,
    required this.aliasUsuarioReporta,
    required this.idCategoria,
    required this.codigoCategoria,
    required this.nombreCategoria,
    required this.codigoEstado,
    required this.nombreEstado,
    required this.titulo,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.direccionReferencial,
    required this.prioridadCalculada,
    required this.cantidadValidaciones,
    required this.cantidadComentarios,
    required this.cantidadSeguidores,
    required this.cantidadConfirmaciones,
    required this.fechaReporte,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      aliasUsuarioReporta: json['aliasUsuarioReporta']?.toString() ?? '',
      idCategoria: json['idCategoria']?.toString() ?? '',
      codigoCategoria: json['codigoCategoria']?.toString() ?? '',
      nombreCategoria: json['nombreCategoria']?.toString() ?? 'Incidencia',
      codigoEstado: json['codigoEstado']?.toString() ?? '',
      nombreEstado: json['nombreEstado']?.toString() ?? 'Reportada',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      direccionReferencial: json['direccionReferencial']?.toString(),
      prioridadCalculada: _toInt(json['prioridadCalculada']),
      cantidadValidaciones: _toInt(json['cantidadValidaciones']),
      cantidadComentarios: _toInt(json['cantidadComentarios']),
      cantidadSeguidores: _toInt(json['cantidadSeguidores']),
      cantidadConfirmaciones: _toInt(json['cantidadConfirmaciones']),
      fechaReporte: DateTime.tryParse(json['fechaReporte']?.toString() ?? ''),
    );
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
