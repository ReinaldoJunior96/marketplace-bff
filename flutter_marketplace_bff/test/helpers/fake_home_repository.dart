import 'package:flutter_marketplace_bff/data/repositories/home_repository.dart';
import 'package:flutter_marketplace_bff/domain/models/product.dart';

/// Repositório controlável pelos testes, sem rede.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository(this.onGetHomeProducts);

  Future<List<Product>> Function() onGetHomeProducts;
  int calls = 0;

  @override
  Future<List<Product>> getHomeProducts() {
    calls++;
    return onGetHomeProducts();
  }
}

const sampleProducts = [
  Product(
    id: 'product-001',
    name: 'Teclado Mecânico',
    priceInCents: 39990,
    thumbnailUrl: 'https://example.com/teclado.png',
  ),
  Product(
    id: 'product-002',
    name: 'Mouse Sem Fio',
    priceInCents: 18990,
    thumbnailUrl: 'https://example.com/mouse.png',
  ),
  Product(
    id: 'product-003',
    name: 'Monitor 27 Polegadas',
    priceInCents: 179990,
    thumbnailUrl: 'https://example.com/monitor.png',
  ),
];
