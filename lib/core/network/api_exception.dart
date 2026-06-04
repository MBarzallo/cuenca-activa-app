class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? body;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.body,
  });

  @override
  String toString() {
    return 'ApiException($statusCode, $code): $message';
  }
}
