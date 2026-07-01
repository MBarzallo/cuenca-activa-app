import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'category_model.dart';
import 'incident_comment_model.dart';
import 'incident_completion_confirmation_model.dart';
import 'incident_follow_model.dart';
import 'incident_image_attachment.dart';
import 'incident_model.dart';
import 'incident_status_history_model.dart';
import 'incident_status_option_model.dart';
import 'incident_vote_model.dart';
import 'multimedia_model.dart';
import 'incident_related_model.dart';

class IncidentsRepository {
  static const firebaseStorageBucket = 'cuenca-activa.firebasestorage.app';
  static const maxImageSizeBytes = 5 * 1024 * 1024;
  static const allowedContentTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;
  final DioClient _dioClient;

  IncidentsRepository({FirebaseAuth? firebaseAuth, DioClient? dioClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firebaseStorage = FirebaseStorage.instanceFor(
        bucket: 'cuenca-activa.firebasestorage.app',
      ),
      _dioClient = dioClient ?? DioClient();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/catalogos/categorias-incidencia',
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .where((category) => category.idCategoria.isNotEmpty)
        .toList();
  }

  Future<List<IncidentStatusOptionModel>> getIncidentStatuses() async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>('/api/catalogos/estados-incidencia');
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentStatusOptionModel.fromJson)
        .where((status) => status.codigo.isNotEmpty)
        .toList();
  }

  Future<List<IncidentModel>> getIncidents({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias',
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentModel.fromJson)
        .toList();
  }

  Future<List<IncidentModel>> getNearbyPreferredIncidents({
    required double latitud,
    required double longitud,
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/cercanas/preferidas',
        token: token,
        queryParameters: {
          'latitud': latitud,
          'longitud': longitud,
          'limit': limit,
          'offset': offset,
        },
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentModel.fromJson)
        .toList();
  }

  Future<int> notifyNearbyIncidents({
    required double latitud,
    required double longitud,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/cercanas/notificaciones',
        token: token,
        queryParameters: {'latitud': latitud, 'longitud': longitud},
      );
    });

    final total = response.data?['totalNotificaciones'];
    if (total is num) {
      return total.toInt();
    }

    return int.tryParse(total?.toString() ?? '') ?? 0;
  }

  Future<List<IncidentModel>> getMyIncidents({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/mis-reportes',
        token: token,
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentModel.fromJson)
        .toList();
  }

  Future<IncidentModel> getIncidentById(String idIncidencia) async {
    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia',
      );
    });

    return IncidentModel.fromJson(response.data ?? {});
  }

  Future<List<MultimediaModel>> getIncidentMultimedia(
    String idIncidencia,
  ) async {
    final token = await _getOptionalIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/multimedia',
        token: token,
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MultimediaModel.fromJson)
        .where((media) => media.downloadUrl.isNotEmpty)
        .toList();
  }

  Future<List<IncidentStatusHistoryModel>> getIncidentStatusHistory(
    String idIncidencia,
  ) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/historial-estados',
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentStatusHistoryModel.fromJson)
        .where((item) => item.idHistorial.isNotEmpty)
        .toList();
  }

  Future<IncidentModel> changeIncidentStatus({
    required String idIncidencia,
    required String codigoEstado,
    String? observacion,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.patch<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/estado',
        token: token,
        data: {
          'codigoEstado': codigoEstado,
          'observacion': (observacion ?? '').trim().isEmpty
              ? null
              : observacion!.trim(),
          'origenCambio': 'CIUDADANO',
        },
      );
    });

    return IncidentModel.fromJson(response.data ?? {});
  }

  Future<List<IncidentCommentModel>> getIncidentComments(
    String idIncidencia, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/comentarios',
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentCommentModel.fromJson)
        .where((comment) => comment.contenido.trim().isNotEmpty)
        .toList();
  }

  Future<List<IncidentVoteModel>> getIncidentVotes(
    String idIncidencia, {
    int limit = 10,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/votos',
        queryParameters: {'limit': limit},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentVoteModel.fromJson)
        .where((vote) => vote.idVoto.isNotEmpty)
        .toList();
  }

  Future<IncidentCommentModel> createIncidentComment({
    required String idIncidencia,
    required String contenido,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/comentarios',
        token: token,
        data: {'contenido': contenido.trim()},
      );
    });

    return IncidentCommentModel.fromJson(response.data ?? {});
  }

  Future<IncidentVoteSummaryModel> getIncidentVoteSummary(
    String idIncidencia,
  ) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/votos/resumen',
        token: token,
      );
    });

    return IncidentVoteSummaryModel.fromJson(response.data ?? {});
  }

  Future<IncidentVoteModel> createIncidentVote({
    required String idIncidencia,
    required String tipoVoto,
    String? observacion,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/votos',
        token: token,
        data: {
          'tipoVoto': tipoVoto,
          'observacion': (observacion ?? '').trim().isEmpty
              ? null
              : observacion!.trim(),
        },
      );
    });

    return IncidentVoteModel.fromJson(response.data ?? {});
  }

  Future<void> reportContent({
    required String tipoEntidad,
    required String idEntidad,
    required String motivo,
    String? detalle,
  }) async {
    final token = await _getIdToken();
    await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/reportes-contenido',
        token: token,
        data: {
          'tipoEntidad': tipoEntidad,
          'idEntidad': idEntidad,
          'motivo': motivo.trim(),
          'detalle': (detalle ?? '').trim().isEmpty ? null : detalle!.trim(),
        },
      );
    });
  }

  Future<IncidentFollowStatusModel> getIncidentFollowStatus(
    String idIncidencia,
  ) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/seguimiento/me',
        token: token,
      );
    });

    return IncidentFollowStatusModel.fromJson(response.data ?? {});
  }

  Future<IncidentFollowStatusModel> followIncident(String idIncidencia) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/seguimiento',
        token: token,
      );
    });

    return IncidentFollowStatusModel.fromJson(response.data ?? {});
  }

  Future<IncidentFollowStatusModel> unfollowIncident(
    String idIncidencia,
  ) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.delete<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/seguimiento/me',
        token: token,
      );
    });

    return IncidentFollowStatusModel.fromJson(response.data ?? {});
  }

  Future<IncidentCompletionSummaryModel> getIncidentCompletionSummary(
    String idIncidencia,
  ) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/confirmaciones/resumen',
        token: token,
      );
    });

    return IncidentCompletionSummaryModel.fromJson(response.data ?? {});
  }

  Future<List<IncidentCompletionConfirmationDetailModel>>
  getIncidentCompletionConfirmations(
    String idIncidencia, {
    int limit = 10,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/confirmaciones',
        queryParameters: {'limit': limit},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentCompletionConfirmationDetailModel.fromJson)
        .where((confirmation) => confirmation.idConfirmacion.isNotEmpty)
        .toList();
  }

  Future<IncidentCompletionConfirmationModel> createCompletionConfirmation({
    required String idIncidencia,
    String? observacion,
    double? latitud,
    double? longitud,
    IncidentImageAttachment? imageAttachment,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/confirmaciones',
        token: token,
        data: {
          'observacion': (observacion ?? '').trim().isEmpty
              ? null
              : observacion!.trim(),
          'latitud': latitud,
          'longitud': longitud,
        },
      );
    });

    final confirmation = IncidentCompletionConfirmationModel.fromJson(
      response.data ?? {},
    );

    if (imageAttachment != null) {
      await _uploadAndRegisterConfirmationImage(
        token: token,
        confirmation: confirmation,
        attachment: imageAttachment,
      );
    }

    return confirmation;
  }

  Future<IncidentModel> createIncident({
    required String idCategoria,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    required String direccionReferencial,
    IncidentImageAttachment? imageAttachment,
  }) async {
    final token = await _getIdToken();

    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias',
        token: token,
        data: {
          'idCategoria': idCategoria,
          'titulo': titulo.trim(),
          'descripcion': descripcion.trim(),
          'latitud': latitud,
          'longitud': longitud,
          'direccionReferencial': direccionReferencial.trim().isEmpty
              ? null
              : direccionReferencial.trim(),
        },
      );
    });

    final incident = IncidentModel.fromJson(response.data ?? {});

    if (imageAttachment == null) {
      return incident;
    }

    final multimedia = await _uploadAndRegisterImage(
      token: token,
      incident: incident,
      attachment: imageAttachment,
    );

    return incident.copyWith(imagenes: [multimedia.downloadUrl]);
  }

  Future<MultimediaModel> _uploadAndRegisterImage({
    required String token,
    required IncidentModel incident,
    required IncidentImageAttachment attachment,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'Inicia sesion para subir imagenes.',
      );
    }

    final bytes = await attachment.file.readAsBytes();
    if (bytes.isEmpty) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_VACIO',
        message: 'La imagen seleccionada está vacía.',
      );
    }

    if (bytes.length > maxImageSizeBytes) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_DEMASIADO_GRANDE',
        message: 'La imagen no debe superar 5 MB.',
      );
    }

    final contentType =
        lookupMimeType(attachment.file.path, headerBytes: bytes) ??
        attachment.file.mimeType ??
        'application/octet-stream';

    if (!allowedContentTypes.contains(contentType)) {
      throw ApiException(
        statusCode: 400,
        code: 'CONTENT_TYPE_NO_PERMITIDO',
        message: 'Solo se permiten imágenes JPG, PNG o WEBP.',
      );
    }

    final fileName = _buildSafeFileName(attachment.file.name, contentType);
    final storagePath =
        'incidencias/${incident.idIncidencia}/${user.uid}/$fileName';
    final reference = _firebaseStorage.ref(storagePath);
    final uploadTask = await reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'idIncidencia': incident.idIncidencia,
          'firebaseUid': user.uid,
        },
      ),
    );
    final metadata = await uploadTask.ref.getMetadata();
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return _registerMultimediaMetadata(
      token: token,
      idIncidencia: incident.idIncidencia,
      bucket: firebaseStorageBucket,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: metadata.contentType ?? contentType,
      sizeBytes: metadata.size ?? bytes.length,
      nombreArchivo: fileName,
    );
  }

  Future<MultimediaModel> _uploadAndRegisterConfirmationImage({
    required String token,
    required IncidentCompletionConfirmationModel confirmation,
    required IncidentImageAttachment attachment,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'Inicia sesion para subir imagenes.',
      );
    }

    final bytes = await attachment.file.readAsBytes();
    if (bytes.isEmpty) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_VACIO',
        message: 'La imagen seleccionada está vacía.',
      );
    }

    if (bytes.length > maxImageSizeBytes) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_DEMASIADO_GRANDE',
        message: 'La imagen no debe superar 5 MB.',
      );
    }

    final contentType =
        lookupMimeType(attachment.file.path, headerBytes: bytes) ??
        attachment.file.mimeType ??
        'application/octet-stream';

    if (!allowedContentTypes.contains(contentType)) {
      throw ApiException(
        statusCode: 400,
        code: 'CONTENT_TYPE_NO_PERMITIDO',
        message: 'Solo se permiten imágenes JPG, PNG o WEBP.',
      );
    }

    final fileName = _buildSafeFileName(attachment.file.name, contentType);
    final storagePath =
        'confirmaciones/${confirmation.idConfirmacion}/${user.uid}/$fileName';
    final reference = _firebaseStorage.ref(storagePath);
    final uploadTask = await reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'idConfirmacion': confirmation.idConfirmacion,
          'firebaseUid': user.uid,
        },
      ),
    );
    final metadata = await uploadTask.ref.getMetadata();
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return _registerConfirmationMultimediaMetadata(
      token: token,
      idConfirmacion: confirmation.idConfirmacion,
      bucket: firebaseStorageBucket,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      contentType: metadata.contentType ?? contentType,
      sizeBytes: metadata.size ?? bytes.length,
      nombreArchivo: fileName,
    );
  }

  Future<MultimediaModel> _registerMultimediaMetadata({
    required String token,
    required String idIncidencia,
    required String bucket,
    required String storagePath,
    required String downloadUrl,
    required String contentType,
    required int sizeBytes,
    required String nombreArchivo,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/multimedia',
        token: token,
        data: {
          'bucket': bucket,
          'storagePath': storagePath,
          'downloadUrl': downloadUrl,
          'contentType': contentType,
          'sizeBytes': sizeBytes,
          'nombreArchivo': nombreArchivo,
          'ordenVisualizacion': 0,
          'esPrincipal': true,
        },
      );
    });

    return MultimediaModel.fromJson(response.data ?? {});
  }

  Future<MultimediaModel> _registerConfirmationMultimediaMetadata({
    required String token,
    required String idConfirmacion,
    required String bucket,
    required String storagePath,
    required String downloadUrl,
    required String contentType,
    required int sizeBytes,
    required String nombreArchivo,
  }) async {
    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/confirmaciones/$idConfirmacion/multimedia',
        token: token,
        data: {
          'bucket': bucket,
          'storagePath': storagePath,
          'downloadUrl': downloadUrl,
          'contentType': contentType,
          'sizeBytes': sizeBytes,
          'nombreArchivo': nombreArchivo,
          'ordenVisualizacion': 0,
          'esPrincipal': true,
        },
      );
    });

    return MultimediaModel.fromJson(response.data ?? {});
  }

  String _buildSafeFileName(String originalName, String contentType) {
    final extension = switch (contentType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
    final baseName = p.basenameWithoutExtension(originalName).trim();
    final safeBaseName = baseName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '${timestamp}_${safeBaseName.isEmpty ? 'incidencia' : safeBaseName}$extension';
  }

  Future<String> _getIdToken() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'Inicia sesion para reportar incidencias.',
      );
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw ApiException(
        statusCode: 401,
        code: 'TOKEN_EMPTY',
        message: 'No se pudo validar tu sesion.',
      );
    }

    return token;
  }

  Future<String?> _getOptionalIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<List<IncidentRelatedModel>> getRelatedIncidents(
    String idIncidencia,
  ) async {
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/incidencias/$idIncidencia/relacionadas',
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(IncidentRelatedModel.fromJson)
        .toList();
  }

  Future<void> relateIncident({
    required String idIncidencia,
    required String idIncidenciaRelacionada,
    required String tipoRelacion,
  }) async {
    final token = await _getIdToken();
    await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/incidencias/$idIncidencia/relacionadas',
        token: token,
        data: {
          'idIncidenciaRelacionada': idIncidenciaRelacionada,
          'tipoRelacion': tipoRelacion,
        },
      );
    });
  }

  Future<Response<T>> _safeRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw DioClient.handleDioError(error);
    }
  }
}
