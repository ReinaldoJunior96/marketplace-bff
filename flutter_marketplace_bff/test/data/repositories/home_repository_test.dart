import 'dart:convert';

import 'package:flutter_marketplace_bff/data/repositories/home_repository.dart';
import 'package:flutter_marketplace_bff/data/services/bff_api_client.dart';
import 'package:flutter_marketplace_bff/domain/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HomeRepository repositoryWith(List<Map<String, Object>> products) {
    final apiClient = BffApiClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'products': products})),
          200,
        ),
      ),
      baseUrl: Uri.parse('http://bff.test'),
    );
    return HomeRepository(apiClient: apiClient);
  }

  group('HomeRepository', () {
    test('mapeia o contrato da API para o modelo de domínio', () async {
      final repository = repositoryWith([
        {
          'id': 'product-001',
          'name': 'Teclado Mecânico',
          'price': 399.9,
          'thumbnail': 'https://example.com/teclado.png',
        },
      ]);

      final products = await repository.getHomeProducts();

      expect(products, const [
        Product(
          id: 'product-001',
          name: 'Teclado Mecânico',
          priceInCents: 39990,
          thumbnailUrl: 'https://example.com/teclado.png',
        ),
      ]);
    });

    test('converte reais para centavos sem erro de ponto flutuante', () async {
      final repository = repositoryWith([
        for (final (index, price) in [1799.9, 0.29, 19.99, 4.35].indexed)
          {
            'id': 'p$index',
            'name': 'Produto $index',
            'price': price,
            'thumbnail': 'https://example.com/$index.png',
          },
      ]);

      final products = await repository.getHomeProducts();

      expect(products.map((p) => p.priceInCents), [179990, 29, 1999, 435]);
    });
  });
}
