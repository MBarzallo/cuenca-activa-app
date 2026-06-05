class IncidentCommentModel {
  final String idComentario;
  final String idIncidencia;
  final String idUsuario;
  final String aliasUsuario;
  final String contenido;
  final DateTime? creadoEn;
  final DateTime? editadoEn;

  const IncidentCommentModel({
    required this.idComentario,
    required this.idIncidencia,
    required this.idUsuario,
    required this.aliasUsuario,
    required this.contenido,
    required this.creadoEn,
    required this.editadoEn,
  });

  factory IncidentCommentModel.fromJson(Map<String, dynamic> json) {
    return IncidentCommentModel(
      idComentario: json['idComentario']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      aliasUsuario: json['aliasUsuario']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
      editadoEn: DateTime.tryParse(json['editadoEn']?.toString() ?? ''),
    );
  }
}
