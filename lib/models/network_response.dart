class NetworkResponse {
  const NetworkResponse({
    required this.statusCode,
    required this.durationMs,
    required this.success,
    this.body,
    this.errorMessage,
  });

  final int? statusCode;
  final int durationMs;
  final bool success;
  final Object? body;
  final String? errorMessage;
}
