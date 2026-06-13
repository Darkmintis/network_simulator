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
    if (!kDebugMode) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null || _entry != null) {
        return;
      }

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

class _NetworkSimulatorOverlayLayer extends StatelessWidget {
  const _NetworkSimulatorOverlayLayer({required this.controller});

  final NetworkSimulatorController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: SafeArea(
        child: NetworkSimulatorFloatingButton(
          onPressed: () => NetworkSimulatorControlPanel.show(context, controller),
        ),
      ),
    );
  }
}
