class IncidentFollowModel {
  final String idSeguimiento;
  final String idIncidencia;
  final String idUsuario;
  final bool activo;
  final DateTime? creadoEn;

  const IncidentFollowModel({
    required this.idSeguimiento,
    required this.idIncidencia,
    required this.idUsuario,
    required this.activo,
    required this.creadoEn,
  });

  factory IncidentFollowModel.fromJson(Map<String, dynamic> json) {
    return IncidentFollowModel(
      idSeguimiento: json['idSeguimiento']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      activo: json['activo'] == true,
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
    );
  }
}

class IncidentFollowStatusModel {
  final bool siguiendo;
  final IncidentFollowModel? seguimiento;

  const IncidentFollowStatusModel({
    required this.siguiendo,
    required this.seguimiento,
  });

  const IncidentFollowStatusModel.notFollowing()
    : siguiendo = false,
      seguimiento = null;

  factory IncidentFollowStatusModel.fromJson(Map<String, dynamic> json) {
    final rawFollow = json['seguimiento'];

    return IncidentFollowStatusModel(
      siguiendo: json['siguiendo'] == true,
      seguimiento: rawFollow is Map<String, dynamic>
          ? IncidentFollowModel.fromJson(rawFollow)
          : null,
    );
  }
}
