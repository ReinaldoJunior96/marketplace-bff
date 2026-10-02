import 'package:flutter_marketplace_bff/data/services/bff_exception.dart';
import 'package:flutter_marketplace_bff/domain/models/order_timeline.dart';
import 'package:flutter_marketplace_bff/ui/features/cart/view_models/cart_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/checkout/view_models/checkout_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/checkout/view_models/order_tracking_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/notifications/view_models/notifications_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/orders/view_models/orders_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/product/view_models/product_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_flow_repositories.dart';
import '../../helpers/fake_home_repository.dart';

void main() {
  final teclado = sampleProducts[0];
  final mouse = sampleProducts[1];

  group('CartViewModel', () {
    test('soma quantidades do mesmo produto e calcula o total', () {
      final cart = CartViewModel()
        ..add(teclado)
        ..add(teclado, quantity: 2)
        ..add(mouse);

      expect(cart.lines, hasLength(2));
      expect(cart.quantityOf(teclado.id), 3);
      expect(cart.itemCount, 4);
      expect(cart.totalInCents, 39990 * 3 + 18990);
    });

    test('decrementar até zero remove o item', () {
      final cart = CartViewModel()..add(mouse);

      cart.decrement(mouse.id);

      expect(cart.isEmpty, isTrue);
    });

    test('clear só notifica quando havia itens', () {
      final cart = CartViewModel();
      var notifications = 0;
      cart.addListener(() => notifications++);

      cart.clear();
      cart
        ..add(mouse)
        ..clear();

      expect(notifications, 2);
    });
  });

  group('ProductDetailViewModel', () {
    late CartViewModel cart;
    late FakeProductRepository repository;
    late ProductDetailViewModel viewModel;

    setUp(() {
      cart = CartViewModel();
      repository = FakeProductRepository((_) async => sampleDetail);
      viewModel = ProductDetailViewModel(
        preview: teclado,
        repository: repository,
        cart: cart,
      );
    });

    test('carrega o detalhe e limita a quantidade ao estoque', () async {
      await viewModel.load();

      for (var i = 0; i < 5; i++) {
        viewModel.incrementQuantity();
      }

      expect(viewModel.state, isA<ProductDetailLoaded>());
      expect(viewModel.quantity, sampleDetail.stock);
    });

    test('adiciona a quantidade escolhida ao carrinho', () async {
      await viewModel.load();
      viewModel.incrementQuantity();

      expect(viewModel.addToCart(), isTrue);
      expect(cart.quantityOf(teclado.id), 2);
    });

    test('não adiciona antes de carregar', () {
      expect(viewModel.addToCart(), isFalse);
      expect(cart.isEmpty, isTrue);
    });

    test('expõe a mensagem de erro do BFF', () async {
      repository.onGetProduct = (_) async =>
          throw const BffException(message: 'Product not found');

      await viewModel.load();

      expect(
        viewModel.state,
        isA<ProductDetailFailure>().having(
          (s) => s.message,
          'message',
          'Product not found',
        ),
      );
    });
  });

  group('CheckoutViewModel', () {
    late CartViewModel cart;
    late FakeOrderRepository orders;
    late CheckoutViewModel viewModel;

    setUp(() {
      cart = CartViewModel()..add(teclado, quantity: 2);
      orders = FakeOrderRepository();
      viewModel = CheckoutViewModel(
        cart: cart,
        orderRepository: orders,
        fakeStepDelay: Duration.zero,
        correlationIds: () => 'corr-fixed',
      );
    });

    test('passa pelas etapas, cria o pedido e esvazia o carrinho', () async {
      final states = <CheckoutState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      await viewModel.pay();

      expect(
        states.whereType<CheckoutProcessing>().map((s) => s.step),
        PaymentStep.values,
      );
      expect(
        viewModel.state,
        isA<CheckoutSuccess>()
            .having((s) => s.correlationId, 'correlationId', 'corr-fixed')
            .having((s) => s.totalInCents, 'total', 79980),
      );
      expect(orders.placedOrders.single.lines.single.quantity, 2);
      expect(orders.placedOrders.single.correlationId, 'corr-fixed');
      expect(cart.isEmpty, isTrue);
    });

    test('mantém o carrinho se o pedido falhar', () async {
      orders.onPlaceOrder = () async =>
          throw const BffException(message: 'Order service is unavailable');

      await viewModel.pay();

      expect(viewModel.state, isA<CheckoutFailure>());
      expect(cart.itemCount, 2);
    });

    test('ignora pagamento com carrinho vazio', () async {
      cart.clear();

      await viewModel.pay();

      expect(viewModel.state, isA<CheckoutIdle>());
      expect(orders.placedOrders, isEmpty);
    });
  });

  group('OrderTrackingViewModel', () {
    test('para de consultar quando a notificação aparece', () async {
      final orders = FakeOrderRepository();
      final viewModel = OrderTrackingViewModel(
        orderId: sampleOrder.id,
        repository: orders,
      );
      addTearDown(viewModel.dispose);

      orders.onGetTimeline = () async => [
        timelineStep(OrderEvent.orderCreated, 'order-service'),
      ];
      await viewModel.poll();
      expect(viewModel.notificationSent, isFalse);

      orders.onGetTimeline = () async => [
        timelineStep(OrderEvent.orderCreated, 'order-service'),
        timelineStep(OrderEvent.notificationSent, 'notification-service'),
      ];
      await viewModel.poll();
      await viewModel.poll();

      expect(viewModel.notificationSent, isTrue);
      expect(orders.timelineCalls, 2);
    });

    test('desiste depois do limite de tentativas', () async {
      final viewModel = OrderTrackingViewModel(
        orderId: sampleOrder.id,
        repository: FakeOrderRepository(),
        maxAttempts: 2,
      );
      addTearDown(viewModel.dispose);

      await viewModel.poll();
      await viewModel.poll();

      expect(viewModel.timedOut, isTrue);
    });
  });

  group('NotificationsViewModel', () {
    late FakeNotificationRepository repository;
    late NotificationsViewModel viewModel;

    setUp(() {
      repository = FakeNotificationRepository();
      viewModel = NotificationsViewModel(repository: repository);
    });

    tearDown(() => viewModel.dispose());

    test('histórico inicial não gera aviso nem fica como não lido', () async {
      repository.onGetNotifications = () async => [notification('old')];

      await viewModel.poll();

      expect(viewModel.incoming.value, isNull);
      expect(viewModel.unreadCount, 0);
      expect(viewModel.notifications, hasLength(1));
    });

    test('notificação nova vira aviso e conta como não lida', () async {
      await viewModel.poll();
      repository.onGetNotifications = () async => [
        notification('new', minute: 5),
      ];

      await viewModel.poll();

      expect(viewModel.incoming.value?.id, 'new');
      expect(viewModel.unreadCount, 1);

      viewModel.markAllRead();
      expect(viewModel.unreadCount, 0);
    });

    test('falha de rede mantém o estado anterior', () async {
      repository.onGetNotifications = () async => [notification('a')];
      await viewModel.poll();
      repository.onGetNotifications = () async =>
          throw const BffException(message: 'offline');

      await viewModel.poll();

      expect(viewModel.notifications, hasLength(1));
    });
  });

  test('OrdersViewModel carrega os pedidos', () async {
    final viewModel = OrdersViewModel(repository: FakeOrderRepository());
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(
      viewModel.state,
      isA<OrdersLoaded>().having(
        (s) => s.orders.single.id,
        'id',
        sampleOrder.id,
      ),
    );
  });
}
