import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Relación de contraste WCAG 2.x entre dos colores opacos.
double contrastRatio(Color a, Color b) {
  final l1 = _relLuminance(a);
  final l2 = _relLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relLuminance(Color c) {
  double ch(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = ch(c.r);
  final g = ch(c.g);
  final b = ch(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}
