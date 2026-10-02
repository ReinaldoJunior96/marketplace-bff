import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/main.dart' as app;
import 'package:flutter_marketplace_bff/ui/features/cart/views/cart_button.dart';
import 'package:flutter_marketplace_bff/ui/features/checkout/views/order_confirmation_screen.dart';
import 'package:flutter_marketplace_bff/ui/features/home/views/widgets/product_card.dart';
import 'package:flutter_marketplace_bff/ui/features/product/views/product_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Jornada completa contra o BFF real (`docker compose up` na raiz):
/// vitrine → produto → carrinho → pagamento fake → pedido → notificação.
///
/// Rode com:
/// `flutter drive --driver=test_driver/integration_test.dart
///  --target=integration_test/shopping_journey_test.dart`
/// Os screenshots vão para `screenshots/`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Avança o tempo em quadros — o app tem animações em loop (skeleton,
  /// indicadores), então `pumpAndSettle` não serve aqui.
  Future<void> wait(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('Timeout esperando por $finder');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> screenshot(String name) async {
    await binding.takeScreenshot(name);
  }

  testWidgets('compra completa reflete os serviços do backend', (tester) async {
    app.main();

    // Splash animada no meio da marca.
    await wait(tester, const Duration(milliseconds: 1500));
    await screenshot('01_splash');

    // Vitrine com produtos e fotos reais.
    await waitFor(tester, find.byType(ProductCard));
    await wait(tester, const Duration(seconds: 4));
    await screenshot('02_home');

    // Detalhe do produto (Hero da foto).
    await tester.ensureVisible(find.byType(ProductCard).first);
    await wait(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byType(ProductCard).first);
    await waitFor(tester, find.textContaining('em estoque'));
    await wait(tester, const Duration(seconds: 2));
    await screenshot('03_product');

    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.pump();
    await tester.tap(find.textContaining('Adicionar ·'));
    await wait(tester, const Duration(milliseconds: 600));
    await screenshot('04_added_to_cart');

    await tester.tap(find.byTooltip('Voltar'));
    await wait(tester, const Duration(seconds: 1));

    // Adicionar rápido direto da vitrine.
    final quickAdd = find.byTooltip('Adicionar Mouse Sem Fio ao carrinho');
    await tester.ensureVisible(quickAdd);
    await wait(tester, const Duration(milliseconds: 500));
    await tester.tap(quickAdd);
    await wait(tester, const Duration(seconds: 1));

    // Carrinho (volta ao topo, onde fica o botão).
    await tester.fling(
      find.byType(CustomScrollView).first,
      const Offset(0, 1500),
      3000,
    );
    await wait(tester, const Duration(seconds: 1));
    await tester.tap(find.byType(CartButton).first);
    await waitFor(tester, find.textContaining('Ir para pagamento'));
    await wait(tester, const Duration(seconds: 2));
    await screenshot('05_cart');

    // Pagamento fake.
    await tester.tap(find.textContaining('Ir para pagamento'));
    await waitFor(tester, find.textContaining('Pagar R\$'));
    await wait(tester, const Duration(seconds: 1));
    await screenshot('06_checkout');

    await tester.tap(find.textContaining('Pagar R\$'));
    await wait(tester, const Duration(milliseconds: 1300));
    await screenshot('07_processing');

    // Confirmação: espera o notification-service processar o pedido.
    await waitFor(tester, find.byType(OrderConfirmationScreen));
    await waitFor(tester, find.text('concluído'));
    // Espera a revelação e a cascata de entrada terminarem.
    await wait(tester, const Duration(seconds: 2));
    await screenshot('08_order_confirmed');
    expect(find.text('order-service'), findsOneWidget);
    expect(find.text('notification-service'), findsOneWidget);

    // Aviso dentro do app vindo do notification-service.
    await waitFor(tester, find.textContaining('foi recebido'));
    await wait(tester, const Duration(milliseconds: 300));
    await screenshot('09_notification_banner');

    // Pedidos e notificações.
    await tester.tap(find.text('Ver meus pedidos'));
    await waitFor(tester, find.text('Meus pedidos'));
    await wait(tester, const Duration(seconds: 2));
    await screenshot('10_orders');

    await tester.tap(find.text('Avisos'));
    await wait(tester, const Duration(seconds: 2));
    expect(find.text('Notificações'), findsOneWidget);
    await screenshot('11_notifications');

    expect(find.byType(ProductDetailScreen), findsNothing);
  });
}
