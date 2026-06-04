import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'category_model.dart';
import 'incident_model.dart';

class IncidentsRepository {
  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;

  IncidentsRepository({FirebaseAuth? firebaseAuth, DioClient? dioClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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

  Future<IncidentModel> createIncident({
    required String idCategoria,
    required String titulo,
    required String descripcion,
    required double latitud,
    required double longitud,
    required String direccionReferencial,
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

    return IncidentModel.fromJson(response.data ?? {});
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
