import 'package:flutter/material.dart';

/// Contenedor que limita el ancho de lectura en pantallas grandes.
///
/// Aplica la recomendación de la skill `flutter-build-responsive-layout`:
/// las decisiones de layout se basan en el espacio disponible, no en el
/// tipo de dispositivo.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    required this.child,
    this.maxWidth = 780,
    super.key,
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
