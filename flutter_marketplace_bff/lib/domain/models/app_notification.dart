class AppNotification {
  const AppNotification({
    required this.id,
    required this.orderId,
    required this.title,
    required this.message,
    required this.sentAt,
  });

  final String id;
  final String orderId;
  final String title;
  final String message;
  final DateTime sentAt;
}
