import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/order_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../domain/models/order_timeline.dart';

/// Acompanha os eventos assíncronos de um pedido recém-criado até a
/// notificação ser enviada (ou o tempo esgotar).
class OrderTrackingViewModel extends ChangeNotifier {
  OrderTrackingViewModel({
    required this.orderId,
    required this._repository,
    this._pollInterval = const Duration(milliseconds: 800),
    this._maxAttempts = 25,
  });

  final String orderId;
  final OrderRepository _repository;
  final Duration _pollInterval;
  final int _maxAttempts;

  Timer? _timer;
  int _attempts = 0;
  bool _disposed = false;

  List<OrderTimelineStep> _steps = const [];
  List<OrderTimelineStep> get steps => _steps;

  OrderTimelineStep? stepFor(OrderEvent event) {
    for (final step in _steps) {
      if (step.event == event) return step;
    }
    return null;
  }

  bool get notificationSent => stepFor(OrderEvent.notificationSent) != null;

  bool _timedOut = false;

  /// O tempo esgotou sem a notificação aparecer.
  bool get timedOut => _timedOut;

  void start() {
    poll();
    _timer ??= Timer.periodic(_pollInterval, (_) => poll());
  }

  Future<void> poll() async {
    if (_disposed || notificationSent || _timedOut) return _stop();
    _attempts++;
    try {
      final steps = await _repository.getTimeline(orderId);
      if (_disposed) return;
      _steps = steps;
    } on BffException {
      // O Audit pode ainda não ter processado; tenta de novo.
    } on FormatException {
      // Idem.
    }
    if (!notificationSent && _attempts >= _maxAttempts) _timedOut = true;
    if (notificationSent || _timedOut) _stop();
    if (!_disposed) notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}
