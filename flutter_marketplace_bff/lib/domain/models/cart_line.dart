import 'product.dart';

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get totalInCents => product.priceInCents * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}
