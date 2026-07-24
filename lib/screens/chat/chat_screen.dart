import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../core/utils/time_ago.dart';
import '../../data/demo_nearby.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/message_input.dart';
import '../../widgets/picaflor_avatar.dart';
import '../../widgets/picaflor_loading.dart';

/// Conversación 1:1 premium.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUid,
  });

  final String chatId;
  final String? otherUid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  UserModel? _demoUser(String uid) {
    if (!uid.startsWith('demo_')) return null;
    for (final d in DemoNearby.people(
      originLat: -33.45,
      originLon: -70.67,
    )) {
      if (d.user.uid == uid) return d.user;
    }
    return null;
  }

  Future<bool> _send(String text, String otherUid) async {
    await Haptic.light();
    final ok = await ref.read(chatControllerProvider.notifier).sendMessage(
          chatId: widget.chatId,
          text: text,
          otherUid: otherUid,
        );
    if (ok) {
      await ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
      _scrollToEnd();
    } else if (mounted) {
      final err = ref.read(chatControllerProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        ref.read(chatControllerProvider.notifier).clearError();
      }
    }
    return ok;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myUid = ref.watch(authServiceProvider).currentUid ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final sendState = ref.watch(chatControllerProvider);

    final chatAsync = ref.watch(chatByIdProvider(widget.chatId));
    final resolvedOtherUid = widget.otherUid ??
        chatAsync.valueOrNull?.otherParticipantId(myUid) ??
        '';

    final otherAsync = ref.watch(userByIdProvider(resolvedOtherUid));
    final other = otherAsync.valueOrNull ?? _demoUser(resolvedOtherUid);
    final isDemo = resolvedOtherUid.startsWith('demo_');

    ref.listen(chatMessagesProvider(widget.chatId), (_, __) {
      ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
      _scrollToEnd();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            PicaflorAvatar(
              photoUrl: other?.photoUrl,
              displayName: other?.displayName ?? '?',
              size: 40,
              isOnline: other?.isOnline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.displayName ?? 'Chat',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isDemo
                        ? 'Perfil de ejemplo'
                        : TimeAgo.lastSeen(
                            other?.lastSeen,
                            isOnline: other?.isOnline ?? false,
                          ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: (other?.isOnline ?? false) && !isDemo
                          ? AppColors.online
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (isDemo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: isDark ? const Color(0xFF1A2A3A) : AppColors.infoSoft,
              child: Text(
                'Este perfil es de ejemplo. Los mensajes no se envían.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const PicaflorLoading(message: 'Cargando mensajes…'),
              error: (_, __) => Center(
                child: Text(
                  'No se pudieron cargar los mensajes.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.waving_hand_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Di hola 👋',
                              style: theme.textTheme.headlineSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isDemo
                                ? 'Los ejemplos no reciben mensajes reales.'
                                : 'Sé el primero en escribir. Un saludo basta.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final prev = index > 0 ? messages[index - 1] : null;
                    final showDay = _shouldShowDay(prev, msg);
                    final isMine = msg.isMine(myUid);
                    final showTail = index == messages.length - 1 ||
                        messages[index + 1].senderId != msg.senderId;

                    return Column(
                      children: [
                        if (showDay && msg.createdAt != null)
                          ChatDaySeparator(date: msg.createdAt!),
                        ChatBubble(
                          message: msg,
                          isMine: isMine,
                          showTail: showTail,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            isSending: sendState.isSending,
            hint: isDemo ? 'Ejemplo · no se envía' : 'Escribe un mensaje…',
            onSend: (text) => _send(text, resolvedOtherUid),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDay(MessageModel? prev, MessageModel current) {
    if (current.createdAt == null) return false;
    if (prev?.createdAt == null) return true;
    final a = prev!.createdAt!;
    final b = current.createdAt!;
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}
