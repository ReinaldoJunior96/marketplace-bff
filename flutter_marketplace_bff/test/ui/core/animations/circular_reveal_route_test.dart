import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/animations/circular_reveal_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircularRevealClipper', () {
    const size = Size(300, 600);

    test('progresso 0 não mostra nada', () {
      final path = const CircularRevealClipper(
        progress: 0,
        center: Alignment.center,
      ).getClip(size);

      expect(path.getBounds().isEmpty, isTrue);
    });

    test('progresso 1 cobre a tela inteira, inclusive os cantos', () {
      final path = const CircularRevealClipper(
        progress: 1,
        center: Alignment.topLeft,
      ).getClip(size);

      expect(path.contains(const Offset(299, 599)), isTrue);
    });
  });

  testWidgets('CircularRevealRoute navega até a nova tela', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Text('origem')),
    );

    navigator.currentState!.pushReplacement(
      CircularRevealRoute<void>(builder: (_) => const Text('destino')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ClipPath), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('destino'), findsOneWidget);
    expect(find.text('origem'), findsNothing);
  });
}
