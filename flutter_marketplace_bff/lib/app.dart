import 'package:flutter/material.dart';

import 'data/repositories/home_repository.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/features/home/views/home_screen.dart';
import 'ui/features/splash/views/splash_screen.dart';

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({super.key, required this.homeRepository});

  final HomeRepository homeRepository;

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  late final _homeViewModel = HomeViewModel(
    homeRepository: widget.homeRepository,
  );

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashScreen(
        preload: _homeViewModel.load,
        nextBuilder: (_) => HomeScreen(viewModel: _homeViewModel),
      ),
    );
  }
}
