/// Produto exibido na vitrine.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceInCents,
    required this.thumbnailUrl,
  });

  final String id;
  final String name;

  /// Preço em centavos — nunca `double` para dinheiro.
  final int priceInCents;
  final String thumbnailUrl;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.priceInCents == priceInCents &&
      other.thumbnailUrl == thumbnailUrl;

  @override
  int get hashCode => Object.hash(id, name, priceInCents, thumbnailUrl);
}
