class PointsMovementModel {
  final String idMovimiento;
  final String codigoAccion;
  final String nombreAccion;
  final String? idIncidencia;
  final String? tituloIncidencia;
  final int puntos;
  final String? motivo;
  final DateTime? creadoEn;

  const PointsMovementModel({
    required this.idMovimiento,
    required this.codigoAccion,
    required this.nombreAccion,
    required this.idIncidencia,
    required this.tituloIncidencia,
    required this.puntos,
    required this.motivo,
    required this.creadoEn,
  });

  factory PointsMovementModel.fromJson(Map<String, dynamic> json) {
    return PointsMovementModel(
      idMovimiento: json['idMovimiento']?.toString() ?? '',
      codigoAccion: json['codigoAccion']?.toString() ?? '',
      nombreAccion: json['nombreAccion']?.toString() ?? 'Movimiento',
      idIncidencia: json['idIncidencia']?.toString(),
      tituloIncidencia: json['tituloIncidencia']?.toString(),
      puntos: _toInt(json['puntos']),
      motivo: json['motivo']?.toString(),
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
