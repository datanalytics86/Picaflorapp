import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../core/utils/time_ago.dart';
import '../../data/demo_nearby.dart';
import '../../data/demo_store.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/message_input.dart';
import '../../widgets/picaflor_avatar.dart';

/// Conversación 1:1 — sin loops de markAsRead (freeze fix).
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
  bool _didMarkRead = false;

  @override
  void initState() {
    super.initState();
    // Una sola vez, post-frame — NO en ref.listen (causaba loop infinito).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markReadOnce();
      _scrollToEnd(jump: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _markReadOnce() {
    if (_didMarkRead) return;
    _didMarkRead = true;
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null || widget.chatId.isEmpty) return;
    // Fire-and-forget, sin await en el frame.
    ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
  }

  UserModel? _resolveOther(String uid) {
    if (uid.isEmpty) return null;
    // Sync: DemoStore primero (sin StreamProvider que se quede loading).
    final fromStore = DemoStore.instance.usersSnapshot[uid];
    if (fromStore != null) return fromStore;
    if (!uid.startsWith('demo_')) return null;
    for (final d in DemoNearby.people(
      originLat: -33.4489,
      originLon: -70.6693,
    )) {
      if (d.user.uid == uid) return d.user;
    }
    return null;
  }

  Future<bool> _send(String text, String otherUid) async {
    if (otherUid.isEmpty) return false;
    await Haptic.light();
    final ok = await ref.read(chatControllerProvider.notifier).sendMessage(
          chatId: widget.chatId,
          text: text,
          otherUid: otherUid,
        );
    if (ok) {
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

  void _scrollToEnd({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent + 80;
      if (jump || kIsWeb) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myUid = ref.watch(authServiceProvider).currentUid ?? '';

    // Mensajes: StreamProvider con fallback sync desde DemoStore si loading.
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final sendState = ref.watch(chatControllerProvider);

    final chatAsync = ref.watch(chatByIdProvider(widget.chatId));
    final resolvedOtherUid = widget.otherUid ??
        chatAsync.valueOrNull?.otherParticipantId(myUid) ??
        '';

    final other = _resolveOther(resolvedOtherUid);
    final isDemo = resolvedOtherUid.startsWith('demo_');

    // Solo scroll cuando llegan mensajes nuevos — SIN markAsRead aquí.
    ref.listen(chatMessagesProvider(widget.chatId), (prev, next) {
      final prevLen = prev?.valueOrNull?.length ?? 0;
      final nextLen = next.valueOrNull?.length ?? 0;
      if (nextLen > prevLen) {
        _scrollToEnd();
      }
    });

    final messages = messagesAsync.valueOrNull ??
        DemoStore.instance.messagesSnapshot(widget.chatId);

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
              color: isDark
                  ? AppColors.info.withValues(alpha: 0.12)
                  : AppColors.infoSoft,
              child: Text(
                'Perfil de ejemplo · puedes escribir (solo en este dispositivo).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentMaxChat,
                ),
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.primary
                                          .withValues(alpha: 0.14)
                                      : AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.waving_hand_rounded,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Di hola 👋',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Sé el primero en escribir. Un saludo basta.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          AppLayout.pageX(context).clamp(16, 28),
                          AppSpacing.sm,
                          AppLayout.pageX(context).clamp(16, 28),
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
                      ),
              ),
            ),
          ),
          MessageInput(
            isSending: sendState.isSending,
            hint: 'Escribe un mensaje…',
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
