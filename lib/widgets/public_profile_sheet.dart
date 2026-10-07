import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/privacy/buckets.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/location_privacy.dart';
import '../features/safety/report_reasons.dart';
import '../features/safety/safety_controller.dart';
import '../features/waves/wave_actions.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'picaflor_avatar.dart';

class PublicProfileSheet extends ConsumerWidget {
  const PublicProfileSheet({
    super.key,
    required this.uid,
    this.distanceMeters,
  });

  final String uid;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userByIdProvider(uid)).valueOrNull;
    final me = ref.watch(sessionProvider)?.uid ?? '';
    final blocked = ref.watch(safetyControllerProvider).isBlocked(uid);
    final name = user?.displayName ?? 'Persona';
    final activity = user?.activityBucket != null
        ? ActivityBuckets.label(user!.activityBucket!)
        : 'zona aproximada';
    final distance = distanceMeters == null
        ? 'distancia aproximada'
        : LocationPrivacy.formatApproxDistance(distanceMeters!);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PicaflorAvatar(
                  photoUrl: user?.photoUrl,
                  displayName: name,
                  size: 64,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '$distance · $activity',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (value) async {
                    if (value == 'block') {
                      await ref.read(safetyControllerProvider).block(uid);
                      if (context.mounted) Navigator.pop(context);
                    } else if (value == 'report') {
                      final sent = await promptReport(context, ref, uid);
                      if (sent && context.mounted) Navigator.pop(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'block', child: Text('Bloquear')),
                    PopupMenuItem(value: 'report', child: Text('Reportar')),
                  ],
                ),
              ],
            ),
            if ((user?.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(user!.bio),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu ubicación exacta nunca se comparte.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (blocked)
              const Text('Bloqueaste a esta persona.')
            else
              FilledButton(
                onPressed: me.isEmpty
                    ? null
                    : () async {
                        try {
                          await ref.read(waveActionsProvider).send(
                                fromUid: me,
                                toUid: uid,
                                plus: false,
                              );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Saludo enviado. El chat se abre si te aceptan.',
                              ),
                            ),
                          );
                        } on WaveException catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                child: const Text('Saludar'),
              ),
          ],
        ),
      ),
    );
  }

}

/// Pide un motivo y envía el reporte. Devuelve true si se envió.
Future<bool> promptReport(
  BuildContext context,
  WidgetRef ref,
  String uid,
) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Reportar'),
      children: [
        for (final id in ReportReasons.ids)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, id),
            child: Text(ReportReasons.label(id)),
          ),
      ],
    ),
  );
  if (reason == null) return false;
  await ref.read(safetyControllerProvider).report(
        otherUid: uid,
        reason: reason,
      );
  if (!context.mounted) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Gracias. Lo revisamos en menos de 24 h.'),
    ),
  );
  return true;
}
