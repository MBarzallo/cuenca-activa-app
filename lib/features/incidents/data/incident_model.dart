class IncidentModel {
  final String idIncidencia;
  final String idUsuarioReporta;
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
  final List<String> imagenes;
  final String? idSector;
  final String? nombreSector;

  const IncidentModel({
    required this.idIncidencia,
    required this.idUsuarioReporta,
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
    required this.imagenes,
    this.idSector,
    this.nombreSector,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuarioReporta: json['idUsuarioReporta']?.toString() ?? '',
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
      imagenes: (json['imagenes'] as List<dynamic>? ?? [])
          .map((image) => image.toString())
          .where((image) => image.isNotEmpty)
          .toList(),
      idSector: json['idSector']?.toString(),
      nombreSector: json['nombreSector']?.toString(),
    );
  }

  IncidentModel copyWith({
    String? codigoEstado,
    String? nombreEstado,
    int? cantidadComentarios,
    int? cantidadSeguidores,
    int? cantidadConfirmaciones,
    List<String>? imagenes,
    String? idSector,
    String? nombreSector,
  }) {
    return IncidentModel(
      idIncidencia: idIncidencia,
      idUsuarioReporta: idUsuarioReporta,
      aliasUsuarioReporta: aliasUsuarioReporta,
      idCategoria: idCategoria,
      codigoCategoria: codigoCategoria,
      nombreCategoria: nombreCategoria,
      codigoEstado: codigoEstado ?? this.codigoEstado,
      nombreEstado: nombreEstado ?? this.nombreEstado,
      titulo: titulo,
      descripcion: descripcion,
      latitud: latitud,
      longitud: longitud,
      direccionReferencial: direccionReferencial,
      prioridadCalculada: prioridadCalculada,
      cantidadValidaciones: cantidadValidaciones,
      cantidadComentarios: cantidadComentarios ?? this.cantidadComentarios,
      cantidadSeguidores: cantidadSeguidores ?? this.cantidadSeguidores,
      cantidadConfirmaciones:
          cantidadConfirmaciones ?? this.cantidadConfirmaciones,
      fechaReporte: fechaReporte,
      imagenes: imagenes ?? this.imagenes,
      idSector: idSector ?? this.idSector,
      nombreSector: nombreSector ?? this.nombreSector,
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
