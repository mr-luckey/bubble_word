import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// App logo image (transparent PNG).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 120,
    this.semanticLabel = 'BubbleWord logo',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.appLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
      filterQuality: FilterQuality.high,
    );
  }
}
