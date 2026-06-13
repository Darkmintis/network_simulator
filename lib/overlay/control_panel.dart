import 'package:flutter/material.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../models/network_log.dart';

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
  State<NetworkSimulatorControlPanel> createState() => _NetworkSimulatorControlPanelState();
}

class _NetworkSimulatorControlPanelState extends State<NetworkSimulatorControlPanel> {
  late NetworkMode _mode;
  late double _latencyMs;
  late double _bandwidthMbps;
  late double _packetLoss;

  @override
  void initState() {
    super.initState();
    _syncFromController();
  }

  void _syncFromController() {
    _mode = widget.controller.mode;
    _latencyMs = widget.controller.latencyMs;
    _bandwidthMbps = widget.controller.bandwidthMbps.isFinite
        ? widget.controller.bandwidthMbps
        : 100;
    _packetLoss = widget.controller.packetLoss;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
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
          animation: widget.controller.logger,
          builder: (context, _) {
            final logs = widget.controller.logger.logs;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.84,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22D3EE,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.wifi, color: Color(0xFF67E8F9)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Network Simulator Panel',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_mode.label} · ${widget.controller.isOffline ? 'Offline' : 'Live simulation'}',
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
                  const SizedBox(height: 20),
                  _ModeField(
                    value: _mode,
                    onChanged: (value) {
                      setState(() {
                        _mode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _SliderRow(
                    label: 'Latency',
                    valueLabel: '${_latencyMs.round()} ms',
                    value: _latencyMs,
                    min: 0,
                    max: 3000,
                    onChanged: (value) => setState(() => _latencyMs = value),
                  ),
                  _SliderRow(
                    label: 'Bandwidth',
                    valueLabel: '${_bandwidthMbps.toStringAsFixed(1)} Mbps',
                    value: _bandwidthMbps,
                    min: 0.1,
                    max: 20,
                    onChanged: (value) =>
                        setState(() => _bandwidthMbps = value),
                  ),
                  _SliderRow(
                    label: 'Packet Loss',
                    valueLabel: '${(_packetLoss * 100).round()}%',
                    value: _packetLoss,
                    min: 0,
                    max: 1,
                    onChanged: (value) => setState(() => _packetLoss = value),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          widget.controller.enableOffline();
                          Navigator.of(context).maybePop();
                        },
                        child: const Text('Offline'),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          widget.controller.reset();
                          Navigator.of(context).maybePop();
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
                              bandwidthMbps: _bandwidthMbps,
                              packetLoss: _packetLoss,
                            );
                          } else {
                            widget.controller.setMode(_mode);
                            widget.controller.setCustom(
                              latencyMs: _latencyMs,
                              bandwidthMbps: _bandwidthMbps,
                              packetLoss: _packetLoss,
                            );
                          }
                          Navigator.of(context).maybePop();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live logs',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.controller.logger.clear,
                        child: const Text('Clear logs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No requests yet. Trigger an API call to see Network Simulator activity here.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return _LogTile(log: log);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
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
      value: value,
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
              child: Text(mode.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
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

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final NetworkLog log;

  @override
  Widget build(BuildContext context) {
    final successColor = log.success
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);
    final icon = log.success ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: successColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.method} ${log.url}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.durationMs} ms${log.statusCode == null ? '' : ' · ${log.statusCode}'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (log.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.errorMessage ?? '',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
