import 'dart:convert';

import 'package:flutter_marketplace_bff/data/repositories/notification_repository.dart';
import 'package:flutter_marketplace_bff/data/repositories/order_repository.dart';
import 'package:flutter_marketplace_bff/data/repositories/product_repository.dart';
import 'package:flutter_marketplace_bff/data/services/bff_api_client.dart';
import 'package:flutter_marketplace_bff/data/services/correlation_id.dart';
import 'package:flutter_marketplace_bff/domain/models/cart_line.dart';
import 'package:flutter_marketplace_bff/domain/models/order.dart';
import 'package:flutter_marketplace_bff/domain/models/order_timeline.dart';
import 'package:flutter_marketplace_bff/domain/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  BffApiClient apiReturning(Map<String, Object?> responsesByPath) {
    requests = [];
    return BffApiClient(
      client: MockClient((request) async {
        requests.add(request);
        final json = responsesByPath[request.url.path];
        return http.Response.bytes(
          utf8.encode(jsonEncode(json)),
          request.method == 'POST' ? 201 : 200,
        );
      }),
      baseUrl: Uri.parse('http://bff.test'),
    );
  }

  group('OrderRepository', () {
    test(
      'placeOrder envia as linhas do carrinho para o cliente demo',
      () async {
        final repository = OrderRepository(
          apiClient: apiReturning({
            '/api/mobile/orders': {
              'id': 'order-1',
              'customerId': 'customer-demo',
              'items': [<String, Object>{}, <String, Object>{}],
              'status': 'CREATED',
              'createdAt': '2026-10-02T12:00:00.000Z',
            },
          }),
          customerId: 'customer-demo',
        );

        final order = await repository.placeOrder(const [
          CartLine(
            product: Product(
              id: 'product-001',
              name: 'Teclado',
              priceInCents: 39990,
              thumbnailUrl: '',
            ),
            quantity: 2,
          ),
          CartLine(
            product: Product(
              id: 'product-002',
              name: 'Mouse',
              priceInCents: 18990,
              thumbnailUrl: '',
            ),
            quantity: 1,
          ),
        ], correlationId: 'corr-1');

        expect(jsonDecode(requests.single.body), {
          'customerId': 'customer-demo',
          'items': [
            {'productId': 'product-001', 'quantity': 2},
            {'productId': 'product-002', 'quantity': 1},
          ],
        });
        expect(order.status, OrderStatus.created);
        expect(order.itemsCount, 2);
        expect(order.createdAt, DateTime.utc(2026, 10, 2, 12));
      },
    );

    test('getOrders ordena do mais recente para o mais antigo', () async {
      final repository = OrderRepository(
        apiClient: apiReturning({
          '/api/mobile/orders': [
            {
              'id': 'old',
              'status': 'CREATED',
              'itemsCount': 1,
              'createdAt': '2026-10-01T12:00:00.000Z',
            },
            {
              'id': 'new',
              'status': 'CREATED',
              'itemsCount': 3,
              'createdAt': '2026-10-02T12:00:00.000Z',
            },
          ],
        }),
        customerId: 'customer-demo',
      );

      final orders = await repository.getOrders();

      expect(orders.map((o) => o.id), ['new', 'old']);
    });

    test('getTimeline converte os eventos conhecidos', () async {
      final repository = OrderRepository(
        apiClient: apiReturning({
          '/api/mobile/orders/order-1/timeline': {
            'orderId': 'order-1',
            'steps': [
              {
                'event': 'order.created',
                'service': 'order-service',
                'occurredAt': '2026-10-02T12:00:00.000Z',
                'auditedAt': '2026-10-02T12:00:00.100Z',
              },
              {
                'event': 'payment.refunded',
                'service': 'unknown',
                'occurredAt': '2026-10-02T12:00:01.000Z',
                'auditedAt': '2026-10-02T12:00:01.100Z',
              },
            ],
          },
        }),
        customerId: 'customer-demo',
      );

      final steps = await repository.getTimeline('order-1');

      expect(steps.map((s) => s.event), [
        OrderEvent.orderCreated,
        OrderEvent.unknown,
      ]);
    });
  });

  test('ProductRepository converte o preço para centavos', () async {
    final repository = ProductRepository(
      apiClient: apiReturning({
        '/api/mobile/products/product-003': {
          'id': 'product-003',
          'name': 'Monitor',
          'description': 'IPS.',
          'price': 1799.9,
          'image': 'https://example.com/monitor.jpg',
          'category': 'Monitores',
          'stock': 0,
        },
      }),
    );

    final product = await repository.getProduct('product-003');

    expect(product.priceInCents, 179990);
    expect(product.inStock, isFalse);
    expect(product.summary.thumbnailUrl, 'https://example.com/monitor.jpg');
  });

  test('NotificationRepository consulta o cliente configurado', () async {
    final repository = NotificationRepository(
      apiClient: apiReturning({'/api/mobile/notifications': <Object>[]}),
      customerId: 'customer-demo',
    );

    await repository.getNotifications();

    expect(requests.single.url.queryParameters['customerId'], 'customer-demo');
  });

  test('generateCorrelationId gera UUIDs v4 distintos', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final a = generateCorrelationId();
    final b = generateCorrelationId();

    expect(a, matches(uuid));
    expect(b, matches(uuid));
    expect(a, isNot(b));
  });
}
