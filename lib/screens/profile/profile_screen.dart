import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/picaflor_avatar.dart';
import '../../widgets/picaflor_button.dart';
import '../../widgets/picaflor_card.dart';
import '../../widgets/picaflor_loading.dart';
import '../../widgets/picaflor_text_field.dart';

/// Perfil mínimo pero premium.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _startEdit(String name, String bio) {
    _nameCtrl.text = name;
    _bioCtrl.text = bio;
    setState(() => _editing = true);
  }

  Future<void> _save(String uid) async {
    await Haptic.medium();
    final ok = await ref.read(profileControllerProvider.notifier).save(
          uid: uid,
          displayName: _nameCtrl.text,
          bio: _bioCtrl.text,
        );
    if (ok && mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final editState = ref.watch(profileControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          loading: () => const PicaflorLoading(),
          error: (_, __) =>
              const Center(child: Text('Error al cargar perfil')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Sin sesión'));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.md,
                AppSpacing.pageX,
                AppSpacing.xxl,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Perfil',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Haptic.light();
                        context.push(AppRoutes.settings);
                      },
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Ajustes',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: PicaflorAvatar(
                    photoUrl: user.photoUrl,
                    displayName: user.displayName,
                    size: 96,
                    isOnline: user.isOnline,
                    showBorder: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_editing) ...[
                  Text(
                    user.displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      user.bio,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.center,
                      children: user.interests
                          .map(
                            (i) => Chip(
                              label: Text(i),
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.primarySoft,
                              side: BorderSide.none,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  PicaflorButton(
                    label: 'Editar perfil',
                    variant: PicaflorButtonVariant.outline,
                    icon: Icons.edit_outlined,
                    onPressed: () => _startEdit(user.displayName, user.bio),
                  ),
                ] else ...[
                  PicaflorTextField(
                    controller: _nameCtrl,
                    label: 'Nombre',
                    hint: 'Tu nombre',
                    prefixIcon: Icons.person_outline_rounded,
                    maxLength: AppConstants.maxDisplayNameLength,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PicaflorTextField(
                    controller: _bioCtrl,
                    label: 'Bio',
                    hint: 'Una línea sobre ti…',
                    maxLines: 3,
                    maxLength: AppConstants.maxBioLength,
                  ),
                  if (editState.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      editState.error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: PicaflorButton(
                          label: 'Cancelar',
                          variant: PicaflorButtonVariant.ghost,
                          onPressed: editState.isSaving
                              ? null
                              : () => setState(() => _editing = false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PicaflorButton(
                          label: 'Guardar',
                          isLoading: editState.isSaving,
                          onPressed: editState.isSaving
                              ? null
                              : () => _save(user.uid),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PicaflorSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: SwitchListTile(
                    value: user.isVisible,
                    onChanged: (v) {
                      Haptic.selection();
                      ref
                          .read(profileControllerProvider.notifier)
                          .setVisibility(user.uid, v);
                    },
                    title: Text(
                      'Visible cerca de mí',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      user.isVisible
                          ? 'Otros pueden verte en Cerca'
                          : 'Estás en modo invisible',
                      style: theme.textTheme.bodySmall,
                    ),
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PicaflorSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Ajustes'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                        ),
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
                            await ref
                                .read(authControllerProvider.notifier)
                                .signOut();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
