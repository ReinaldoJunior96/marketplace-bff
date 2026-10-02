import 'package:flutter/foundation.dart';

import '../../../../domain/models/cart_line.dart';
import '../../../../domain/models/product.dart';

/// Carrinho em memória, compartilhado pelo app inteiro.
class CartViewModel extends ChangeNotifier {
  final _lines = <String, CartLine>{};

  List<CartLine> get lines => List.unmodifiable(_lines.values);

  bool get isEmpty => _lines.isEmpty;

  /// Quantidade total de itens (para o badge).
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  int get totalInCents =>
      _lines.values.fold(0, (sum, line) => sum + line.totalInCents);

  int quantityOf(String productId) => _lines[productId]?.quantity ?? 0;

  void add(Product product, {int quantity = 1}) {
    assert(quantity > 0, 'quantity must be positive');
    final current = _lines[product.id];
    _lines[product.id] = CartLine(
      product: product,
      quantity: (current?.quantity ?? 0) + quantity,
    );
    notifyListeners();
  }

  void increment(String productId) => _changeBy(productId, 1);

  /// Ao chegar a zero, o item sai do carrinho.
  void decrement(String productId) => _changeBy(productId, -1);

  void remove(String productId) {
    if (_lines.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }

  void _changeBy(String productId, int delta) {
    final line = _lines[productId];
    if (line == null) return;
    final quantity = line.quantity + delta;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      _lines[productId] = line.copyWith(quantity: quantity);
    }
    notifyListeners();
  }
}
