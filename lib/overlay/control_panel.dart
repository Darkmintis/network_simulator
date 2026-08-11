import 'package:flutter/material.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../core/tunnel_status.dart';

class NetworkSimulatorControlPanel extends StatefulWidget {
  const NetworkSimulatorControlPanel({super.key, required this.controller});

  final NetworkSimulatorController controller;

  static bool _isOpen = false;

  static Future<void> show(
    BuildContext context,
    NetworkSimulatorController controller,
  ) async {
    if (_isOpen) return;
    _isOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NetworkSimulatorControlPanel(controller: controller),
    );
    _isOpen = false;
  }

  @override
  State<NetworkSimulatorControlPanel> createState() =>
      _NetworkSimulatorControlPanelState();
}

class _NetworkSimulatorControlPanelState
    extends State<NetworkSimulatorControlPanel> {
  late NetworkMode _mode;
  late double _latencyMs;
  late double _downloadMbps;
  late double _uploadMbps;
  late double _jitterMs;
  late double _packetLoss;

  @override
  void initState() {
    super.initState();
    _syncFromController();
  }

  void _syncFromController() {
    _mode = widget.controller.mode;
    _latencyMs = widget.controller.latencyMs;
    _downloadMbps = widget.controller.downloadMbps.isFinite
        ? widget.controller.downloadMbps
        : 100;
    _uploadMbps = widget.controller.uploadMbps.isFinite
        ? widget.controller.uploadMbps
        : 100;
    _jitterMs = widget.controller.jitterMs;
    _packetLoss = widget.controller.packetLoss;
  }

  Future<void> _toggleTunnel() async {
    final controller = widget.controller;
    if (controller.status == TunnelStatus.connected ||
        controller.status == TunnelStatus.connecting) {
      await controller.stopTunnel();
    } else {
      await controller.startTunnel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final status = widget.controller.status;
            final stats = widget.controller.stats;
            final error = widget.controller.lastError;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.vpn_lock,
                            color: Color(0xFF67E8F9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Network Simulator',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${status.label} · ${_mode.label}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _toggleTunnel,
                      icon: Icon(
                        status == TunnelStatus.connected
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      label: Text(
                        status == TunnelStatus.connected ||
                                status == TunnelStatus.connecting
                            ? 'Stop tunnel'
                            : 'Start tunnel',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error,
                        style: const TextStyle(color: Color(0xFFF87171)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      stats.summary,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    _ModeField(
                      value: _mode,
                      onChanged: (value) => setState(() => _mode = value),
                    ),
                    const SizedBox(height: 16),
                    _SliderRow(
                      label: 'Latency',
                      valueLabel: '${_latencyMs.round()} ms',
                      value: _latencyMs,
                      min: 0,
                      max: 3000,
                      onChanged: (value) =>
                          setState(() => _latencyMs = value),
                    ),
                    _SliderRow(
                      label: 'Download',
                      valueLabel: '${_downloadMbps.toStringAsFixed(1)} Mbps',
                      value: _downloadMbps,
                      min: 0.05,
                      max: 50,
                      onChanged: (value) =>
                          setState(() => _downloadMbps = value),
                    ),
                    _SliderRow(
                      label: 'Upload',
                      valueLabel: '${_uploadMbps.toStringAsFixed(1)} Mbps',
                      value: _uploadMbps,
                      min: 0.05,
                      max: 50,
                      onChanged: (value) =>
                          setState(() => _uploadMbps = value),
                    ),
                    _SliderRow(
                      label: 'Jitter',
                      valueLabel: '${_jitterMs.round()} ms',
                      value: _jitterMs,
                      min: 0,
                      max: 500,
                      onChanged: (value) => setState(() => _jitterMs = value),
                    ),
                    _SliderRow(
                      label: 'Packet Loss',
                      valueLabel: '${(_packetLoss * 100).round()}%',
                      value: _packetLoss,
                      min: 0,
                      max: 1,
                      onChanged: (value) =>
                          setState(() => _packetLoss = value),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            widget.controller.enableOffline();
                            _syncFromController();
                            setState(() {});
                          },
                          child: const Text('Offline'),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            widget.controller.reset();
                            _syncFromController();
                            setState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (_mode == NetworkMode.offline) {
                              widget.controller.enableOffline();
                            } else if (_mode == NetworkMode.normal) {
                              widget.controller.reset();
                            } else if (_mode == NetworkMode.custom) {
                              widget.controller.setCustom(
                                latencyMs: _latencyMs,
                                downloadMbps: _downloadMbps,
                                uploadMbps: _uploadMbps,
                                jitterMs: _jitterMs,
                                packetLoss: _packetLoss,
                              );
                            } else {
                              widget.controller.setMode(_mode);
                              widget.controller.setCustom(
                                latencyMs: _latencyMs,
                                downloadMbps: _downloadMbps,
                                uploadMbps: _uploadMbps,
                                jitterMs: _jitterMs,
                                packetLoss: _packetLoss,
                              );
                            }
                            _syncFromController();
                            setState(() {});
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tunnel shapes all app traffic at the OS level. '
                      'Android is supported; iOS is experimental.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}

class _ModeField extends StatelessWidget {
  const _ModeField({required this.value, required this.onChanged});

  final NetworkMode value;
  final ValueChanged<NetworkMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<NetworkMode>(
      initialValue: value,
      dropdownColor: const Color(0xFF0F172A),
      decoration: InputDecoration(
        labelText: 'Mode',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: NetworkMode.values
          .map(
            (mode) => DropdownMenuItem<NetworkMode>(
              value: mode,
              child: Text(mode.label, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text(valueLabel, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
