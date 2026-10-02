import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/animations/fade_slide_in.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  double opacityOf(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeSlideIn),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity
      .value;

  Widget subject({bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: FadeSlideIn(
        delay: Duration(milliseconds: 200),
        duration: Duration(milliseconds: 300),
        child: Text('oi'),
      ),
    ),
  );

  testWidgets('fica invisível durante o delay e aparece no fim', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pump(); // a animação começa no frame seguinte

    await tester.pump(const Duration(milliseconds: 150));
    expect(opacityOf(tester), 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);
  });

  testWidgets('espera a transição da rota terminar para começar', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );

    navigator.currentState!.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const FadeSlideIn(
          duration: Duration(milliseconds: 300),
          child: Text('oi'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityOf(tester), 0);

    // A transição termina perto de 600ms; a entrada começa no frame seguinte.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 150));
    expect(opacityOf(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester), 1);
  });

  testWidgets('com "reduzir movimento" aparece imediatamente', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));

    expect(opacityOf(tester), 1);
  });
}
