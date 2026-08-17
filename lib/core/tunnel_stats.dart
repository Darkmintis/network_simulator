/// Live telemetry emitted by the native tunnel (~1 Hz).
class TunnelStats {
  /// Creates stats with explicit counters and throughput values.
  const TunnelStats({
    required this.bytesUploaded,
    required this.bytesDownloaded,
    required this.packetsUploaded,
    required this.packetsDownloaded,
    required this.packetsDropped,
    required this.uploadMbps,
    required this.downloadMbps,
  });

  /// Zeroed stats used before the tunnel starts or after it stops.
  const TunnelStats.zero()
    : bytesUploaded = 0,
      bytesDownloaded = 0,
      packetsUploaded = 0,
      packetsDownloaded = 0,
      packetsDropped = 0,
      uploadMbps = 0,
      downloadMbps = 0;

  /// Parses a native stats map from the EventChannel.
  factory TunnelStats.fromMap(Map<dynamic, dynamic> map) {
    return TunnelStats(
      bytesUploaded: (map['bytesUploaded'] as num?)?.toInt() ?? 0,
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      packetsUploaded: (map['packetsUploaded'] as num?)?.toInt() ?? 0,
      packetsDownloaded: (map['packetsDownloaded'] as num?)?.toInt() ?? 0,
      packetsDropped: (map['packetsDropped'] as num?)?.toInt() ?? 0,
      uploadMbps: (map['uploadMbps'] as num?)?.toDouble() ?? 0,
      downloadMbps: (map['downloadMbps'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Total bytes sent through the tunnel since it connected.
  final int bytesUploaded;

  /// Total bytes received through the tunnel since it connected.
  final int bytesDownloaded;

  /// Packets forwarded upstream.
  final int packetsUploaded;

  /// Packets forwarded downstream.
  final int packetsDownloaded;

  /// Packets intentionally dropped by the shaper.
  final int packetsDropped;

  /// Measured upload throughput in megabits per second.
  final double uploadMbps;

  /// Measured download throughput in megabits per second.
  final double downloadMbps;

  /// Compact one-line summary for the debug UI.
  String get summary {
    return '↓ ${downloadMbps.toStringAsFixed(2)} Mbps · '
        '↑ ${uploadMbps.toStringAsFixed(2)} Mbps · '
        'dropped $packetsDropped';
  }
}
