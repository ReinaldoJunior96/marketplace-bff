import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/data/services/bff_exception.dart';
import 'package:flutter_marketplace_bff/domain/models/product.dart';
import 'package:flutter_marketplace_bff/ui/core/theme/app_theme.dart';
import 'package:flutter_marketplace_bff/ui/features/home/view_models/home_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/home/views/home_screen.dart';
import 'package:flutter_marketplace_bff/ui/features/home/views/widgets/product_card.dart';
import 'package:flutter_marketplace_bff/ui/features/home/views/widgets/product_card_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_home_repository.dart';

/// O `TextField` também tem um Scrollable; o primeiro é o da tela.
Finder get _homeScrollable => find.byType(Scrollable).first;

void main() {
  late FakeHomeRepository repository;
  late HomeViewModel viewModel;

  setUp(() {
    repository = FakeHomeRepository(() async => sampleProducts);
    viewModel = HomeViewModel(homeRepository: repository);
  });

  tearDown(() => viewModel.dispose());

  Future<void> pumpHome(WidgetTester tester, {Size? size}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(viewModel: viewModel),
      ),
    );
  }

  testWidgets('mostra skeletons enquanto carrega', (tester) async {
    final response = Completer<List<Product>>();
    repository.onGetHomeProducts = () => response.future;

    await pumpHome(tester);

    expect(find.byType(ProductCardSkeleton), findsWidgets);
    expect(find.byType(ProductCard), findsNothing);

    response.complete(sampleProducts);
    await tester.pumpAndSettle();
  });

  testWidgets('mostra os produtos com preço em reais', (tester) async {
    await pumpHome(tester, size: const Size(800, 1600));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCard), findsNWidgets(3));
    expect(find.text('Teclado Mecânico'), findsOneWidget);
    expect(find.text(r'R$ 399,90'), findsOneWidget);
    expect(find.text(r'R$ 1.799,90'), findsOneWidget);
    expect(find.text('3 produtos'), findsOneWidget);
  });

  testWidgets('busca filtra os cards', (tester) async {
    await pumpHome(tester, size: const Size(800, 1600));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'monitor');
    await tester.pump();

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Monitor 27 Polegadas'), findsOneWidget);
    expect(find.text('1 produto'), findsOneWidget);
  });

  testWidgets('busca sem resultado mostra mensagem', (tester) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'geladeira');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Nada encontrado'),
      200,
      scrollable: _homeScrollable,
    );
    await tester.pump();

    expect(find.byType(ProductCard), findsNothing);
    expect(find.text('Nada encontrado'), findsOneWidget);
  });

  testWidgets('erro mostra mensagem e permite tentar de novo', (tester) async {
    repository.onGetHomeProducts = () async =>
        throw const BffException(message: 'Catálogo indisponível');

    await pumpHome(tester);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tentar de novo'),
      200,
      scrollable: _homeScrollable,
    );
    await tester.pump();

    expect(find.text('Não conseguimos carregar a vitrine'), findsOneWidget);
    expect(find.text('Catálogo indisponível'), findsOneWidget);

    repository.onGetHomeProducts = () async => sampleProducts;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCard), findsWidgets);
    expect(repository.calls, 2);
  });

  testWidgets('grade usa mais colunas em telas largas', (tester) async {
    Future<int> columnsAt(double width) async {
      await pumpHome(tester, size: Size(width, 1600));
      await tester.pumpAndSettle();
      final cards = find.byType(ProductCard);
      final tops = [
        for (var i = 0; i < cards.evaluate().length; i++)
          tester.getTopLeft(cards.at(i)).dy,
      ];
      return tops.where((top) => top == tops.first).length;
    }

    expect(await columnsAt(390), 2);
    expect(await columnsAt(1200), 3); // só há 3 produtos
  });

  testWidgets('não estoura layout com fonte grande', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpHome(tester, size: const Size(360, 1600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductCard), findsWidgets);
  });
}
