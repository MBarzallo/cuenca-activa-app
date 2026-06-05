import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/dio_client.dart';

class PushNotificationsService {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;
  static bool _tokenRefreshListenerRegistered = false;

  PushNotificationsService({
    FirebaseMessaging? firebaseMessaging,
    FirebaseAuth? firebaseAuth,
    DioClient? dioClient,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _dioClient = dioClient ?? DioClient();

  Future<void> initializeForAuthenticatedUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _firebaseMessaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    if (!_tokenRefreshListenerRegistered) {
      _tokenRefreshListenerRegistered = true;
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _registerToken(newToken);
      });
    }
  }

  Future<void> _registerToken(String fcmToken) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      return;
    }

    try {
      await _dioClient.post<Map<String, dynamic>>(
        '/api/dispositivos',
        token: idToken,
        data: {
          'fcmToken': fcmToken,
          'plataforma': _platformCode(),
          'modeloDispositivo': _modelLabel(),
          'identificadorDispositivo': null,
          'notificacionesHabilitadas': true,
        },
      );
    } on DioException {
      // El registro de push no debe bloquear el login ni el uso principal.
    }
  }

  String _platformCode() {
    if (kIsWeb) {
      return 'WEB';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'IOS';
    }

    return 'ANDROID';
  }

  String _modelLabel() {
    if (kIsWeb) {
      return 'Web';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS';
    }

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macOS';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android';
    }

    return 'Dispositivo';
  }
}
