import '../../domain/models/product_detail.dart';
import '../services/bff_api_client.dart';
import 'price_mapper.dart';

class ProductRepository {
  ProductRepository({required this._apiClient});

  final BffApiClient _apiClient;

  Future<ProductDetail> getProduct(String id) async {
    final product = await _apiClient.getProduct(id);
    return ProductDetail(
      id: product.id,
      name: product.name,
      description: product.description,
      priceInCents: reaisToCents(product.price),
      imageUrl: product.image,
      category: product.category,
      stock: product.stock,
    );
  }
}
