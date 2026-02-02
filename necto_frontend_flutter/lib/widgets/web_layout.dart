import 'package:flutter/material.dart';

/// Constrains content to a max width for web; works for mobile later.
class WebLayout extends StatelessWidget {
  const WebLayout({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
