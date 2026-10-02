/// Eventos do marketplace que o app sabe apresentar.
enum OrderEvent {
  orderCreated('order.created'),
  notificationSent('notification.sent'),
  unknown('');

  const OrderEvent(this.type);

  final String type;

  static OrderEvent parse(String type) => values.firstWhere(
    (event) => event.type == type,
    orElse: () => OrderEvent.unknown,
  );
}

/// Um evento do pedido já processado e registrado pelo Audit Service.
class OrderTimelineStep {
  const OrderTimelineStep({
    required this.event,
    required this.service,
    required this.occurredAt,
    required this.auditedAt,
  });

  final OrderEvent event;
  final String service;
  final DateTime occurredAt;
  final DateTime auditedAt;
}
