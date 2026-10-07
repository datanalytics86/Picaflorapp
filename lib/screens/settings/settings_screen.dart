import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design_system/components/pf_mark.dart';
import '../../features/safety/safety_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/picaflor_card.dart';

/// Ajustes: tema, privacidad, cuenta.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ajustes'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
          child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppLayout.pageX(context),
          AppSpacing.sm,
          AppLayout.pageX(context),
          AppSpacing.xxl,
        ),
        children: [
          const _SectionLabel('Apariencia'),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ThemeOption(
                  title: 'Claro',
                  subtitle: 'Fondo limpio',
                  icon: Icons.light_mode_outlined,
                  selected: themeMode == ThemeMode.light,
                  onTap: () {
                    Haptic.selection();
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                  },
                ),
                _div(isDark),
                _ThemeOption(
                  title: 'Oscuro',
                  subtitle: 'Más cómodo de noche',
                  icon: Icons.dark_mode_outlined,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () {
                    Haptic.selection();
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                  },
                ),
                _div(isDark),
                _ThemeOption(
                  title: 'Sistema',
                  subtitle: 'Sigue el teléfono',
                  icon: Icons.brightness_auto_outlined,
                  selected: themeMode == ThemeMode.system,
                  onTap: () {
                    Haptic.selection();
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Privacidad'),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Visibilidad'),
                  subtitle: const Text('Se controla desde tu perfil'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                  onTap: () => context.pop(),
                ),
                _div(isDark),
                const ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Ubicación aproximada'),
                  subtitle: Text(
                    'Nunca guardamos tu punto exacto · solo zona cercana',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Cuenta'),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Picaflor Plus'),
                  subtitle: const Text(
                    AppConfig.plusEnabled
                        ? 'Gestionar suscripción'
                        : 'Lista de espera · todavía no se cobra',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.plus),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Descargar mis datos'),
                  subtitle: const Text(
                    'Una copia de lo que tenemos de ti en este dispositivo o en la nube.',
                  ),
                  onTap: () => _exportData(context, ref),
                ),
                _div(isDark),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: Text(
                    'Eliminar cuenta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Se borra en este dispositivo y, en producción, en la nube.',
                  ),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'Cerrar sesión',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () async {
                await Haptic.warning();
                if (!context.mounted) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Cerrar sesión?'),
                    content: const Text(
                      'Vas a salir de tu cuenta en este dispositivo.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Acerca de'),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm + 2),
                      ),
                      child: const PfMark(
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const _VersionLabel(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gente cerca, charlas reales. Hecho para Santiago.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                if (AppConfig.demoMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.primarySoft,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm + 2),
                    ),
                    child: Text(
                      'Modo demo activo · datos en memoria · sin Firebase',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Legal'),
          const SizedBox(height: AppSpacing.sm),
          PicaflorSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacidad'),
                  subtitle: const Text(
                    AppConfig.privacyPolicyUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openExternal(AppConfig.privacyPolicyUrl),
                ),
                _div(isDark),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Términos'),
                  subtitle: const Text(
                    AppConfig.termsUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openExternal(AppConfig.termsUrl),
                ),
                _div(isDark),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text('Soporte'),
                  subtitle: const Text(AppConfig.supportEmail),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openExternal('mailto:${AppConfig.supportEmail}'),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _div(bool isDark) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: selected ? AppColors.primary : null),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final version = snap.data?.version;
        return Text(
          version == null ? 'Versión' : 'Versión $version',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}

Future<void> _openExternal(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri);
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  try {
    final data = await ref.read(safetyControllerProvider).exportMyData();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tus datos'),
        content: SingleChildScrollView(
          child: Text(data.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos preparar la copia. Inténtalo de nuevo.')),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: const Text(
        'Se cierra tu sesión y pedimos el borrado de tus datos. '
        'En producción el plazo es de 30 días.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return;
  final second = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirma otra vez'),
      content: const Text('Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar cuenta'),
        ),
      ],
    ),
  );
  if (second != true || !context.mounted) return;
  await ref.read(safetyControllerProvider).deleteAccount();
  await ref.read(authControllerProvider.notifier).signOut();
  if (context.mounted) context.go(AppRoutes.login);
}
