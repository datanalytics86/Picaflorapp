import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala de espaciado Picaflor — ritmo generoso estilo Fintual.
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

  /// Padding horizontal base (móvil). Preferir [AppLayout.pageX] en UI.
  static const double pageX = 20;

  static const double sectionY = 16;
  static const double listGap = 12;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;
  static const double radiusXxl = 28;
  static const double radiusPill = 999;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageX,
    vertical: sectionY,
  );

  static const EdgeInsets pagePaddingX =
      EdgeInsets.symmetric(horizontal: pageX);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static BorderRadius get cardRadius => BorderRadius.circular(radiusLg);
  static BorderRadius get buttonRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get pillRadius => BorderRadius.circular(radiusPill);
}

/// Breakpoints y anchos de contenido — evita “móvil agrandado” en PC.
abstract final class AppLayout {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;

  /// Ancho máximo del feed de cards (lista).
  static const double contentMax = 680;

  /// Ancho máximo del hilo de chat / formularios.
  static const double contentMaxChat = 720;

  /// Ancho máximo del bloque mapa / paneles anchos.
  static const double contentMaxWide = 1120;

  /// NavigationRail compacto (iconos).
  static const double railWidth = 84;

  /// NavigationRail extendido con labels (desktop ≥ expanded).
  static const double railExtendedWidth = 208;

  /// Altura mínima del mapa en desktop (sensación de producto, no “caja chica”).
  static const double mapMinHeightDesktop = 480;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compact;
  static bool isMedium(BuildContext context) =>
      widthOf(context) >= compact && widthOf(context) < medium;
  static bool isWide(BuildContext context) => widthOf(context) >= medium;
  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= expanded;

  /// Shell lateral en tablet/PC (≥ medium).
  static bool useNavRail(BuildContext context) => isWide(context);

  /// Padding horizontal adaptativo (más aire en desktop).
  static double pageX(BuildContext context) {
    final w = widthOf(context);
    if (w >= expanded) return 40;
    if (w >= medium) return 32;
    if (w >= compact) return 24;
    return AppSpacing.pageX;
  }

  static EdgeInsets pagePaddingX(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: pageX(context));

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.fromLTRB(pageX(context), top, pageX(context), bottom);

  /// Envuelve [child] centrado con ancho máximo (lista o mapa).
  static Widget constrained({
    required BuildContext context,
    required Widget child,
    double maxWidth = contentMax,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Scroll body centrado con max width — patrón Fintual/Mercury desktop.
  static Widget scrollBody({
    required BuildContext context,
    required List<Widget> children,
    double maxWidth = contentMax,
    double top = 0,
    double bottom = AppSpacing.xxl,
  }) {
    final px = pageX(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(px, top, px, bottom),
          children: children,
        ),
      ),
    );
  }
}

/// Sombras multi-capa estilo Linear / Fintual / Mercury.
/// Incluye variante web liviana (1 capa) — sin sombra las cards se ven “default”.
abstract final class AppShadows {
  static List<BoxShadow> card(bool isDark, {bool web = false}) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: web ? 0.28 : 0.38),
          blurRadius: web ? 14 : 22,
          offset: const Offset(0, 6),
          spreadRadius: -4,
        ),
      ];
    }
    if (web) {
      return [
        BoxShadow(
          color: const Color(0xFF0C0F14).withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.025),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.045),
        blurRadius: 14,
        offset: const Offset(0, 5),
        spreadRadius: -3,
      ),
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.03),
        blurRadius: 28,
        offset: const Offset(0, 12),
        spreadRadius: -8,
      ),
    ];
  }

  static List<BoxShadow> cardHover(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 28,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 22,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
    ];
  }

  static List<BoxShadow> cardPressed(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.09),
        blurRadius: 18,
        offset: const Offset(0, 7),
        spreadRadius: -3,
      ),
    ];
  }

  static List<BoxShadow> mapPin({Color? tint}) {
    return [
      BoxShadow(
        color: (tint ?? Colors.black)
            .withValues(alpha: tint != null ? 0.3 : 0.14),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> float(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.38),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0C0F14).withValues(alpha: 0.06),
        blurRadius: 14,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ];
  }
}
