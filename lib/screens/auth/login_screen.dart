import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/picaflor_button.dart';
import '../../widgets/picaflor_text_field.dart';

/// Login / registro — email, Google, Apple y teléfono.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();

  /// 0 = email, 1 = teléfono
  int _tab = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _smsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await Haptic.medium();

    final controller = ref.read(authControllerProvider.notifier);
    final isRegister = ref.read(authControllerProvider).isRegisterMode;

    final ok = isRegister
        ? await controller.signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text,
          )
        : await controller.signIn(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );

    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _enterDemo() async {
    FocusScope.of(context).unfocus();
    await Haptic.medium();
    // Timeout duro: nunca dejar el botón en loading eterno.
    final ok = await ref
        .read(authControllerProvider.notifier)
        .enterDemo()
        .timeout(
          const Duration(seconds: 4),
          onTimeout: () => false,
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo entrar al demo. Reintenta.')),
      );
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    await Haptic.light();
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _apple() async {
    FocusScope.of(context).unfocus();
    await Haptic.light();
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithApple();
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _sendSms() async {
    FocusScope.of(context).unfocus();
    await Haptic.light();
    final ok = await ref.read(authControllerProvider.notifier).sendPhoneCode(
          _phoneCtrl.text,
        );
    // Auto-verify (Android) o sesión lista → home.
    final step = ref.read(authControllerProvider).phoneStep;
    if (ok && step == PhoneAuthStep.idle && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _confirmSms() async {
    FocusScope.of(context).unfocus();
    await Haptic.medium();
    final ok = await ref.read(authControllerProvider.notifier).confirmPhoneCode(
          smsCode: _smsCtrl.text,
          displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text,
        );
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    final error = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Te enviamos un enlace a $email. Revisa tu correo.',
        ),
        backgroundColor: error != null ? AppColors.error : null,
      ),
    );
  }

  bool get _showApple {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = ref.watch(authControllerProvider);
    final isRegister = auth.isRegisterMode;
    final phoneSent = auth.phoneStep == PhoneAuthStep.codeSent ||
        auth.phoneStep == PhoneAuthStep.verifying;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd + 2),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isRegister ? 'Crea tu cuenta' : 'Qué bueno verte',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isRegister
                          ? 'Únete y conoce gente cerca en Santiago.'
                          : 'Entra para ver quién anda cerca.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (AppConfig.demoMode) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.primarySoft,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.science_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Modo demo (sin Firebase)',
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Explora gente cerca, chats y perfil con datos en memoria. SMS demo: ${AuthService.demoSmsCode}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PicaflorButton(
                              label: 'Entrar en demo',
                              onPressed: auth.isLoading ? null : _enterDemo,
                              isLoading: auth.isLoading &&
                                  auth.lastMethod == AuthMethod.email &&
                                  _emailCtrl.text.isEmpty,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // Tabs correo / teléfono
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightBackground,
                        borderRadius: AppSpacing.buttonRadius,
                      ),
                      child: Row(
                        children: [
                          _TabChip(
                            label: 'Correo',
                            selected: _tab == 0,
                            onTap: () {
                              setState(() => _tab = 0);
                              ref
                                  .read(authControllerProvider.notifier)
                                  .resetPhoneFlow();
                            },
                          ),
                          _TabChip(
                            label: 'Teléfono',
                            selected: _tab == 1,
                            onTap: () => setState(() => _tab = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_tab == 0) ...[
                      if (isRegister) ...[
                        PicaflorTextField(
                          controller: _nameCtrl,
                          label: 'Nombre',
                          hint: '¿Cómo te llaman?',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (!isRegister) return null;
                            if (v == null || v.trim().length < 2) {
                              return 'Pon al menos 2 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      PicaflorTextField(
                        controller: _emailCtrl,
                        label: 'Correo',
                        hint: 'tu@correo.cl',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (_tab != 0) return null;
                          if (v == null || !v.contains('@')) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PicaflorTextField(
                        controller: _passwordCtrl,
                        label: 'Contraseña',
                        hint: isRegister
                            ? 'Mínimo 6 caracteres'
                            : 'Tu contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitEmail(),
                        validator: (v) {
                          if (_tab != 0) return null;
                          if (v == null || v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      if (!isRegister)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: auth.isLoading ? null : _forgotPassword,
                            child: const Text('¿Olvidaste tu clave?'),
                          ),
                        )
                      else
                        const SizedBox(height: AppSpacing.lg),
                    ] else ...[
                      if (!phoneSent && isRegister) ...[
                        PicaflorTextField(
                          controller: _nameCtrl,
                          label: 'Nombre',
                          hint: '¿Cómo te llaman?',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (!phoneSent)
                        PicaflorTextField(
                          controller: _phoneCtrl,
                          label: 'Celular',
                          hint: '+56 9 1234 5678',
                          prefixIcon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _sendSms(),
                        )
                      else
                        PicaflorTextField(
                          controller: _smsCtrl,
                          label: 'Código SMS',
                          hint: '6 dígitos',
                          prefixIcon: Icons.sms_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _confirmSms(),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3D1515)
                              : AppColors.errorSoft,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm + 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (_tab == 0)
                      PicaflorButton(
                        label: isRegister ? 'Crear cuenta' : 'Entrar',
                        onPressed: auth.isLoading ? null : _submitEmail,
                        isLoading: auth.isLoading &&
                            auth.lastMethod == AuthMethod.email,
                      )
                    else if (!phoneSent)
                      PicaflorButton(
                        label: 'Enviar código',
                        onPressed: auth.isLoading ? null : _sendSms,
                        isLoading: auth.isLoading &&
                            auth.lastMethod == AuthMethod.phone,
                      )
                    else
                      Column(
                        children: [
                          PicaflorButton(
                            label: 'Confirmar',
                            onPressed: auth.isLoading ? null : _confirmSms,
                            isLoading: auth.isLoading &&
                                auth.lastMethod == AuthMethod.phone,
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .resetPhoneFlow(),
                            child: const Text('Cambiar número'),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            'o continúa con',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    PicaflorSocialButton(
                      label: 'Google',
                      onPressed: auth.isLoading ? null : _google,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    ),
                    if (_showApple) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PicaflorSocialButton(
                        label: 'Apple',
                        onPressed: auth.isLoading ? null : _apple,
                        icon: const Icon(Icons.apple_rounded, size: 22),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRegister
                              ? '¿Ya tienes cuenta? '
                              : '¿Primera vez? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: auth.isLoading
                              ? null
                              : () {
                                  Haptic.selection();
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .toggleMode();
                                },
                          child: Text(
                            isRegister ? 'Inicia sesión' : 'Regístrate',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: selected
            ? (isDark ? AppColors.darkCard : AppColors.lightSurface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: () {
            Haptic.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
