import 'package:flutter_marketplace_bff/data/services/bff_exception.dart';
import 'package:flutter_marketplace_bff/ui/features/home/view_models/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_home_repository.dart';

void main() {
  group('HomeViewModel', () {
    late FakeHomeRepository repository;
    late HomeViewModel viewModel;

    setUp(() {
      repository = FakeHomeRepository(() async => sampleProducts);
      viewModel = HomeViewModel(homeRepository: repository);
    });

    tearDown(() => viewModel.dispose());

    test('começa carregando', () {
      expect(viewModel.state, isA<HomeLoading>());
      expect(viewModel.visibleProducts, isEmpty);
    });

    test('load expõe os produtos do repositório', () async {
      await viewModel.load();

      expect(viewModel.state, isA<HomeLoaded>());
      expect(viewModel.visibleProducts, sampleProducts);
    });

    test('load expõe a mensagem de BffException', () async {
      repository.onGetHomeProducts = () async =>
          throw const BffException(message: 'Catálogo indisponível');

      await viewModel.load();

      expect(
        viewModel.state,
        isA<HomeFailure>().having(
          (s) => s.message,
          'message',
          'Catálogo indisponível',
        ),
      );
    });

    test('load trata resposta malformada como falha', () async {
      repository.onGetHomeProducts = () async =>
          throw const FormatException('quebrado');

      await viewModel.load();

      expect(viewModel.state, isA<HomeFailure>());
    });

    test('refresh mantém os produtos na tela enquanto recarrega', () async {
      await viewModel.load();
      final states = <HomeState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      await viewModel.load();

      expect(states, everyElement(isA<HomeLoaded>()));
      expect(repository.calls, 2);
    });

    test('nova tentativa após falha volta a mostrar carregamento', () async {
      repository.onGetHomeProducts = () async =>
          throw const BffException(message: 'fora do ar');
      await viewModel.load();
      repository.onGetHomeProducts = () async => sampleProducts;
      final states = <HomeState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      await viewModel.load();

      expect(states.first, isA<HomeLoading>());
      expect(states.last, isA<HomeLoaded>());
    });

    group('search', () {
      setUp(() => viewModel.load());

      test('filtra sem diferenciar maiúsculas e acentos', () {
        viewModel.search('MECANICO');

        expect(viewModel.visibleProducts.map((p) => p.id), ['product-001']);
      });

      test('busca vazia mostra todos os produtos', () {
        viewModel.search('mouse');
        viewModel.search('   ');

        expect(viewModel.visibleProducts, sampleProducts);
      });

      test('notifica apenas quando o termo muda', () {
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        viewModel.search('mouse');
        viewModel.search('mouse');

        expect(notifications, 1);
      });
    });

    test('não notifica depois de descartado', () async {
      final viewModel = HomeViewModel(homeRepository: repository);
      final pending = viewModel.load();
      viewModel.dispose();

      await expectLater(pending, completes);
    });
  });
}
