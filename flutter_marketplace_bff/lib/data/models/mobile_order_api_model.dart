/// Corpo de `POST /api/mobile/orders`.
class CreateOrderRequest {
  const CreateOrderRequest({required this.customerId, required this.items});

  final String customerId;
  final List<CreateOrderItemRequest> items;

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'items': [for (final item in items) item.toJson()],
  };
}

class CreateOrderItemRequest {
  const CreateOrderItemRequest({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

/// Resposta de `POST /api/mobile/orders`.
class CreatedOrderApiModel {
  const CreatedOrderApiModel({
    required this.id,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  factory CreatedOrderApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'status': final String status,
        'items': final List<dynamic> items,
        'createdAt': final String createdAt,
      } =>
        CreatedOrderApiModel(
          id: id,
          status: status,
          itemsCount: items.length,
          createdAt: createdAt,
        ),
      _ => throw const FormatException('Pedido inválido na resposta.'),
    };
  }

  final String id;
  final String status;
  final int itemsCount;
  final String createdAt;
}

/// Item de `GET /api/mobile/orders` (contrato reduzido do mobile).
class MobileOrderApiModel {
  const MobileOrderApiModel({
    required this.id,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  factory MobileOrderApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'status': final String status,
        'itemsCount': final int itemsCount,
        'createdAt': final String createdAt,
      } =>
        MobileOrderApiModel(
          id: id,
          status: status,
          itemsCount: itemsCount,
          createdAt: createdAt,
        ),
      _ => throw const FormatException('Pedido inválido na resposta.'),
    };
  }

  final String id;
  final String status;
  final int itemsCount;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'itemsCount': itemsCount,
    'createdAt': createdAt,
  };
}

/// Resposta de `GET /api/mobile/orders/:id/timeline`.
class OrderTimelineApiModel {
  const OrderTimelineApiModel({required this.orderId, required this.steps});

  factory OrderTimelineApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'orderId': final String orderId, 'steps': final List<dynamic> steps} =>
        OrderTimelineApiModel(
          orderId: orderId,
          steps: [
            for (final step in steps)
              OrderTimelineStepApiModel.fromJson(step as Map<String, dynamic>),
          ],
        ),
      _ => throw const FormatException('Timeline inválida na resposta.'),
    };
  }

  final String orderId;
  final List<OrderTimelineStepApiModel> steps;
}

class OrderTimelineStepApiModel {
  const OrderTimelineStepApiModel({
    required this.event,
    required this.service,
    required this.occurredAt,
    required this.auditedAt,
  });

  factory OrderTimelineStepApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'event': final String event,
        'service': final String service,
        'occurredAt': final String occurredAt,
        'auditedAt': final String auditedAt,
      } =>
        OrderTimelineStepApiModel(
          event: event,
          service: service,
          occurredAt: occurredAt,
          auditedAt: auditedAt,
        ),
      _ => throw const FormatException('Etapa inválida na timeline.'),
    };
  }

  final String event;
  final String service;
  final String occurredAt;
  final String auditedAt;
}
