import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/order.dart';
import '../../../../domain/models/order_timeline.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/app_scope.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustration.dart';
import '../view_models/order_tracking_view_model.dart';

/// Pedido confirmado + linha do tempo ao vivo dos serviços do backend.
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.correlationId,
    required this.totalInCents,
  });

  final Order order;
  final String correlationId;
  final int totalInCents;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  OrderTrackingViewModel? _tracking;
  bool _notifiedShell = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tracking != null) return;
    _tracking =
        OrderTrackingViewModel(
            orderId: widget.order.id,
            repository: AppScope.of(context).orderRepository,
          )
          ..addListener(_onTrackingChanged)
          ..start();
  }

  void _onTrackingChanged() {
    // Assim que a notificação existe no backend, pede ao app para buscá-la
    // — o aviso aparece sem esperar o próximo ciclo de polling.
    if (_tracking!.notificationSent && !_notifiedShell) {
      _notifiedShell = true;
      HapticFeedback.lightImpact();
      AppScope.of(context).notifications.poll();
    }
  }

  @override
  void dispose() {
    _tracking?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking!;
    final textTheme = Theme.of(context).textTheme;
    final scope = AppScope.of(context);
    final gutter = math.max(
      AppSpacing.xl,
      (MediaQuery.sizeOf(context).width - 560) / 2,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) scope.goToTab(AppTab.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.xl,
              gutter,
              AppSpacing.xl,
            ),
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: const Illustration(
                  AppIllustration.orderSuccess,
                  height: 180,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(
                child: Text(
                  'Pagamento aprovado!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: AppMotion.stagger,
                child: Text(
                  'Pedido #${widget.order.shortId} · '
                  '${formatBrl(widget.totalInCents)}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.terracotta,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(
                delay: AppMotion.stagger * 2,
                child: ListenableBuilder(
                  listenable: tracking,
                  builder: (context, _) =>
                      _LiveTimeline(order: widget.order, tracking: tracking),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideIn(
                delay: AppMotion.stagger * 3,
                child: _CorrelationId(value: widget.correlationId),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(
                delay: AppMotion.stagger * 4,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => scope.goToTab(AppTab.orders),
                  child: const Text('Ver meus pedidos'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: AppMotion.stagger * 5,
                child: TextButton(
                  onPressed: () => scope.goToTab(AppTab.home),
                  child: const Text('Continuar comprando'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTimeline extends StatelessWidget {
  const _LiveTimeline({required this.order, required this.tracking});

  final Order order;
  final OrderTrackingViewModel tracking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final created = tracking.stepFor(OrderEvent.orderCreated);
    final notified = tracking.stepFor(OrderEvent.notificationSent);

    final rows = [
      _TimelineRowData(
        title: 'Pagamento aprovado',
        service: 'simulado no app',
        icon: FontAwesomeIcons.creditCard,
        time: order.createdAt,
      ),
      _TimelineRowData(
        title: 'Pedido registrado',
        service: 'order-service',
        icon: FontAwesomeIcons.receipt,
        time: created?.occurredAt,
      ),
      _TimelineRowData(
        title: 'Notificação enviada',
        service: 'notification-service',
        icon: FontAwesomeIcons.solidBell,
        time: notified?.occurredAt,
      ),
      _TimelineRowData(
        title: 'Eventos auditados',
        service: 'audit-service',
        icon: FontAwesomeIcons.shieldHalved,
        time: notified?.auditedAt,
      ),
    ];
    final activeIndex = rows.indexWhere((row) => row.time == null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.linen,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.stone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Acompanhe ao vivo', style: textTheme.titleMedium),
              ),
              _LiveDot(active: activeIndex != -1 && !tracking.timedOut),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (index, row) in rows.indexed)
            _TimelineRow(
              data: row,
              status: row.time != null
                  ? _RowStatus.done
                  : index == activeIndex && !tracking.timedOut
                  ? _RowStatus.active
                  : _RowStatus.pending,
              isLast: index == rows.length - 1,
            ),
          if (tracking.timedOut)
            Text(
              'Os serviços estão demorando. A notificação chega assim que o '
              'processamento terminar.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.mocha),
            ),
        ],
      ),
    );
  }
}

class _TimelineRowData {
  const _TimelineRowData({
    required this.title,
    required this.service,
    required this.icon,
    required this.time,
  });

  final String title;
  final String service;
  final FaIconData icon;
  final DateTime? time;
}

enum _RowStatus { pending, active, done }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.data,
    required this.status,
    required this.isLast,
  });

  final _TimelineRowData data;
  final _RowStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = status == _RowStatus.done;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.medium,
                curve: Curves.easeOutBack,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.olive : AppColors.cream,
                  border: Border.all(
                    color: switch (status) {
                      _RowStatus.done => AppColors.olive,
                      _RowStatus.active => AppColors.terracotta,
                      _RowStatus.pending => AppColors.stone,
                    },
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                      child: child,
                    ),
                    child: switch (status) {
                      _RowStatus.done => const FaIcon(
                        FontAwesomeIcons.check,
                        key: ValueKey('done'),
                        size: 14,
                        color: Colors.white,
                      ),
                      _RowStatus.active => const SizedBox.square(
                        key: ValueKey('active'),
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      _RowStatus.pending => FaIcon(
                        data.icon,
                        key: const ValueKey('pending'),
                        size: 13,
                        color: AppColors.mocha,
                      ),
                    },
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.medium,
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    color: done ? AppColors.olive : AppColors.stone,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: status == _RowStatus.pending
                                ? AppColors.mocha
                                : AppColors.espresso,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: data.time == null
                            ? const SizedBox.shrink()
                            : Text(
                                formatTime(data.time!),
                                key: const ValueKey('time'),
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.mocha,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ServiceChip(name: data.service),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontFamily: 'monospace', color: AppColors.espresso),
      ),
    );
  }
}

/// Ponto pulsando enquanto ainda há etapas pendentes.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.active});

  final bool active;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.active && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.terracotta : AppColors.olive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          widget.active ? 'ao vivo' : 'concluído',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CorrelationId extends StatelessWidget {
  const _CorrelationId({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(
          FontAwesomeIcons.fingerprint,
          size: 12,
          color: AppColors.mocha,
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: SelectableText(
            'x-correlation-id: $value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.mocha, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
