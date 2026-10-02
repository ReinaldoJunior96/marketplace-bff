import 'dart:async';
import 'dart:convert';

import 'package:flutter_marketplace_bff/data/services/bff_api_client.dart';
import 'package:flutter_marketplace_bff/data/services/bff_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUrl = Uri.parse('http://bff.test:3000');

  BffApiClient clientReturning(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    return BffApiClient(
      client: MockClient(handler),
      baseUrl: baseUrl,
      timeout: timeout,
    );
  }

  group('BffApiClient.getMobileHome', () {
    test('chama GET /api/mobile/home e decodifica UTF-8', () async {
      late http.Request sent;
      final client = clientReturning((request) async {
        sent = request;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'products': [
                {
                  'id': 'product-001',
                  'name': 'Teclado Mecânico',
                  'price': 399.9,
                  'thumbnail': 'https://example.com/teclado.png',
                },
              ],
            }),
          ),
          200,
        );
      });

      final home = await client.getMobileHome();

      expect(sent.method, 'GET');
      expect(sent.url.toString(), 'http://bff.test:3000/api/mobile/home');
      expect(sent.headers['accept'], 'application/json');
      expect(home.products.single.name, 'Teclado Mecânico');
    });

    test('converte o contrato de erro do BFF em BffException', () async {
      final client = clientReturning(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 503,
            'error': 'Service Unavailable',
            'message': 'Catalog service is unavailable',
            'correlationId': 'abc-123',
          }),
          503,
        ),
      );

      expect(
        client.getMobileHome(),
        throwsA(
          isA<BffException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having(
                (e) => e.message,
                'message',
                'Catalog service is unavailable',
              )
              .having((e) => e.correlationId, 'correlationId', 'abc-123'),
        ),
      );
    });

    test('usa mensagem genérica quando o erro foge do contrato', () async {
      final client = clientReturning(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );

      expect(
        client.getMobileHome(),
        throwsA(
          isA<BffException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having(
                (e) => e.message,
                'message',
                'Erro inesperado do servidor.',
              ),
        ),
      );
    });

    test('converte falha de conexão em BffException', () async {
      final client = clientReturning(
        (_) async => throw http.ClientException('Connection refused'),
      );

      expect(
        client.getMobileHome(),
        throwsA(
          isA<BffException>().having(
            (e) => e.message,
            'message',
            'Não foi possível conectar ao servidor.',
          ),
        ),
      );
    });

    test('converte timeout em BffException', () async {
      final client = clientReturning(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        client.getMobileHome(),
        throwsA(
          isA<BffException>().having(
            (e) => e.message,
            'message',
            'O servidor demorou para responder.',
          ),
        ),
      );
    });
  });
}
