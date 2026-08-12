import 'package:flutter/material.dart';

/// Draggable floating action button that opens the simulator control panel.
class NetworkSimulatorFloatingButton extends StatelessWidget {
  /// Creates the overlay button that invokes [onPressed] when tapped.
  const NetworkSimulatorFloatingButton({super.key, required this.onPressed});

  /// Called when the user taps the floating button.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF22D3EE), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 20),
      ),
    );
  }
}
