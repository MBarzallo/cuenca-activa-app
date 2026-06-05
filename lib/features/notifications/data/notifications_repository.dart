import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'app_notification_model.dart';
import 'notification_preference_model.dart';

class NotificationsRepository {
  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;

  NotificationsRepository({FirebaseAuth? firebaseAuth, DioClient? dioClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _dioClient = dioClient ?? DioClient();

  Future<List<AppNotificationModel>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/notificaciones',
        token: token,
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .where((notification) => notification.idNotificacion.isNotEmpty)
        .toList();
  }

  Future<int> getUnreadCount() async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>(
        '/api/notificaciones/no-leidas/count',
        token: token,
      );
    });

    final total = response.data?['total'];
    if (total is num) {
      return total.toInt();
    }

    return int.tryParse(total?.toString() ?? '') ?? 0;
  }

  Future<AppNotificationModel> markAsRead(String idNotificacion) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.put<Map<String, dynamic>>(
        '/api/notificaciones/$idNotificacion/leida',
        token: token,
      );
    });

    return AppNotificationModel.fromJson(response.data ?? {});
  }

  Future<void> markAllAsRead() async {
    final token = await _getIdToken();
    await _safeRequest(() {
      return _dioClient.put<void>('/api/notificaciones/leidas', token: token);
    });
  }

  Future<List<NotificationPreferenceModel>> getPreferences() async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/notificaciones/preferencias',
        token: token,
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationPreferenceModel.fromJson)
        .where((preference) => preference.codigoTipo.isNotEmpty)
        .toList();
  }

  Future<NotificationPreferenceModel> updatePreference({
    required String codigoTipo,
    required bool habilitada,
    double? radioCercaniaKm,
  }) async {
    final token = await _getIdToken();
    final response = await _safeRequest(() {
      return _dioClient.put<Map<String, dynamic>>(
        '/api/notificaciones/preferencias/$codigoTipo',
        token: token,
        data: {'habilitada': habilitada, 'radioCercaniaKm': radioCercaniaKm},
      );
    });

    return NotificationPreferenceModel.fromJson(response.data ?? {});
  }

  Future<String> _getIdToken() async {
    final user = _firebaseAuth.currentUser;
    final token = await user?.getIdToken();

    if (token == null || token.isEmpty) {
      throw ApiException(
        statusCode: 401,
        code: 'AUTH_REQUIRED',
        message: 'Debes iniciar sesion para ver tus notificaciones.',
      );
    }

    return token;
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
