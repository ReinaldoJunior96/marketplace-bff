import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'config/bff_config.dart';
import 'data/repositories/home_repository.dart';
import 'data/services/bff_api_client.dart';

void main() {
  final apiClient = BffApiClient(
    client: http.Client(),
    baseUrl: BffConfig.baseUrl,
  );

  runApp(MarketplaceApp(homeRepository: HomeRepository(apiClient: apiClient)));
}
