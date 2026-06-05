class AppNotificationModel {
  final String idNotificacion;
  final String codigoTipo;
  final String nombreTipo;
  final String idIncidencia;
  final String titulo;
  final String mensaje;
  final String estadoEnvio;
  final bool leida;
  final DateTime? creadaEn;
  final DateTime? leidaEn;

  const AppNotificationModel({
    required this.idNotificacion,
    required this.codigoTipo,
    required this.nombreTipo,
    required this.idIncidencia,
    required this.titulo,
    required this.mensaje,
    required this.estadoEnvio,
    required this.leida,
    required this.creadaEn,
    required this.leidaEn,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      idNotificacion: json['idNotificacion']?.toString() ?? '',
      codigoTipo: json['codigoTipo']?.toString() ?? '',
      nombreTipo: json['nombreTipo']?.toString() ?? 'Notificacion',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      estadoEnvio: json['estadoEnvio']?.toString() ?? '',
      leida: json['leida'] == true,
      creadaEn: DateTime.tryParse(json['creadaEn']?.toString() ?? ''),
      leidaEn: DateTime.tryParse(json['leidaEn']?.toString() ?? ''),
    );
  }
}
