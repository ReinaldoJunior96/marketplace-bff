import '../../domain/models/product.dart';
import '../models/mobile_home_api_model.dart';
import '../services/bff_api_client.dart';
import 'price_mapper.dart';

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
      priceInCents: reaisToCents(product.price),
      thumbnailUrl: product.thumbnail,
    );
  }
}
