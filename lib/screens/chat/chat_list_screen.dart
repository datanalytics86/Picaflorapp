import 'package:flutter/foundation.dart';
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

/// Lista de conversaciones — minimalista estilo fintech, usable en PC.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatsAsync = ref.watch(userChatsProvider);
    final myUid = ref.watch(authServiceProvider).currentUid ?? '';
    final px = AppLayout.pageX(context);
    final wide = AppLayout.isWide(context);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    px,
                    wide ? 28 : 20,
                    px,
                    wide ? 14 : 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mensajes',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          fontSize: wide ? 26 : 22,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: wide ? 6 : 5),
                      Text(
                        'Tus charlas en Picaflor',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: wide ? 14 : 13,
                          height: 1.35,
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
                        padding: EdgeInsets.fromLTRB(
                          px,
                          AppSpacing.xs,
                          px,
                          wide ? AppSpacing.xxl : AppSpacing.xl,
                        ),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: wide ? 10 : 8),
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
                                  AppRoutes.chatPath(
                                    chat.id,
                                    otherUid: other,
                                  ),
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
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerStatefulWidget {
  const _ChatTile({
    required this.chat,
    required this.myUid,
    required this.onTap,
  });

  final ChatModel chat;
  final String myUid;
  final VoidCallback onTap;

  @override
  ConsumerState<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends ConsumerState<_ChatTile> {
  bool _hovered = false;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final otherUid = widget.chat.otherParticipantId(widget.myUid);
    final otherAsync = ref.watch(userByIdProvider(otherUid));
    final unread = widget.chat.unreadFor(widget.myUid);
    final other = otherAsync.valueOrNull ?? _demoUser(otherUid);

    final name = other?.displayName ?? 'Usuario';
    final preview = (widget.chat.lastMessage?.isNotEmpty == true)
        ? widget.chat.lastMessage!
        : 'Sin mensajes todavía';
    final time = TimeAgo.format(widget.chat.lastMessageAt);
    final elevated = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: elevated
              ? (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurface)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: elevated && !isDark
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.cardBorder(isDark: isDark),
          ),
          boxShadow: elevated
              ? AppShadows.cardHover(isDark)
              : AppShadows.card(isDark, web: kIsWeb),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            splashColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  PicaflorAvatar(
                    photoUrl: other?.photoUrl,
                    displayName: name,
                    size: 52,
                    isOnline: other?.isOnline,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.2,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: unread > 0
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary),
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
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
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                  fontWeight: unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  fontSize: 13.2,
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                constraints:
                                    const BoxConstraints(minWidth: 22),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppSpacing.pillRadius,
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
