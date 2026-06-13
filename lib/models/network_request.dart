class NetworkRequest {
  const NetworkRequest({
    required this.method,
    required this.url,
    required this.startedAt,
    this.headers = const {},
    this.body,
  });

  final String method;
  final String url;
  final DateTime startedAt;
  final Map<String, dynamic> headers;
  final Object? body;
}
