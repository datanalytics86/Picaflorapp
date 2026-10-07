import 'package:flutter/material.dart';

import '../tokens/pf_palette.dart';

/// Isotipo geométrico de picaflor (placeholder de una tinta).
///
/// No es el arte final. El humano aprueba el isotipo antes de tiendas.
class PfMark extends StatelessWidget {
  const PfMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? PfPalette.brand;
    return Semantics(
      label: 'Picaflor',
      child: CustomPaint(
        size: Size.square(size),
        painter: _HummingbirdPainter(ink),
      ),
    );
  }
}

class _HummingbirdPainter extends CustomPainter {
  _HummingbirdPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final p = Paint()..color = color;
    final body = Path()
      ..moveTo(s * 0.62, s * 0.18)
      ..quadraticBezierTo(s * 0.78, s * 0.42, s * 0.58, s * 0.62)
      ..quadraticBezierTo(s * 0.50, s * 0.86, s * 0.42, s * 0.90)
      ..quadraticBezierTo(s * 0.46, s * 0.70, s * 0.40, s * 0.55)
      ..quadraticBezierTo(s * 0.28, s * 0.40, s * 0.22, s * 0.28)
      ..quadraticBezierTo(s * 0.40, s * 0.30, s * 0.62, s * 0.18)
      ..close();
    canvas.drawPath(body, p);

    final wing = Path()
      ..moveTo(s * 0.48, s * 0.40)
      ..quadraticBezierTo(s * 0.20, s * 0.22, s * 0.10, s * 0.36)
      ..quadraticBezierTo(s * 0.28, s * 0.42, s * 0.46, s * 0.50)
      ..close();
    canvas.drawPath(wing, p..color = color.withValues(alpha: 0.85));

    canvas.drawCircle(Offset(s * 0.66, s * 0.24), s * 0.035, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HummingbirdPainter oldDelegate) =>
      oldDelegate.color != color;
}
