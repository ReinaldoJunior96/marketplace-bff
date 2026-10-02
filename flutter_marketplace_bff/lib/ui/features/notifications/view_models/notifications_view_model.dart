import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../domain/models/app_notification.dart';

/// Acompanha as notificações do cliente consultando o BFF periodicamente.
///
/// Na primeira consulta, o histórico existente é marcado como visto sem gerar
/// avisos; depois, cada notificação nova vira um aviso em [incoming].
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required this._repository,
    this._pollInterval = const Duration(seconds: 4),
  });

  final NotificationRepository _repository;
  final Duration _pollInterval;

  Timer? _timer;
  bool _primed = false;
  bool _disposed = false;
  Future<void>? _inFlight;

  final _seen = <String>{};
  final _read = <String>{};

  List<AppNotification> _notifications = const [];
  List<AppNotification> get notifications => _notifications;

  bool _loaded = false;
  bool get loaded => _loaded;

  int get unreadCount =>
      _notifications.where((n) => !_read.contains(n.id)).length;

  /// Última notificação recém-chegada, para o aviso dentro do app.
  final incoming = ValueNotifier<AppNotification?>(null);

  void start() {
    _timer ??= Timer.periodic(_pollInterval, (_) => poll());
    poll();
  }

  Future<void> poll() =>
      _inFlight ??= _poll().whenComplete(() => _inFlight = null);

  Future<void> _poll() async {
    final List<AppNotification> latest;
    try {
      latest = await _repository.getNotifications();
    } on BffException {
      return; // Tenta de novo no próximo ciclo.
    } on FormatException {
      return;
    }
    if (_disposed) return;

    final fresh = latest.where((n) => !_seen.contains(n.id)).toList();
    _seen.addAll(latest.map((n) => n.id));
    if (!_primed) {
      _read.addAll(latest.map((n) => n.id));
      _primed = true;
    } else if (fresh.isNotEmpty) {
      incoming.value = fresh.first;
    }

    _notifications = [...latest]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    _loaded = true;
    notifyListeners();
  }

  void markAllRead() {
    if (unreadCount == 0) return;
    _read.addAll(_notifications.map((n) => n.id));
    notifyListeners();
  }

  void dismissIncoming() => incoming.value = null;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    incoming.dispose();
    super.dispose();
  }
}
