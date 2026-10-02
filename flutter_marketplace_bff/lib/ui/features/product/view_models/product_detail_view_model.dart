import 'package:flutter/foundation.dart';

import '../../../../data/repositories/product_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/product_detail.dart';
import '../../cart/view_models/cart_view_model.dart';

sealed class ProductDetailState {
  const ProductDetailState();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product);

  final ProductDetail product;
}

final class ProductDetailFailure extends ProductDetailState {
  const ProductDetailFailure(this.message);

  final String message;
}

class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel({
    required this.preview,
    required this._repository,
    required this._cart,
  });

  /// Dados já conhecidos da vitrine — exibidos enquanto o detalhe carrega.
  final Product preview;
  final ProductRepository _repository;
  final CartViewModel _cart;

  static const maxQuantity = 10;

  ProductDetailState _state = const ProductDetailLoading();
  ProductDetailState get state => _state;

  int _quantity = 1;
  int get quantity => _quantity;

  bool _disposed = false;

  int get maxSelectable => switch (_state) {
    ProductDetailLoaded(:final product) =>
      product.stock < maxQuantity ? product.stock : maxQuantity,
    _ => maxQuantity,
  };

  Future<void> load() async {
    _setState(const ProductDetailLoading());
    try {
      _setState(ProductDetailLoaded(await _repository.getProduct(preview.id)));
    } on BffException catch (error) {
      _setState(ProductDetailFailure(error.message));
    } on FormatException {
      _setState(const ProductDetailFailure('Recebemos dados inesperados.'));
    }
  }

  void incrementQuantity() {
    if (_quantity >= maxSelectable) return;
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity <= 1) return;
    _quantity--;
    notifyListeners();
  }

  /// Adiciona ao carrinho; retorna `false` se o produto ainda não carregou
  /// ou estiver sem estoque.
  bool addToCart() {
    final state = _state;
    if (state is! ProductDetailLoaded || !state.product.inStock) return false;
    _cart.add(state.product.summary, quantity: _quantity);
    return true;
  }

  void _setState(ProductDetailState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
