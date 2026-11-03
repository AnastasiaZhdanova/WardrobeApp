import 'package:flutter/material.dart';

/// Decodes the asset at the size it is displayed, not at its source size.
/// `cacheWidth` makes Flutter wrap the provider in a `ResizeImage`, so the
/// shared `ImageCache` holds one small bitmap per (asset, width) pair.
class WardrobeImage extends StatelessWidget {
  const WardrobeImage({required this.asset, super.key});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Unbounded width (e.g. inside a horizontal list): decode at full size
        // rather than crash on `infinity.round()`.
        cacheWidth: constraints.hasBoundedWidth
            ? (constraints.maxWidth * dpr).round()
            : null,
        gaplessPlayback: true,
        errorBuilder: (context, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.checkroom_outlined),
        ),
      ),
    );
  }
}
