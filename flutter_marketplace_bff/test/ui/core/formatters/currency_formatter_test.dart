import 'package:flutter_marketplace_bff/ui/core/formatters/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBrl', () {
    test('formata centavos como reais', () {
      expect(formatBrl(39990), r'R$ 399,90');
      expect(formatBrl(5), r'R$ 0,05');
      expect(formatBrl(0), r'R$ 0,00');
    });

    test('agrupa milhares com ponto', () {
      expect(formatBrl(179990), r'R$ 1.799,90');
      expect(formatBrl(123456789), r'R$ 1.234.567,89');
    });

    test('mantém o sinal negativo', () {
      expect(formatBrl(-1050), r'-R$ 10,50');
    });
  });
}
