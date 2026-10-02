import '../../domain/models/app_notification.dart';
import '../services/bff_api_client.dart';

class NotificationRepository {
  NotificationRepository({required this._apiClient, required this._customerId});

  final BffApiClient _apiClient;
  final String _customerId;

  Future<List<AppNotification>> getNotifications() async {
    final notifications = await _apiClient.getNotifications(_customerId);
    return [
      for (final notification in notifications)
        AppNotification(
          id: notification.id,
          orderId: notification.orderId,
          title: notification.title,
          message: notification.message,
          sentAt: DateTime.parse(notification.sentAt),
        ),
    ];
  }
}
