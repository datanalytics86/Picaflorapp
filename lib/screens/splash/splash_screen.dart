import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Splash mínimo — sin flutter_animate (evita jank en web al boot).
///
/// El router redirige de inmediato; esta pantalla casi no se ve.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🖼️ SplashScreen build (should redirect ASAP)');
    }

    return const Scaffold(
      body: ColoredBox(
        color: Color(0xFF0C0F14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoMark(),
              Gap(20),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              Gap(16),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: const Icon(
        Icons.pets_rounded,
        size: 36,
        color: Colors.white,
      ),
    );
  }
}
