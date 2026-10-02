import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mobile_home_api_model.dart';
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
    final json = await _getJson('/api/mobile/home');
    return MobileHomeApiModel.fromJson(json);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final http.Response response;
    try {
      response = await _client
          .get(_baseUrl.resolve(path), headers: {'accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const BffException(message: 'O servidor demorou para responder.');
    } on http.ClientException {
      throw const BffException(
        message: 'Não foi possível conectar ao servidor.',
      );
    }

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw BffException.fromResponse(response.statusCode, body);
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta do BFF não é um objeto JSON.');
    }
    return decoded;
  }
}
