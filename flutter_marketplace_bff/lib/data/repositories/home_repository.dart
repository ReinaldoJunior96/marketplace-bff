import '../../domain/models/product.dart';
import '../models/mobile_home_api_model.dart';
import '../services/bff_api_client.dart';

/// Fonte única dos dados da home.
class HomeRepository {
  HomeRepository({required this._apiClient});

  final BffApiClient _apiClient;

  Future<List<Product>> getHomeProducts() async {
    final home = await _apiClient.getMobileHome();
    return home.products.map(_toDomain).toList(growable: false);
  }

  Product _toDomain(MobileProductApiModel product) {
    return Product(
      id: product.id,
      name: product.name,
      // O BFF envia reais com casas decimais; convertemos para centavos
      // arredondando para eliminar o erro de ponto flutuante (399.9 * 100).
      priceInCents: (product.price * 100).round(),
      thumbnailUrl: product.thumbnail,
    );
  }
}
