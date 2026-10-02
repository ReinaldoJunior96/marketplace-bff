import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mobile_home_api_model.dart';
import '../models/mobile_notification_api_model.dart';
import '../models/mobile_order_api_model.dart';
import '../models/mobile_product_detail_api_model.dart';
import 'bff_exception.dart';

/// Cliente HTTP dos contratos `/api/mobile/*` do Marketplace BFF.
class BffApiClient {
  BffApiClient({
    required this._client,
    required this._baseUrl,
    this._timeout = const Duration(seconds: 8),
  });

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  Future<MobileHomeApiModel> getMobileHome() async {
    return MobileHomeApiModel.fromJson(await _getObject('/api/mobile/home'));
  }

  Future<MobileProductDetailApiModel> getProduct(String id) async {
    final path = '/api/mobile/products/${Uri.encodeComponent(id)}';
    return MobileProductDetailApiModel.fromJson(await _getObject(path));
  }

  /// Cria o pedido. O [correlationId] é propagado pelo BFF para o Order
  /// Service e para os eventos — é com ele que o app rastreia o fluxo.
  Future<CreatedOrderApiModel> createOrder(
    CreateOrderRequest request, {
    required String correlationId,
  }) async {
    final json = await _send(
      () => _client.post(
        _baseUrl.resolve('/api/mobile/orders'),
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json; charset=utf-8',
          'x-correlation-id': correlationId,
        },
        body: jsonEncode(request.toJson()),
      ),
      expectedStatus: 201,
    );
    return CreatedOrderApiModel.fromJson(_asObject(json));
  }

  Future<List<MobileOrderApiModel>> getOrders() async {
    final json = await _get('/api/mobile/orders');
    return [
      for (final order in _asList(json))
        MobileOrderApiModel.fromJson(_asObject(order)),
    ];
  }

  Future<OrderTimelineApiModel> getOrderTimeline(String orderId) async {
    final path = '/api/mobile/orders/${Uri.encodeComponent(orderId)}/timeline';
    return OrderTimelineApiModel.fromJson(await _getObject(path));
  }

  Future<List<MobileNotificationApiModel>> getNotifications(
    String customerId,
  ) async {
    final json = await _get(
      Uri(
        path: '/api/mobile/notifications',
        queryParameters: {'customerId': customerId},
      ).toString(),
    );
    return [
      for (final notification in _asList(json))
        MobileNotificationApiModel.fromJson(_asObject(notification)),
    ];
  }

  Future<Map<String, dynamic>> _getObject(String path) async =>
      _asObject(await _get(path));

  Future<Object?> _get(String path) => _send(
    () => _client.get(
      _baseUrl.resolve(path),
      headers: {'accept': 'application/json'},
    ),
  );

  Future<Object?> _send(
    Future<http.Response> Function() request, {
    int expectedStatus = 200,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const BffException(message: 'O servidor demorou para responder.');
    } on http.ClientException {
      throw const BffException(
        message: 'Não foi possível conectar ao servidor.',
      );
    }

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != expectedStatus) {
      throw BffException.fromResponse(response.statusCode, body);
    }
    return jsonDecode(body);
  }

  Map<String, dynamic> _asObject(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Resposta do BFF não é um objeto JSON.');
    }
    return json;
  }

  List<Object?> _asList(Object? json) {
    if (json is! List<Object?>) {
      throw const FormatException('Resposta do BFF não é uma lista JSON.');
    }
    return json;
  }
}
