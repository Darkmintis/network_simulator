import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/controller.dart';
import 'control_panel.dart';
import 'floating_button.dart';

class NetworkSimulatorOverlay {
  NetworkSimulatorOverlay._();

  static OverlayEntry? _entry;

  static void attach({
    required NetworkSimulatorController controller,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    if (!kDebugMode) return;

    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null || _entry != null) return;

      _entry = OverlayEntry(
        builder: (context) => _NetworkSimulatorOverlayLayer(controller: controller),
      );
      overlay.insert(_entry!);
    });
  }

  static void detach() {
    _entry?.remove();
    _entry = null;
  }
}

class _NetworkSimulatorOverlayLayer extends StatefulWidget {
  const _NetworkSimulatorOverlayLayer({required this.controller});

  final NetworkSimulatorController controller;

  @override
  State<_NetworkSimulatorOverlayLayer> createState() => _NetworkSimulatorOverlayLayerState();
}

class _NetworkSimulatorOverlayLayerState extends State<_NetworkSimulatorOverlayLayer> {
  Offset _position = const Offset(16, 24);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: _position.dx,
      bottom: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: SafeArea(
          child: NetworkSimulatorFloatingButton(
            onPressed: () => NetworkSimulatorControlPanel.show(context, widget.controller),
          ),
        ),
      ),
    );
  }
}
