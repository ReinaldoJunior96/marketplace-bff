import 'dart:convert';

import 'package:flutter_marketplace_bff/data/models/mobile_order_api_model.dart';
import 'package:flutter_marketplace_bff/data/services/bff_api_client.dart';
import 'package:flutter_marketplace_bff/data/services/bff_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Endpoints do fluxo de compra: produto, pedido, timeline e notificações.
void main() {
  late List<http.Request> requests;

  BffApiClient clientRespondingWith(Object? json, {int status = 200}) {
    requests = [];
    return BffApiClient(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(json)), status);
      }),
      baseUrl: Uri.parse('http://bff.test'),
    );
  }

  test('getProduct busca o detalhe mobile do produto', () async {
    final client = clientRespondingWith({
      'id': 'product-001',
      'name': 'Teclado Mecânico',
      'description': 'Compacto.',
      'price': 399.9,
      'image': 'https://example.com/teclado.jpg',
      'category': 'Periféricos',
      'stock': 10,
    });

    final product = await client.getProduct('product-001');

    expect(requests.single.url.path, '/api/mobile/products/product-001');
    expect(product.name, 'Teclado Mecânico');
    expect(product.stock, 10);
  });

  test('createOrder envia o pedido com o x-correlation-id', () async {
    final client = clientRespondingWith({
      'id': 'order-1',
      'customerId': 'customer-terrashop',
      'items': [
        {'productId': 'product-001', 'quantity': 2},
      ],
      'status': 'CREATED',
      'createdAt': '2026-10-02T12:00:00.000Z',
    }, status: 201);

    final order = await client.createOrder(
      const CreateOrderRequest(
        customerId: 'customer-terrashop',
        items: [CreateOrderItemRequest(productId: 'product-001', quantity: 2)],
      ),
      correlationId: 'corr-123',
    );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/mobile/orders');
    expect(request.headers['x-correlation-id'], 'corr-123');
    expect(jsonDecode(request.body), {
      'customerId': 'customer-terrashop',
      'items': [
        {'productId': 'product-001', 'quantity': 2},
      ],
    });
    expect(order.id, 'order-1');
    expect(order.itemsCount, 1);
  });

  test('createOrder repassa a validação do BFF como BffException', () {
    final client = clientRespondingWith({
      'statusCode': 400,
      'error': 'Bad Request',
      'message': 'items must be a non-empty array',
      'correlationId': 'corr-123',
    }, status: 400);

    expect(
      client.createOrder(
        const CreateOrderRequest(customerId: 'c', items: []),
        correlationId: 'corr-123',
      ),
      throwsA(
        isA<BffException>().having(
          (e) => e.message,
          'message',
          'items must be a non-empty array',
        ),
      ),
    );
  });

  test('getNotifications envia o customerId na query', () async {
    final client = clientRespondingWith([
      {
        'id': 'n-1',
        'orderId': 'order-1',
        'title': 'Pedido confirmado',
        'message': 'Seu pedido #order-1 foi recebido.',
        'sentAt': '2026-10-02T12:00:01.000Z',
      },
    ]);

    final notifications = await client.getNotifications('customer terrashop');

    expect(requests.single.url.path, '/api/mobile/notifications');
    expect(
      requests.single.url.queryParameters['customerId'],
      'customer terrashop',
    );
    expect(notifications.single.title, 'Pedido confirmado');
  });

  test('getOrderTimeline lê as etapas do pedido', () async {
    final client = clientRespondingWith({
      'orderId': 'order-1',
      'steps': [
        {
          'event': 'order.created',
          'service': 'order-service',
          'occurredAt': '2026-10-02T12:00:00.000Z',
          'auditedAt': '2026-10-02T12:00:00.100Z',
        },
      ],
    });

    final timeline = await client.getOrderTimeline('order-1');

    expect(requests.single.url.path, '/api/mobile/orders/order-1/timeline');
    expect(timeline.steps.single.service, 'order-service');
  });

  test('getOrders exige uma lista', () {
    final client = clientRespondingWith({'orders': <Object>[]});

    expect(client.getOrders(), throwsFormatException);
  });
}
