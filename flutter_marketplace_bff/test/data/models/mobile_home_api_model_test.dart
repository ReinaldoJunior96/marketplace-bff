import 'package:flutter_marketplace_bff/data/models/mobile_home_api_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MobileHomeApiModel', () {
    final json = <String, dynamic>{
      'products': [
        {
          'id': 'product-001',
          'name': 'Teclado Mecânico',
          'price': 399.9,
          'thumbnail': 'https://example.com/teclado.png',
        },
        {
          'id': 'product-002',
          'name': 'Mouse',
          'price': 100,
          'thumbnail': 'https://example.com/mouse.png',
        },
      ],
    };

    test('fromJson lê o contrato mobile do BFF', () {
      final home = MobileHomeApiModel.fromJson(json);

      expect(home.products, hasLength(2));
      expect(home.products.first.id, 'product-001');
      expect(home.products.first.name, 'Teclado Mecânico');
      expect(home.products.first.price, 399.9);
      expect(home.products.first.thumbnail, 'https://example.com/teclado.png');
    });

    test('fromJson aceita preço inteiro', () {
      final home = MobileHomeApiModel.fromJson(json);

      expect(home.products.last.price, 100.0);
    });

    test('toJson faz o caminho inverso', () {
      final home = MobileHomeApiModel.fromJson(json);

      expect(
        MobileHomeApiModel.fromJson(home.toJson()).toJson(),
        home.toJson(),
      );
    });

    test('fromJson lança FormatException sem a lista de produtos', () {
      expect(
        () => MobileHomeApiModel.fromJson({'items': <Object>[]}),
        throwsFormatException,
      );
    });

    test('fromJson lança FormatException com produto incompleto', () {
      expect(
        () => MobileHomeApiModel.fromJson({
          'products': [
            {'id': 'product-001', 'name': 'Sem preço'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
