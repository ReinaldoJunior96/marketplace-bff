import 'package:flutter_marketplace_bff/ui/core/formatters/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 2, 14, 30);

  test('formatRelative usa termos curtos para eventos recentes', () {
    expect(
      formatRelative(now.subtract(const Duration(seconds: 20)), now: now),
      'agora',
    );
    expect(
      formatRelative(now.subtract(const Duration(minutes: 5)), now: now),
      'há 5 min',
    );
    expect(
      formatRelative(now.subtract(const Duration(hours: 2)), now: now),
      'há 2 h',
    );
  });

  test('formatRelative usa a data para eventos antigos', () {
    expect(
      formatRelative(DateTime(2026, 9, 28, 9, 5), now: now),
      '28/09 às 09:05',
    );
  });

  test('formatTime mostra hora com segundos', () {
    expect(formatTime(DateTime(2026, 10, 2, 8, 4, 9)), '08:04:09');
  });
}
