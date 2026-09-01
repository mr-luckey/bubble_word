import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Full-screen app background using the reference park/castle image.
class NebulaBackground extends StatelessWidget {
  const NebulaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.gameBackground),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
