import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/privacy/buckets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic.dart';
import '../../core/utils/time_ago.dart';
import '../../features/safety/safety_controller.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/message_input.dart';
import '../../widgets/picaflor_avatar.dart';
import '../../widgets/public_profile_sheet.dart';

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
  Timer? _readDebounce;
  String? _lastMarkedMessageId;
  final List<MessageModel> _older = [];
  bool _loadingOlder = false;
  bool _noMoreOlder = false;

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
    _readDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _markReadOnce() {
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null || widget.chatId.isEmpty) return;
    ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
  }

  void _scheduleMarkRead(List<MessageModel> messages, String myUid) {
    if (messages.isEmpty || myUid.isEmpty) return;
    final incoming = messages.last;
    if (incoming.senderId == myUid) return;
    if (incoming.id.isEmpty || incoming.id == _lastMarkedMessageId) return;
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 350), () {
      _lastMarkedMessageId = incoming.id;
      ref.read(chatControllerProvider.notifier).markAsRead(widget.chatId);
    });
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

  Future<void> _loadOlder(List<MessageModel> visible) async {
    if (_loadingOlder || _noMoreOlder || visible.isEmpty) return;
    final before = visible.first.createdAt;
    if (before == null) return;
    setState(() => _loadingOlder = true);
    try {
      final fetched = await ref.read(chatServiceProvider).fetchOlderMessages(
            chatId: widget.chatId,
            before: before,
          );
      if (!mounted) return;
      final known = visible.map((m) => m.id).toSet();
      final fresh = fetched.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _loadingOlder = false;
        if (fresh.isEmpty) {
          _noMoreOlder = true;
        } else {
          _older.insertAll(0, fresh);
        }
      });
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  List<MessageModel> _merged(List<MessageModel> live) {
    if (_older.isEmpty) return live;
    final seen = <String>{};
    final all = <MessageModel>[..._older, ...live];
    all.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return [
      for (final message in all)
        if (seen.add(message.id)) message,
    ];
  }

  Future<void> _onChatMenu(String value, String otherUid) async {
    if (otherUid.isEmpty) return;
    if (value == 'profile') {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => PublicProfileSheet(uid: otherUid),
      );
      return;
    }
    if (value == 'block') {
      await ref.read(safetyControllerProvider).block(otherUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloqueaste a esta persona.')),
      );
      context.pop();
      return;
    }
    if (value == 'report') {
      await promptReport(context, ref, otherUid);
    }
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

    final other = ref.watch(userByIdProvider(resolvedOtherUid)).valueOrNull;
    final isDemo = resolvedOtherUid.startsWith('demo_');

    ref.listen(chatMessagesProvider(widget.chatId), (prev, next) {
      final prevLen = prev?.valueOrNull?.length ?? 0;
      final nextList = next.valueOrNull;
      final nextLen = nextList?.length ?? 0;
      if (nextLen > prevLen) {
        _scrollToEnd();
        if (nextList != null) _scheduleMarkRead(nextList, myUid);
      }
    });

    final messages = _merged(
      messagesAsync.valueOrNull ?? const <MessageModel>[],
    );

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
                        : (other?.activityBucket != null
                            ? ActivityBuckets.label(other!.activityBucket!)
                            : TimeAgo.lastSeen(
                                other?.lastSeen,
                                isOnline: false,
                              )),
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (value) => _onChatMenu(value, resolvedOtherUid),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Ver perfil')),
              PopupMenuItem(value: 'block', child: Text('Bloquear')),
              PopupMenuItem(value: 'report', child: Text('Reportar')),
            ],
          ),
        ],
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
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return TextButton(
                              onPressed: _loadingOlder || _noMoreOlder
                                  ? null
                                  : () => _loadOlder(messages),
                              child: Text(
                                _noMoreOlder
                                    ? 'No hay mensajes más antiguos'
                                    : (_loadingOlder
                                        ? 'Cargando…'
                                        : 'Mensajes anteriores'),
                              ),
                            );
                          }
                          final msgIndex = index - 1;
                          final msg = messages[msgIndex];
                          final prev = msgIndex > 0 ? messages[msgIndex - 1] : null;
                          final showDay = _shouldShowDay(prev, msg);
                          final isMine = msg.isMine(myUid);
                          final showTail = msgIndex == messages.length - 1 ||
                              messages[msgIndex + 1].senderId != msg.senderId;

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
