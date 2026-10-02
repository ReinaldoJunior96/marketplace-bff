/// Resposta de `GET /api/mobile/home`.
class MobileHomeApiModel {
  const MobileHomeApiModel({required this.products});

  factory MobileHomeApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'products': final List<dynamic> products} => MobileHomeApiModel(
        products: [
          for (final product in products)
            MobileProductApiModel.fromJson(product as Map<String, dynamic>),
        ],
      ),
      _ => throw const FormatException('Resposta inválida para a home.'),
    };
  }

  final List<MobileProductApiModel> products;

  Map<String, dynamic> toJson() => {
    'products': [for (final product in products) product.toJson()],
  };
}

/// Produto no contrato mobile do BFF. `price` vem em reais.
class MobileProductApiModel {
  const MobileProductApiModel({
    required this.id,
    required this.name,
    required this.price,
    required this.thumbnail,
  });

  factory MobileProductApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'name': final String name,
        'price': final num price,
        'thumbnail': final String thumbnail,
      } =>
        MobileProductApiModel(
          id: id,
          name: name,
          price: price.toDouble(),
          thumbnail: thumbnail,
        ),
      _ => throw const FormatException('Produto inválido na resposta.'),
    };
  }

  final String id;
  final String name;
  final double price;
  final String thumbnail;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'thumbnail': thumbnail,
  };
}
