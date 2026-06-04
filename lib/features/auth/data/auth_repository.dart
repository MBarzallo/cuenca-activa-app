import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'auth_user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;

  AuthRepository({FirebaseAuth? firebaseAuth, DioClient? dioClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _dioClient = dioClient ?? DioClient();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<AuthUserModel?> checkSession() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return null;
    }

    return getMe();
  }

  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    return getMe();
  }

  Future<AuthUserModel> register({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String aliasPublico,
    required String telefono,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final token = await _getIdToken();

    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        token: token,
        data: {
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'aliasPublico': aliasPublico.trim(),
          'telefono': telefono.trim(),
        },
      );
    });

    return AuthUserModel.fromJson(response.data ?? {});
  }

  Future<AuthUserModel> getMe() async {
    final token = await _getIdToken();

    final response = await _safeRequest(() {
      return _dioClient.get<Map<String, dynamic>>('/api/auth/me', token: token);
    });

    return AuthUserModel.fromJson(response.data ?? {});
  }

  Future<void> logout() {
    return _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String> _getIdToken() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'No existe una sesión activa en Firebase',
      );
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw ApiException(
        statusCode: 401,
        code: 'TOKEN_EMPTY',
        message: 'No se pudo obtener el token de Firebase',
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
