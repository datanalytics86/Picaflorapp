import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final userChatsProvider = StreamProvider.autoDispose<List<ChatModel>>((ref) {
  final uid = ref.watch(authServiceProvider).currentUid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatServiceProvider).watchUserChats(uid);
});

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, chatId) {
  if (chatId.isEmpty) return Stream.value(const []);
  return ref.watch(chatServiceProvider).watchMessages(chatId);
});

final chatByIdProvider =
    StreamProvider.autoDispose.family<ChatModel?, String>((ref, chatId) {
  if (chatId.isEmpty) return Stream.value(null);
  return ref.watch(chatServiceProvider).watchChat(chatId);
});

final totalUnreadProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(authServiceProvider).currentUid;
  if (uid == null) return Stream.value(0);
  return ref.watch(chatServiceProvider).watchTotalUnread(uid);
});

class ChatSendState {
  const ChatSendState({this.isSending = false, this.error});

  final bool isSending;
  final String? error;

  ChatSendState copyWith({
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatSendState(
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatController extends StateNotifier<ChatSendState> {
  ChatController(this._chat, this._ref) : super(const ChatSendState());

  final ChatService _chat;
  final Ref _ref;

  Future<ChatModel?> openChatWith(String otherUid) async {
    final uid = _ref.read(authServiceProvider).currentUid;
    if (uid == null || otherUid.isEmpty || uid == otherUid) return null;
    try {
      return await _chat.getOrCreateChat(
        currentUid: uid,
        otherUid: otherUid,
      );
    } on ChatException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(error: 'No se pudo abrir el chat.');
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatId,
    required String text,
    required String otherUid,
  }) async {
    final uid = _ref.read(authServiceProvider).currentUid;
    if (uid == null) return false;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      await _chat.sendTextMessage(
        chatId: chatId,
        senderId: uid,
        text: text,
        otherUid: otherUid,
      );
      state = state.copyWith(isSending: false);
      return true;
    } on ChatException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        error: 'No se pudo enviar. Inténtalo de nuevo.',
      );
      return false;
    }
  }

  Future<void> markAsRead(String chatId) async {
    final uid = _ref.read(authServiceProvider).currentUid;
    if (uid == null) return;
    await _chat.markChatAsRead(chatId: chatId, uid: uid);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatSendState>((ref) {
  return ChatController(ref.watch(chatServiceProvider), ref);
});
