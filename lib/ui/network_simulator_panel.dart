import 'package:flutter/material.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../core/tunnel_stats.dart';
import '../core/tunnel_status.dart';
import 'network_simulator_theme.dart';

/// Tunnel controls and shaping presets for the network simulator UI.
class NetworkSimulatorPanel extends StatefulWidget {
  /// Creates a panel bound to [controller].
  const NetworkSimulatorPanel({super.key, required this.controller});

  /// Controller that owns tunnel state and shaping config.
  final NetworkSimulatorController controller;

  @override
  State<NetworkSimulatorPanel> createState() => _NetworkSimulatorPanelState();
}

class _NetworkSimulatorPanelState extends State<NetworkSimulatorPanel> {
  late NetworkMode _mode;
  bool _busy = false;

  static const _presets = [
    NetworkMode.normal,
    NetworkMode.slow3G,
    NetworkMode.slow2G,
    NetworkMode.offline,
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.controller.mode;
  }

  Future<void> _toggleTunnel() async {
    if (_busy) return;
    final controller = widget.controller;
    setState(() => _busy = true);
    try {
      if (controller.status == TunnelStatus.connected ||
          controller.status == TunnelStatus.connecting ||
          controller.status == TunnelStatus.preparing) {
        await controller.stopTunnel();
      } else {
        await controller.startTunnel();
      }
    } catch (_) {
      // Errors are surfaced via controller.lastError / status.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyMode(NetworkMode mode) {
    setState(() => _mode = mode);
    switch (mode) {
      case NetworkMode.offline:
        widget.controller.enableOffline();
      case NetworkMode.normal:
        widget.controller.reset();
      default:
        widget.controller.setMode(mode);
    }
    setState(() => _mode = widget.controller.mode);
  }

  Color _statusColor(TunnelStatus status) {
    switch (status) {
      case TunnelStatus.connected:
        return NetworkSimulatorTheme.success;
      case TunnelStatus.error:
        return NetworkSimulatorTheme.error;
      case TunnelStatus.connecting:
      case TunnelStatus.preparing:
        return NetworkSimulatorTheme.accentSoft;
      default:
        return NetworkSimulatorTheme.textMuted;
    }
  }

  String _statsLabel(TunnelStatus status, TunnelStats stats) {
    if (status != TunnelStatus.connected && status != TunnelStatus.connecting) {
      return 'No active traffic';
    }
    if (stats.downloadMbps == 0 && stats.uploadMbps == 0) {
      return 'Connected — waiting for traffic';
    }
    return stats.summary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final status = widget.controller.status;
        final stats = widget.controller.stats;
        final error = widget.controller.lastError;
        final isActive =
            status == TunnelStatus.connected ||
            status == TunnelStatus.connecting;
        final isStarting =
            _busy ||
            status == TunnelStatus.preparing ||
            status == TunnelStatus.connecting;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _StatusCard(
              status: status,
              mode: _mode,
              statusColor: _statusColor(status),
              statsLabel: _statsLabel(status, stats),
              error: error,
            ),
            const SizedBox(height: 20),
            _PrimaryActionButton(
              isActive: isActive,
              isLoading: isStarting && !isActive,
              onPressed: isStarting && !isActive ? null : _toggleTunnel,
            ),
            const SizedBox(height: 28),
            Text(
              'Network profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Normal uses your real connection speed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ..._presets.map(
              (mode) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PresetTile(
                  mode: mode,
                  selected: _mode == mode,
                  onTap: () => _applyMode(mode),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shapes all app traffic while the tunnel is running. Android only.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.mode,
    required this.statusColor,
    required this.statsLabel,
    required this.error,
  });

  final TunnelStatus status;
  final NetworkMode mode;
  final Color statusColor;
  final String statsLabel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NetworkSimulatorTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                status.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NetworkSimulatorTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mode.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NetworkSimulatorTheme.accentSoft,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(statsLabel, style: Theme.of(context).textTheme.bodyMedium),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: NetworkSimulatorTheme.error)),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.isActive,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isActive;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF374151), const Color(0xFF1F2937)]
              : [NetworkSimulatorTheme.accent, const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? null
            : [
                BoxShadow(
                  color: NetworkSimulatorTheme.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: NetworkSimulatorTheme.textPrimary,
                    ),
                  )
                else
                  Icon(
                    isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: NetworkSimulatorTheme.textPrimary,
                  ),
                const SizedBox(width: 8),
                Text(
                  isLoading
                      ? 'Starting VPN…'
                      : isActive
                      ? 'Stop tunnel'
                      : 'Start tunnel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: NetworkSimulatorTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final NetworkMode mode;
  final bool selected;
  final VoidCallback onTap;

  String get _subtitle {
    switch (mode) {
      case NetworkMode.normal:
        return 'Real network speed — no artificial limits';
      case NetworkMode.slow3G:
        return '~800 ms latency · ~0.5 Mbps';
      case NetworkMode.slow2G:
        return '~2000 ms latency · ~0.1 Mbps';
      case NetworkMode.offline:
        return 'Blocks all traffic';
      default:
        return mode.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? NetworkSimulatorTheme.accent.withValues(alpha: 0.08)
          : NetworkSimulatorTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? NetworkSimulatorTheme.accent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? NetworkSimulatorTheme.accentSoft
                    : NetworkSimulatorTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
