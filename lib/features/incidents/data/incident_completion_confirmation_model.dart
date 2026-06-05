import 'multimedia_model.dart';

class IncidentCompletionConfirmationModel {
  final String idConfirmacion;
  final String idIncidencia;
  final String idUsuario;
  final String? observacion;
  final double? latitud;
  final double? longitud;
  final bool valida;
  final DateTime? creadoEn;

  const IncidentCompletionConfirmationModel({
    required this.idConfirmacion,
    required this.idIncidencia,
    required this.idUsuario,
    required this.observacion,
    required this.latitud,
    required this.longitud,
    required this.valida,
    required this.creadoEn,
  });

  factory IncidentCompletionConfirmationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return IncidentCompletionConfirmationModel(
      idConfirmacion: json['idConfirmacion']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      observacion: json['observacion']?.toString(),
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      valida: json['valida'] != false,
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
    );
  }

  bool get hasLocation => latitud != null && longitud != null;

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class IncidentCompletionConfirmationDetailModel {
  final String idConfirmacion;
  final String idIncidencia;
  final String idUsuario;
  final String aliasUsuario;
  final String? observacion;
  final double? latitud;
  final double? longitud;
  final bool valida;
  final DateTime? creadoEn;
  final List<MultimediaModel> multimedia;

  const IncidentCompletionConfirmationDetailModel({
    required this.idConfirmacion,
    required this.idIncidencia,
    required this.idUsuario,
    required this.aliasUsuario,
    required this.observacion,
    required this.latitud,
    required this.longitud,
    required this.valida,
    required this.creadoEn,
    required this.multimedia,
  });

  factory IncidentCompletionConfirmationDetailModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return IncidentCompletionConfirmationDetailModel(
      idConfirmacion: json['idConfirmacion']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      idUsuario: json['idUsuario']?.toString() ?? '',
      aliasUsuario: json['aliasUsuario']?.toString() ?? '',
      observacion: json['observacion']?.toString(),
      latitud: IncidentCompletionConfirmationModel._toDouble(json['latitud']),
      longitud: IncidentCompletionConfirmationModel._toDouble(json['longitud']),
      valida: json['valida'] != false,
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
      multimedia: (json['multimedia'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MultimediaModel.fromJson)
          .where((media) => media.downloadUrl.isNotEmpty)
          .toList(),
    );
  }

  bool get hasLocation => latitud != null && longitud != null;
}

class IncidentCompletionSummaryModel {
  final int totalConfirmaciones;
  final bool usuarioYaConfirmo;
  final IncidentCompletionConfirmationModel? confirmacionUsuario;

  const IncidentCompletionSummaryModel({
    required this.totalConfirmaciones,
    required this.usuarioYaConfirmo,
    required this.confirmacionUsuario,
  });

  const IncidentCompletionSummaryModel.empty()
    : totalConfirmaciones = 0,
      usuarioYaConfirmo = false,
      confirmacionUsuario = null;

  factory IncidentCompletionSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawConfirmation = json['confirmacionUsuario'];

    return IncidentCompletionSummaryModel(
      totalConfirmaciones: _toInt(json['totalConfirmaciones']),
      usuarioYaConfirmo: json['usuarioYaConfirmo'] == true,
      confirmacionUsuario: rawConfirmation is Map<String, dynamic>
          ? IncidentCompletionConfirmationModel.fromJson(rawConfirmation)
          : null,
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
