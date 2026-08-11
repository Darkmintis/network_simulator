/// Live telemetry emitted by the native tunnel (~1 Hz).
class TunnelStats {
  const TunnelStats({
    required this.bytesUploaded,
    required this.bytesDownloaded,
    required this.packetsUploaded,
    required this.packetsDownloaded,
    required this.packetsDropped,
    required this.uploadMbps,
    required this.downloadMbps,
  });

  const TunnelStats.zero()
      : bytesUploaded = 0,
        bytesDownloaded = 0,
        packetsUploaded = 0,
        packetsDownloaded = 0,
        packetsDropped = 0,
        uploadMbps = 0,
        downloadMbps = 0;

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

  final int bytesUploaded;
  final int bytesDownloaded;
  final int packetsUploaded;
  final int packetsDownloaded;
  final int packetsDropped;
  final double uploadMbps;
  final double downloadMbps;

  String get summary {
    return '↓ ${downloadMbps.toStringAsFixed(2)} Mbps · '
        '↑ ${uploadMbps.toStringAsFixed(2)} Mbps · '
        'dropped $packetsDropped';
  }
}
