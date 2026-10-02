import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/animations/app_page_route.dart';
import '../../../core/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/count_badge.dart';
import 'cart_screen.dart';

/// Atalho para o carrinho com a contagem de itens.
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => IconButton(
        tooltip: 'Carrinho, ${cart.itemCount} itens',
        style: IconButton.styleFrom(
          backgroundColor: AppColors.linen,
          side: const BorderSide(color: AppColors.stone),
        ),
        onPressed: () =>
            Navigator.of(context)
                .push(AppPageRoute<void>(builder: (_) => const CartScreen())),
        icon: CountBadge(
          count: cart.itemCount,
          child: const FaIcon(
            FontAwesomeIcons.bagShopping,
            size: 18,
            color: AppColors.espresso,
          ),
        ),
      ),
    );
  }
}
