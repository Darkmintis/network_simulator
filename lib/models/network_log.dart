class NetworkLog {
  NetworkLog({
    required this.method,
    required this.url,
    required this.durationMs,
    required this.success,
    this.statusCode,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String method;
  final String url;
  final int durationMs;
  final bool success;
  final int? statusCode;
  final String? errorMessage;
  final DateTime timestamp;

  String get summary {
    final status = success ? 'OK' : 'FAIL';
    final code = statusCode == null ? '' : ' $statusCode';
    return '$method $url -> ${durationMs}ms $status$code';
  }
}
