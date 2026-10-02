import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/domain/models/order_timeline.dart';
import 'package:flutter_marketplace_bff/ui/core/app_scope.dart';
import 'package:flutter_marketplace_bff/ui/features/cart/views/cart_screen.dart';
import 'package:flutter_marketplace_bff/ui/features/checkout/views/checkout_screen.dart';
import 'package:flutter_marketplace_bff/ui/features/checkout/views/order_confirmation_screen.dart';
import 'package:flutter_marketplace_bff/ui/features/product/views/product_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_flow_repositories.dart';
import '../../helpers/fake_home_repository.dart';
import '../../helpers/test_app.dart';

void main() {
  final teclado = sampleProducts[0];

  /// Tela alta o bastante para os botões fixos ficarem visíveis.
  Future<void> useTallScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('detalhe carrega a descrição e adiciona ao carrinho', (
    tester,
  ) async {
    await useTallScreen(tester);
    final deps = createTestDependencies();

    await tester.pumpWidget(deps.app(ProductDetailScreen(product: teclado)));
    await tester.pumpAndSettle();

    expect(find.text(sampleDetail.description), findsOneWidget);
    expect(find.text('3 em estoque'), findsOneWidget);

    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.pump();
    await tester.tap(find.textContaining('Adicionar ·'));
    await tester.pump();

    expect(deps.cart.quantityOf(teclado.id), 2);
    expect(find.text('Adicionado!'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('carrinho altera quantidades e mostra o vazio', (tester) async {
    await useTallScreen(tester);
    final deps = createTestDependencies();
    deps.cart.add(teclado);

    await tester.pumpWidget(deps.app(const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Teclado Mecânico'), findsOneWidget);
    expect(find.textContaining('R\$ 399,90'), findsWidgets);

    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.pumpAndSettle();
    expect(find.textContaining('R\$ 799,80'), findsWidgets);

    await tester.tap(find.byTooltip('Diminuir quantidade'));
    await tester.tap(find.byTooltip('Diminuir quantidade'));
    await tester.pumpAndSettle();
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
  });

  testWidgets('pagamento cria o pedido e a confirmação acompanha os serviços', (
    tester,
  ) async {
    await useTallScreen(tester);
    final deps = createTestDependencies();
    deps.cart.add(teclado, quantity: 2);
    deps.orders.onGetTimeline = () async => [
      timelineStep(OrderEvent.orderCreated, 'order-service'),
      timelineStep(OrderEvent.notificationSent, 'notification-service'),
    ];

    await tester.pumpWidget(deps.app(const CheckoutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Pagar R\$ 799,80'), findsOneWidget);

    await tester.tap(find.text('Pagar R\$ 799,80'));
    await tester.pump();
    expect(find.text('Validando cartão'), findsOneWidget);

    // Etapas simuladas + criação do pedido + revelação da confirmação.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(OrderConfirmationScreen), findsOneWidget);
    expect(find.text('Pagamento aprovado!'), findsOneWidget);
    expect(deps.orders.placedOrders.single.lines.single.quantity, 2);
    expect(deps.cart.isEmpty, isTrue);

    // A timeline mostra os serviços que processaram o pedido.
    expect(find.text('order-service'), findsOneWidget);
    expect(find.text('notification-service'), findsOneWidget);
    expect(find.text('concluído'), findsOneWidget);
    expect(
      find.textContaining(deps.orders.placedOrders.single.correlationId),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver meus pedidos'));
    await tester.pumpAndSettle();
    expect(deps.currentTab.value, AppTab.orders);
  });

  testWidgets('falha no pedido mantém o carrinho e permite tentar de novo', (
    tester,
  ) async {
    await useTallScreen(tester);
    final deps = createTestDependencies();
    deps.cart.add(teclado);
    deps.orders.onPlaceOrder = () =>
        Future.error(const FormatException('quebrado'));

    await tester.pumpWidget(deps.app(const CheckoutScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Pagar'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(OrderConfirmationScreen), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(deps.cart.itemCount, 1);
  });
}
