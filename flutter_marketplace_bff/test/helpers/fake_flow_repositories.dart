import 'package:flutter_marketplace_bff/data/repositories/notification_repository.dart';
import 'package:flutter_marketplace_bff/data/repositories/order_repository.dart';
import 'package:flutter_marketplace_bff/data/repositories/product_repository.dart';
import 'package:flutter_marketplace_bff/domain/models/app_notification.dart';
import 'package:flutter_marketplace_bff/domain/models/cart_line.dart';
import 'package:flutter_marketplace_bff/domain/models/order.dart';
import 'package:flutter_marketplace_bff/domain/models/order_timeline.dart';
import 'package:flutter_marketplace_bff/domain/models/product_detail.dart';

const sampleDetail = ProductDetail(
  id: 'product-001',
  name: 'Teclado Mecânico',
  description: 'Teclado mecânico compacto com iluminação ajustável.',
  priceInCents: 39990,
  imageUrl: 'https://example.com/teclado.jpg',
  category: 'Periféricos',
  stock: 3,
);

final sampleOrder = Order(
  id: 'a1b2c3d4-e5f6-4000-8000-000000000001',
  status: OrderStatus.created,
  itemsCount: 1,
  createdAt: DateTime.utc(2026, 10, 2, 12),
);

OrderTimelineStep timelineStep(OrderEvent event, String service) =>
    OrderTimelineStep(
      event: event,
      service: service,
      occurredAt: DateTime.utc(2026, 10, 2, 12),
      auditedAt: DateTime.utc(2026, 10, 2, 12, 0, 1),
    );

AppNotification notification(String id, {int minute = 0}) => AppNotification(
  id: id,
  orderId: 'order-$id',
  title: 'Pedido confirmado',
  message: 'Seu pedido #$id foi recebido.',
  sentAt: DateTime.utc(2026, 10, 2, 12, minute),
);

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.onGetProduct);

  Future<ProductDetail> Function(String id) onGetProduct;

  @override
  Future<ProductDetail> getProduct(String id) => onGetProduct(id);
}

class FakeOrderRepository implements OrderRepository {
  final placedOrders = <({List<CartLine> lines, String correlationId})>[];
  Future<Order> Function() onPlaceOrder = () async => sampleOrder;
  Future<List<Order>> Function() onGetOrders = () async => [sampleOrder];
  Future<List<OrderTimelineStep>> Function() onGetTimeline = () async => [];
  int timelineCalls = 0;

  @override
  Future<Order> placeOrder(
    List<CartLine> lines, {
    required String correlationId,
  }) {
    placedOrders.add((lines: lines, correlationId: correlationId));
    return onPlaceOrder();
  }

  @override
  Future<List<Order>> getOrders() => onGetOrders();

  @override
  Future<List<OrderTimelineStep>> getTimeline(String orderId) {
    timelineCalls++;
    return onGetTimeline();
  }
}

class FakeNotificationRepository implements NotificationRepository {
  Future<List<AppNotification>> Function() onGetNotifications = () async => [];

  @override
  Future<List<AppNotification>> getNotifications() => onGetNotifications();
}
