import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/controller.dart';
import 'control_panel.dart';
import 'floating_button.dart';

/// Draggable debug overlay entry point for the network simulator UI.
class NetworkSimulatorOverlay {
  NetworkSimulatorOverlay._();

  static OverlayEntry? _entry;

  /// Inserts a floating control button into the app's navigator overlay.
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
        builder: (context) =>
            _NetworkSimulatorOverlayLayer(controller: controller),
      );
      overlay.insert(_entry!);
    });
  }

  /// Removes the overlay entry if it was previously attached.
  static void detach() {
    _entry?.remove();
    _entry = null;
  }
}

class _NetworkSimulatorOverlayLayer extends StatefulWidget {
  const _NetworkSimulatorOverlayLayer({required this.controller});

  final NetworkSimulatorController controller;

  @override
  State<_NetworkSimulatorOverlayLayer> createState() =>
      _NetworkSimulatorOverlayLayerState();
}

class _NetworkSimulatorOverlayLayerState
    extends State<_NetworkSimulatorOverlayLayer> {
  final double _buttonSize = 44;
  late double _top;
  late double _left;

  @override
  void initState() {
    super.initState();
    _top = 100;
    _left = 16;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      top: _top,
      left: _left,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _top = (_top + details.delta.dy).clamp(
              0,
              size.height - _buttonSize,
            );
            _left = (_left + details.delta.dx).clamp(
              0,
              size.width - _buttonSize,
            );
          });
        },
        child: SafeArea(
          child: NetworkSimulatorFloatingButton(
            onPressed: () =>
                NetworkSimulatorControlPanel.show(context, widget.controller),
          ),
        ),
      ),
    );
  }
}
