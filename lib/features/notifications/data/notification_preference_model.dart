class NotificationPreferenceModel {
  final String idTipoNotificacion;
  final String codigoTipo;
  final String nombreTipo;
  final bool habilitada;
  final double? radioCercaniaKm;

  const NotificationPreferenceModel({
    required this.idTipoNotificacion,
    required this.codigoTipo,
    required this.nombreTipo,
    required this.habilitada,
    required this.radioCercaniaKm,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    final radio = json['radioCercaniaKm'];

    return NotificationPreferenceModel(
      idTipoNotificacion: json['idTipoNotificacion']?.toString() ?? '',
      codigoTipo: json['codigoTipo']?.toString() ?? '',
      nombreTipo: json['nombreTipo']?.toString() ?? 'Notificacion',
      habilitada: json['habilitada'] != false,
      radioCercaniaKm: radio is num
          ? radio.toDouble()
          : double.tryParse(radio?.toString() ?? ''),
    );
  }
}
