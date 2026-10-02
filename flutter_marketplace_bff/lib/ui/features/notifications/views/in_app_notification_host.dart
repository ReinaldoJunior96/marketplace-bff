import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/app_notification.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../view_models/notifications_view_model.dart';

/// Exibe um aviso no topo, sobre qualquer tela, quando chega notificação.
class InAppNotificationHost extends StatefulWidget {
  const InAppNotificationHost({
    super.key,
    required this.notifications,
    required this.onOpen,
    required this.child,
  });

  final NotificationsViewModel notifications;
  final VoidCallback onOpen;
  final Widget child;

  @override
  State<InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 5);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    reverseDuration: AppMotion.fast,
  );
  AppNotification? _current;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.notifications.incoming.addListener(_onIncoming);
  }

  void _onIncoming() {
    final notification = widget.notifications.incoming.value;
    if (notification == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _current = notification);
    _controller.forward(from: 0);
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleFor, _hide);
  }

  Future<void> _hide() async {
    _hideTimer?.cancel();
    await _controller.reverse();
    widget.notifications.dismissIncoming();
  }

  void _open() {
    _hide();
    widget.onOpen();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.notifications.incoming.removeListener(_onIncoming);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        widget.child,
        if (current != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -1.6),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: _controller,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _Banner(
                      notification: current,
                      onTap: _open,
                      onDismiss: _hide,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.up,
        onDismissed: (_) => onDismiss(),
        child: Material(
          color: AppColors.espresso,
          elevation: 8,
          shadowColor: AppColors.espresso.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const _RingingBell(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.cream,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 12,
                    color: AppColors.stone,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sino que balança ao aparecer.
class _RingingBell extends StatelessWidget {
  const _RingingBell();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      builder: (context, t, child) {
        // Oscilação amortecida.
        final angle = 0.5 * (1 - t) * math.sin(t * 6 * 2 * math.pi);
        return Transform.rotate(angle: angle, child: child);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.terracotta,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const FaIcon(
          FontAwesomeIcons.solidBell,
          size: 16,
          color: AppColors.cream,
        ),
      ),
    );
  }
}
