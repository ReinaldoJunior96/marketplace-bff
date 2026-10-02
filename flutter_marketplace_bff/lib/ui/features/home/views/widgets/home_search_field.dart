import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Buscar produtos',
        prefixIcon: Padding(
          padding: EdgeInsets.all(14),
          child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
        ),
      ),
    );
  }
}
