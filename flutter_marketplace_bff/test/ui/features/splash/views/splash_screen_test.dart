import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/theme/app_theme.dart';
import 'package:flutter_marketplace_bff/ui/features/splash/views/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSplash(
    WidgetTester tester, {
    required Future<void> Function() preload,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: SplashScreen(
          preload: preload,
          nextBuilder: (_) => const Scaffold(body: Text('home')),
        ),
      ),
    );
  }

  testWidgets('anima a marca e depois revela a próxima tela', (tester) async {
    var preloads = 0;
    await pumpSplash(tester, preload: () async => preloads++);

    expect(preloads, 1);
    expect(find.text('Achados com afeto'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('espera a pré-carga terminar antes de sair', (tester) async {
    final preload = Completer<void>();
    await pumpSplash(tester, preload: () => preload.future);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('home'), findsNothing);

    preload.complete();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('não fica presa se a pré-carga demorar demais', (tester) async {
    await pumpSplash(tester, preload: () => Completer<void>().future);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('com "reduzir movimento" sai sem esperar a animação', (
    tester,
  ) async {
    await pumpSplash(tester, preload: () async {}, disableAnimations: true);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
