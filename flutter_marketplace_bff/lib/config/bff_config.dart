import 'package:flutter/foundation.dart';

/// Endereço do Marketplace BFF.
///
/// Em aparelho físico, aponte para o IP da máquina que roda o Docker:
/// `flutter run --dart-define=BFF_BASE_URL=http://192.168.0.10:3000`
abstract final class BffConfig {
  /// Cliente fixo do app de demonstração (não há login).
  static const demoCustomerId = 'customer-terrashop';

  static const _override = String.fromEnvironment('BFF_BASE_URL');

  static Uri get baseUrl {
    if (_override.isNotEmpty) return Uri.parse(_override);

    // O emulador Android enxerga o host pelo IP especial 10.0.2.2.
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Uri.parse(
      isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000',
    );
  }
}
