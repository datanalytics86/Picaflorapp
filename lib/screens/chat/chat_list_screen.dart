import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../core/utils/time_ago.dart';
import '../../data/demo_nearby.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/picaflor_avatar.dart';
import '../../widgets/picaflor_empty_state.dart';
import '../../widgets/picaflor_skeleton.dart';

/// Lista de conversaciones — minimalista estilo fintech.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatsAsync = ref.watch(userChatsProvider);
    final myUid = ref.watch(authServiceProvider).currentUid ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.md,
                AppSpacing.pageX,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensajes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Tus charlas en Picaflor',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chatsAsync.when(
                loading: () => const PicaflorSkeleton(itemCount: 8),
                error: (_, __) => PicaflorEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'No se cargaron los chats',
                  subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
                  actionLabel: 'Reintentar',
                  onAction: () => ref.invalidate(userChatsProvider),
                ),
                data: (chats) {
                  if (chats.isEmpty) {
                    return const PicaflorEmptyState(
                      icon: Icons.forum_outlined,
                      title: 'Aún no tienes chats',
                      subtitle:
                          'Ve a Cerca, elige a alguien y mándale un saludo.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      0,
                      AppSpacing.sm,
                      AppSpacing.xl,
                    ),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 84,
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _ChatTile(
                        chat: chat,
                        myUid: myUid,
                        onTap: () async {
                          await Haptic.light();
                          final other = chat.otherParticipantId(myUid);
                          if (context.mounted) {
                            context.push(
                              AppRoutes.chatPath(chat.id, otherUid: other),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  final ChatModel chat;
  final String myUid;
  final VoidCallback onTap;

  UserModel? _demoUser(String uid) {
    if (!uid.startsWith('demo_')) return null;
    final demos = DemoNearby.people(
      originLat: -33.4489,
      originLon: -70.6693,
    );
    for (final d in demos) {
      if (d.user.uid == uid) return d.user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final otherUid = chat.otherParticipantId(myUid);
    final otherAsync = ref.watch(userByIdProvider(otherUid));
    final unread = chat.unreadFor(myUid);
    final other = otherAsync.valueOrNull ?? _demoUser(otherUid);

    final name = other?.displayName ?? 'Usuario';
    final preview = (chat.lastMessage?.isNotEmpty == true)
        ? chat.lastMessage!
        : 'Sin mensajes todavía';
    final time = TimeAgo.format(chat.lastMessageAt);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: PicaflorAvatar(
        photoUrl: other?.photoUrl,
        displayName: name,
        size: 52,
        isOnline: other?.isOnline,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: theme.textTheme.labelSmall?.copyWith(
              color: unread > 0
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary),
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: unread > 0
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : null,
                  fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.pillRadius,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
