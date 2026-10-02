/// Item de `GET /api/mobile/notifications`.
class MobileNotificationApiModel {
  const MobileNotificationApiModel({
    required this.id,
    required this.orderId,
    required this.title,
    required this.message,
    required this.sentAt,
  });

  factory MobileNotificationApiModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'orderId': final String orderId,
        'title': final String title,
        'message': final String message,
        'sentAt': final String sentAt,
      } =>
        MobileNotificationApiModel(
          id: id,
          orderId: orderId,
          title: title,
          message: message,
          sentAt: sentAt,
        ),
      _ => throw const FormatException('Notificação inválida na resposta.'),
    };
  }

  final String id;
  final String orderId;
  final String title;
  final String message;
  final String sentAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'title': title,
    'message': message,
    'sentAt': sentAt,
  };
}
