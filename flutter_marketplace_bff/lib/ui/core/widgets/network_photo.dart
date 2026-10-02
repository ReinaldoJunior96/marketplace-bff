import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';

/// Foto remota que aparece com fade quando termina de carregar.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url, this.semanticLabel});

  final String url;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.medium,
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: FaIcon(FontAwesomeIcons.image, size: 36, color: AppColors.mocha),
      ),
    );
  }
}
