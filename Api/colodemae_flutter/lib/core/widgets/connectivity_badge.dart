import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/connection_status.dart';

class _ConnVisuals {
  const _ConnVisuals({required this.icon, required this.label, required this.background, required this.color});

  final IconData icon;
  final String label;
  final Color background;
  final Color color;
}

const Map<ConnectionStatus, _ConnVisuals> _visuals = {
  ConnectionStatus.online: _ConnVisuals(
    icon: LucideIcons.wifi,
    label: 'Online',
    background: Color(0xFFE8F5E9),
    color: Color(0xFF388E3C),
  ),
  ConnectionStatus.offline: _ConnVisuals(
    icon: LucideIcons.wifiOff,
    label: 'Offline',
    background: Color(0xFFFBE9E7),
    color: Color(0xFFD84315),
  ),
  ConnectionStatus.syncing: _ConnVisuals(
    icon: LucideIcons.refreshCw,
    label: 'Sincronizando…',
    background: Color(0xFFFFF3E0),
    color: Color(0xFFE65100),
  ),
};

/// Indicador de conectividade (RF11) — apenas demonstrativo, como no protótipo original.
class ConnectivityBadge extends StatefulWidget {
  const ConnectivityBadge({super.key, required this.status});

  final ConnectionStatus status;

  @override
  State<ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<ConnectivityBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.status == ConnectionStatus.syncing) _controller.repeat();
  }

  @override
  void didUpdateWidget(ConnectivityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == ConnectionStatus.syncing) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visuals = _visuals[widget.status]!;
    final icon = Icon(visuals.icon, size: 14, color: visuals.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: visuals.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.status == ConnectionStatus.syncing
              ? RotationTransition(turns: _controller, child: icon)
              : icon,
          const SizedBox(width: 6),
          Text(visuals.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: visuals.color)),
        ],
      ),
    );
  }
}
