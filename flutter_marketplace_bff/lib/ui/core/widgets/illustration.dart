import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ilustrações do unDraw (recoloridas para a paleta do app).
enum AppIllustration {
  browsing('browsing'),
  connectionLost('connection_lost'),
  emptyCart('empty_cart'),
  emptyNotifications('empty_notifications'),
  emptyOrders('empty_orders'),
  notFound('not_found'),
  orderSuccess('order_success'),
  payment('payment');

  const AppIllustration(this._file);

  final String _file;

  String get assetPath => 'assets/illustrations/$_file.svg';
}

/// Ilustração decorativa — ignorada por leitores de tela.
class Illustration extends StatelessWidget {
  const Illustration(this.illustration, {super.key, this.height});

  final AppIllustration illustration;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.asset(
        illustration.assetPath,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
