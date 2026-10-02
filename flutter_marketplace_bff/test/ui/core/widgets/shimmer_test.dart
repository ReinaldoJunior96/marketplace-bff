import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/widgets/shimmer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({bool disableAnimations = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: Shimmer(child: SizedBox(width: 100, height: 100)),
    ),
  );

  testWidgets('anima em loop', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('fica parado com "reduzir movimento"', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
