/// Resposta de `GET /api/mobile/products/:id`. `price` vem em reais.
class MobileProductDetailApiModel {
  const MobileProductDetailApiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.stock,
  });

  factory MobileProductDetailApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'name': final String name,
        'description': final String description,
        'price': final num price,
        'image': final String image,
        'category': final String category,
        'stock': final int stock,
      } =>
        MobileProductDetailApiModel(
          id: id,
          name: name,
          description: description,
          price: price.toDouble(),
          image: image,
          category: category,
          stock: stock,
        ),
      _ => throw const FormatException('Produto inválido na resposta.'),
    };
  }

  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final int stock;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image': image,
    'category': category,
    'stock': stock,
  };
}
