import 'package:flutter/foundation.dart';

import '../../../../data/repositories/order_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../data/services/correlation_id.dart';
import '../../../../domain/models/order.dart';
import '../../cart/view_models/cart_view_model.dart';

/// Etapas exibidas durante o pagamento. As duas primeiras são simuladas no
/// app (não há serviço de pagamento); a última cria o pedido de verdade.
enum PaymentStep { validatingCard, authorizingPayment, creatingOrder }

sealed class CheckoutState {
  const CheckoutState();
}

final class CheckoutIdle extends CheckoutState {
  const CheckoutIdle();
}

final class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing(this.step);

  final PaymentStep step;
}

final class CheckoutSuccess extends CheckoutState {
  const CheckoutSuccess({
    required this.order,
    required this.correlationId,
    required this.totalInCents,
  });

  final Order order;
  final String correlationId;
  final int totalInCents;
}

final class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(this.message);

  final String message;
}

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel({
    required this._cart,
    required this._orderRepository,
    this._fakeStepDelay = const Duration(milliseconds: 900),
    String Function()? correlationIds,
  }) : _correlationIds = correlationIds ?? generateCorrelationId;

  final CartViewModel _cart;
  final OrderRepository _orderRepository;
  final Duration _fakeStepDelay;
  final String Function() _correlationIds;

  CheckoutState _state = const CheckoutIdle();
  CheckoutState get state => _state;

  bool get isProcessing => _state is CheckoutProcessing;

  bool _disposed = false;

  Future<void> pay() async {
    if (isProcessing || _cart.isEmpty) return;
    final lines = _cart.lines;
    final total = _cart.totalInCents;

    _setState(const CheckoutProcessing(PaymentStep.validatingCard));
    await Future<void>.delayed(_fakeStepDelay);
    _setState(const CheckoutProcessing(PaymentStep.authorizingPayment));
    await Future<void>.delayed(_fakeStepDelay);
    _setState(const CheckoutProcessing(PaymentStep.creatingOrder));

    final correlationId = _correlationIds();
    try {
      final order = await _orderRepository.placeOrder(
        lines,
        correlationId: correlationId,
      );
      _cart.clear();
      _setState(
        CheckoutSuccess(
          order: order,
          correlationId: correlationId,
          totalInCents: total,
        ),
      );
    } on BffException catch (error) {
      _setState(CheckoutFailure(error.message));
    } on FormatException {
      _setState(const CheckoutFailure('Recebemos dados inesperados.'));
    }
  }

  void _setState(CheckoutState state) {
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
