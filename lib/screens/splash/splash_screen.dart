import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/constants/app_constants.dart';
import '../../core/design_system/components/pf_mark.dart';
import '../../core/design_system/tokens/pf_type.dart';
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
        color: AppColors.darkBackground,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoMark(),
              Gap(20),
              Text(
                AppConstants.appName,
                style: PfType.wordmarkOnDark,
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
      child: const PfMark(
        size: 36,
        color: Colors.white,
      ),
    );
  }
}
