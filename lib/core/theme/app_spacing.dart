import 'package:flutter/material.dart';

/// Escala de espaciado Picaflor — whitespace generoso, estilo fintech.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  /// Padding horizontal de pantalla.
  static const double pageX = 20;

  /// Padding vertical de secciones.
  static const double sectionY = 16;

  /// Radio de cards / botones.
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageX,
    vertical: sectionY,
  );

  static const EdgeInsets pagePaddingX = EdgeInsets.symmetric(horizontal: pageX);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static BorderRadius get cardRadius => BorderRadius.circular(radiusLg);
  static BorderRadius get buttonRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get pillRadius => BorderRadius.circular(radiusPill);
}
