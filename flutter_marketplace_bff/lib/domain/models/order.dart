enum OrderStatus {
  created,
  unknown;

  static OrderStatus parse(String value) =>
      value == 'CREATED' ? OrderStatus.created : OrderStatus.unknown;
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  final String id;
  final OrderStatus status;
  final int itemsCount;
  final DateTime createdAt;

  /// Identificador curto para exibição (`#a1b2c3d4`).
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
}
