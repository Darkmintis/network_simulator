/// Lifecycle state of the local VPN / packet tunnel.
enum TunnelStatus {
  idle,
  preparing,
  connecting,
  connected,
  disconnecting,
  error,
  unsupported;

  /// Parses native / MethodChannel status strings.
  static TunnelStatus parse(String? raw) {
    switch (raw) {
      case 'preparing':
        return TunnelStatus.preparing;
      case 'connecting':
        return TunnelStatus.connecting;
      case 'connected':
        return TunnelStatus.connected;
      case 'disconnecting':
        return TunnelStatus.disconnecting;
      case 'error':
        return TunnelStatus.error;
      case 'unsupported':
        return TunnelStatus.unsupported;
      case 'idle':
      default:
        return TunnelStatus.idle;
    }
  }

  String get wireName => name;
}

extension TunnelStatusX on TunnelStatus {
  String get label {
    switch (this) {
      case TunnelStatus.idle:
        return 'Idle';
      case TunnelStatus.preparing:
        return 'Preparing';
      case TunnelStatus.connecting:
        return 'Connecting';
      case TunnelStatus.connected:
        return 'Connected';
      case TunnelStatus.disconnecting:
        return 'Disconnecting';
      case TunnelStatus.error:
        return 'Error';
      case TunnelStatus.unsupported:
        return 'Unsupported';
    }
  }

  bool get isActive =>
      this == TunnelStatus.connected ||
      this == TunnelStatus.connecting ||
      this == TunnelStatus.preparing;
}
