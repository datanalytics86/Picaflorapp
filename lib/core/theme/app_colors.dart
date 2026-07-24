import 'package:flutter/material.dart';

/// Paleta Picaflor — inspirada en el colibrí y el minimalismo fintech (Fintual/BCI).
/// Colores suaves, mucho contraste legible y acentos calmados.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1FA89A);
  static const Color primaryDark = Color(0xFF168A7E);
  static const Color primarySoft = Color(0xFFE6F7F5);
  static const Color primaryMuted = Color(0xFFA8D9D3);

  static const Color accent = Color(0xFFFF7A59);
  static const Color accentSoft = Color(0xFFFFF0EC);

  static const Color secondary = Color(0xFF5B6CFF);
  static const Color secondarySoft = Color(0xFFEEF0FF);

  // ── Light ──────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8EBF0);
  static const Color lightDivider = Color(0xFFF0F2F5);

  static const Color lightTextPrimary = Color(0xFF1A1D26);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightTextInverse = Color(0xFFFFFFFF);

  // ── Dark ───────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF171B22);
  static const Color darkSurfaceElevated = Color(0xFF1E242D);
  static const Color darkCard = Color(0xFF1A1F27);
  static const Color darkBorder = Color(0xFF2A3140);
  static const Color darkDivider = Color(0xFF232833);

  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);
  static const Color darkTextInverse = Color(0xFF1A1D26);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // ── Presence ───────────────────────────────────────────────────────────
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color away = Color(0xFFF59E0B);

  // ── Chat ───────────────────────────────────────────────────────────────
  static const Color bubbleMineLight = Color(0xFF1FA89A);
  static const Color bubbleMineDark = Color(0xFF168A7E);
  static const Color bubbleOtherLight = Color(0xFFF0F2F5);
  static const Color bubbleOtherDark = Color(0xFF2A3140);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1FA89A), Color(0xFF2BC4B4)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E1116), Color(0xFF1A2E2B)],
  );

  static const LinearGradient cardHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F8FA)],
  );
}
