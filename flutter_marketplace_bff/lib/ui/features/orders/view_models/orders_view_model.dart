import 'package:flutter/foundation.dart';

import '../../../../data/repositories/order_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../domain/models/order.dart';

sealed class OrdersState {
  const OrdersState();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);

  final List<Order> orders;
}

final class OrdersFailure extends OrdersState {
  const OrdersFailure(this.message);

  final String message;
}

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel({required this._repository});

  final OrderRepository _repository;

  OrdersState _state = const OrdersLoading();
  OrdersState get state => _state;

  bool _disposed = false;

  Future<void> load() async {
    if (_state is! OrdersLoaded) _setState(const OrdersLoading());
    try {
      _setState(OrdersLoaded(await _repository.getOrders()));
    } on BffException catch (error) {
      _setState(OrdersFailure(error.message));
    } on FormatException {
      _setState(const OrdersFailure('Recebemos dados inesperados.'));
    }
  }

  void _setState(OrdersState state) {
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
