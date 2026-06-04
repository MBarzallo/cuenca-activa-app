import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

class DioClient {
  final Dio dio;

  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    String? token,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: _options(token),
    );
  }

  Future<Response<T>> post<T>(String path, {String? token, Object? data}) {
    return dio.post<T>(path, data: data, options: _options(token));
  }

  Future<Response<T>> put<T>(String path, {String? token, Object? data}) {
    return dio.put<T>(path, data: data, options: _options(token));
  }

  Options _options(String? token) {
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  static ApiException handleDioError(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      return ApiException(
        statusCode: response?.statusCode ?? 500,
        code: data['code']?.toString() ?? 'UNKNOWN_ERROR',
        message: data['message']?.toString() ?? 'Error desconocido',
        body: data,
      );
    }

    return ApiException(
      statusCode: response?.statusCode ?? 500,
      code: 'NETWORK_ERROR',
      message: error.message ?? 'Error de conexión con el servidor',
    );
  }
}
