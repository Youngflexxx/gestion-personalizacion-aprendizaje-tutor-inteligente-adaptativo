import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de progreso redondeada reutilizable.
class GamifiedProgressBar extends StatelessWidget {
  const GamifiedProgressBar({
    required this.value,
    this.height = 10,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: LinearProgressIndicator(
        value: normalized,
        minHeight: height,
        color: color ?? scheme.primary,
        backgroundColor:
            backgroundColor ?? scheme.primary.withValues(alpha: 0.14),
      ),
    );
  }
}
