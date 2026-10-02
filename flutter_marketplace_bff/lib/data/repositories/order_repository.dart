import '../../domain/models/cart_line.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_timeline.dart';
import '../models/mobile_order_api_model.dart';
import '../services/bff_api_client.dart';

/// Pedidos do cliente demo, criados e consultados pelo BFF.
class OrderRepository {
  OrderRepository({required this._apiClient, required this._customerId});

  final BffApiClient _apiClient;
  final String _customerId;

  Future<Order> placeOrder(
    List<CartLine> lines, {
    required String correlationId,
  }) async {
    final created = await _apiClient.createOrder(
      CreateOrderRequest(
        customerId: _customerId,
        items: [
          for (final line in lines)
            CreateOrderItemRequest(
              productId: line.product.id,
              quantity: line.quantity,
            ),
        ],
      ),
      correlationId: correlationId,
    );
    return Order(
      id: created.id,
      status: OrderStatus.parse(created.status),
      itemsCount: created.itemsCount,
      createdAt: DateTime.parse(created.createdAt),
    );
  }

  /// Pedidos mais recentes primeiro.
  Future<List<Order>> getOrders() async {
    final orders = await _apiClient.getOrders();
    return [
      for (final order in orders)
        Order(
          id: order.id,
          status: OrderStatus.parse(order.status),
          itemsCount: order.itemsCount,
          createdAt: DateTime.parse(order.createdAt),
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<OrderTimelineStep>> getTimeline(String orderId) async {
    final timeline = await _apiClient.getOrderTimeline(orderId);
    return [
      for (final step in timeline.steps)
        OrderTimelineStep(
          event: OrderEvent.parse(step.event),
          service: step.service,
          occurredAt: DateTime.parse(step.occurredAt),
          auditedAt: DateTime.parse(step.auditedAt),
        ),
    ];
  }
}
