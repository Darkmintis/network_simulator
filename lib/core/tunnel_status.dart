/// Lifecycle state of the local VPN / packet tunnel.
enum TunnelStatus {
  /// Tunnel is not running.
  idle,

  /// Native layer is allocating resources before connecting.
  preparing,

  /// VPN permission granted and tunnel is being established.
  connecting,

  /// Traffic is actively shaped through the tunnel.
  connected,

  /// Tunnel is shutting down.
  disconnecting,

  /// Last start/stop operation failed; see [NetworkSimulatorController.lastError].
  error,

  /// Platform does not expose a supported tunnel implementation.
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

/// Convenience helpers for [TunnelStatus].
extension TunnelStatusX on TunnelStatus {
  /// Human-readable label for UI display.
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

  /// Whether the tunnel is starting or already shaping traffic.
  bool get isActive =>
      this == TunnelStatus.connected ||
      this == TunnelStatus.connecting ||
      this == TunnelStatus.preparing;
}
