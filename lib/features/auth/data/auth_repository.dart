import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'auth_user_model.dart';
import 'points_movement_model.dart';

class AuthRepository {
  static const firebaseStorageBucket = 'cuenca-activa.firebasestorage.app';
  static const maxAvatarSizeBytes = 3 * 1024 * 1024;
  static const allowedAvatarContentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;
  final DioClient _dioClient;

  AuthRepository({FirebaseAuth? firebaseAuth, DioClient? dioClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firebaseStorage = FirebaseStorage.instanceFor(
        bucket: firebaseStorageBucket,
      ),
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

  Future<AuthUserModel> updateProfile({
    required String nombres,
    required String apellidos,
    required String aliasPublico,
    String? telefono,
    String? fotoPerfilUrl,
  }) async {
    final token = await _getIdToken();

    final response = await _safeRequest(() {
      return _dioClient.put<Map<String, dynamic>>(
        '/api/usuarios/me/perfil',
        token: token,
        data: {
          'nombres': nombres.trim(),
          'apellidos': apellidos.trim(),
          'aliasPublico': aliasPublico.trim(),
          'telefono': (telefono ?? '').trim().isEmpty ? null : telefono!.trim(),
          'fotoPerfilUrl': (fotoPerfilUrl ?? '').trim().isEmpty
              ? null
              : fotoPerfilUrl!.trim(),
        },
      );
    });

    return AuthUserModel.fromJson(response.data ?? {});
  }

  Future<List<PointsMovementModel>> getPointsMovements({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _getIdToken();

    final response = await _safeRequest(() {
      return _dioClient.get<List<dynamic>>(
        '/api/usuarios/me/movimientos-puntos',
        token: token,
        queryParameters: {'limit': limit, 'offset': offset},
      );
    });

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PointsMovementModel.fromJson)
        .where((movement) => movement.idMovimiento.isNotEmpty)
        .toList();
  }

  Future<String> uploadProfilePhoto(XFile image) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'Inicia sesión para actualizar tu foto.',
      );
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_VACIO',
        message: 'La imagen seleccionada está vacía.',
      );
    }

    if (bytes.length > maxAvatarSizeBytes) {
      throw ApiException(
        statusCode: 400,
        code: 'ARCHIVO_DEMASIADO_GRANDE',
        message: 'La foto de perfil no debe superar 3 MB.',
      );
    }

    final contentType =
        lookupMimeType(image.path, headerBytes: bytes) ??
        image.mimeType ??
        'application/octet-stream';

    if (!allowedAvatarContentTypes.contains(contentType)) {
      throw ApiException(
        statusCode: 400,
        code: 'CONTENT_TYPE_NO_PERMITIDO',
        message: 'Solo se permiten imágenes JPG, PNG o WEBP.',
      );
    }

    final fileName = _buildSafeAvatarFileName(image.name, contentType);
    final storagePath = 'perfiles/${user.uid}/avatar/$fileName';
    final reference = _firebaseStorage.ref(storagePath);
    final uploadTask = await reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {'firebaseUid': user.uid, 'tipo': 'fotoPerfil'},
      ),
    );

    return uploadTask.ref.getDownloadURL();
  }

  Future<AuthUserModel> sincronizarTelefonoVerificado() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw ApiException(
        statusCode: 401,
        code: 'NO_FIREBASE_SESSION',
        message: 'No existe una sesión activa en Firebase',
      );
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw ApiException(
        statusCode: 401,
        code: 'TOKEN_EMPTY',
        message: 'No se pudo obtener el token de Firebase',
      );
    }

    final response = await _safeRequest(() {
      return _dioClient.post<Map<String, dynamic>>(
        '/api/auth/phone/sync',
        token: token,
      );
    });

    return AuthUserModel.fromJson(response.data ?? {});
  }

  Future<void> verificarDisponibilidadTelefono(String phone) async {
    final token = await _getIdToken();
    await _safeRequest(() {
      return _dioClient.get<void>(
        '/api/auth/phone/check',
        token: token,
        queryParameters: {'telefono': phone},
      );
    });
  }

  Future<void> logout() {
    return _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  String _buildSafeAvatarFileName(String originalName, String contentType) {
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

    return '${timestamp}_${safeBaseName.isEmpty ? 'perfil' : safeBaseName}$extension';
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
