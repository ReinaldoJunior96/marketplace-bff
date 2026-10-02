import 'package:flutter/foundation.dart';

import '../../../../data/repositories/home_repository.dart';
import '../../../../data/services/bff_exception.dart';
import '../../../../domain/models/product.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.products);

  final List<Product> products;
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.message);

  final String message;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this._homeRepository});

  final HomeRepository _homeRepository;

  HomeState _state = const HomeLoading();
  HomeState get state => _state;

  String _query = '';
  String get query => _query;

  bool _disposed = false;

  /// Produtos carregados filtrados pela busca atual.
  List<Product> get visibleProducts {
    final state = _state;
    if (state is! HomeLoaded) return const [];
    final query = _normalize(_query);
    if (query.isEmpty) return state.products;
    return [
      for (final product in state.products)
        if (_normalize(product.name).contains(query)) product,
    ];
  }

  Future<void>? _inFlight;

  /// Carrega a vitrine. Em um refresh, mantém os produtos atuais na tela
  /// até a nova resposta chegar. Chamadas simultâneas (ex.: pré-carga da
  /// splash + abertura da home) compartilham a mesma requisição.
  Future<void> load() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    if (_state is! HomeLoaded) _setState(const HomeLoading());

    try {
      final products = await _homeRepository.getHomeProducts();
      _setState(HomeLoaded(products));
    } on BffException catch (error) {
      _setState(HomeFailure(error.message));
    } on FormatException {
      _setState(const HomeFailure('Recebemos dados inesperados do servidor.'));
    }
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    notifyListeners();
  }

  void _setState(HomeState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Busca sem diferenciar maiúsculas nem acentos ("mecanico" acha "Mecânico").
String _normalize(String value) {
  const accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c',
  };
  final lower = value.trim().toLowerCase();
  return lower.split('').map((char) => accents[char] ?? char).join();
}
