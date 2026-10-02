import 'product.dart';

/// Produto com os dados da tela de detalhe.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInCents,
    required this.imageUrl,
    required this.category,
    required this.stock,
  });

  final String id;
  final String name;
  final String description;
  final int priceInCents;
  final String imageUrl;
  final String category;
  final int stock;

  bool get inStock => stock > 0;

  /// Versão resumida usada na vitrine e no carrinho.
  Product get summary => Product(
    id: id,
    name: name,
    priceInCents: priceInCents,
    thumbnailUrl: imageUrl,
  );
}
