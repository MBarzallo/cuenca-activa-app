class MultimediaModel {
  final String idMultimedia;
  final String idIncidencia;
  final String bucket;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int sizeBytes;
  final String nombreArchivo;
  final String estadoRevision;
  final bool visiblePublicamente;
  final String motivoRevision;

  const MultimediaModel({
    required this.idMultimedia,
    required this.idIncidencia,
    required this.bucket,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.nombreArchivo,
    required this.estadoRevision,
    required this.visiblePublicamente,
    required this.motivoRevision,
  });

  factory MultimediaModel.fromJson(Map<String, dynamic> json) {
    return MultimediaModel(
      idMultimedia: json['idMultimedia']?.toString() ?? '',
      idIncidencia: json['idIncidencia']?.toString() ?? '',
      bucket: json['bucket']?.toString() ?? '',
      storagePath: json['storagePath']?.toString() ?? '',
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      sizeBytes: _toInt(json['sizeBytes']),
      nombreArchivo: json['nombreArchivo']?.toString() ?? '',
      estadoRevision: json['estadoRevision']?.toString() ?? '',
      visiblePublicamente: json['visiblePublicamente'] == true,
      motivoRevision: json['motivoRevision']?.toString() ?? '',
    );
  }

  static int _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
