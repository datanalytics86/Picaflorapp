import 'dart:async';
import 'dart:math';

import '../core/config/app_config.dart';
import '../core/constants/santiago_bounds.dart';
import '../models/auth_session.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../core/utils/location_privacy.dart';
import 'demo_nearby.dart';

/// Store en memoria para el modo demo (sin Firebase).
///
/// Soporta sesión, perfil, chats y mensajes con streams reactivos.
class DemoStore {
  DemoStore._() {
    _seedCatalog();
  }

  static final DemoStore instance = DemoStore._();

  final _rng = Random(42);

  // ── Auth ───────────────────────────────────────────────────────────────
  AuthSession? _session;
  final _authCtrl = StreamController<AuthSession?>.broadcast();

  AuthSession? get session => _session;
  String? get currentUid => _session?.uid;

  /// Stream de sesión: emite altiro el valor actual y luego cambios.
  /// Usa [Stream.multi] (no `async*` + broadcast) para que Riverpod
  /// no se quede en `isLoading` eterno en web.
  Stream<AuthSession?> get authStateChanges {
    return Stream<AuthSession?>.multi((listener) {
      listener.add(_session);
      final sub = _authCtrl.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = () => sub.cancel();
    });
  }

  // ── Users ──────────────────────────────────────────────────────────────
  final Map<String, UserModel> _users = {};
  final Map<String, StreamController<UserModel?>> _userWatchers = {};

  // ── Chats / messages ───────────────────────────────────────────────────
  final Map<String, ChatModel> _chats = {};
  final Map<String, List<MessageModel>> _messages = {};
  final _chatsCtrl = StreamController<void>.broadcast();
  final Map<String, StreamController<void>> _messageCtrls = {};

  void _seedCatalog() {
    final people = DemoNearby.people(
      originLat: SantiagoBounds.centerLatitude,
      originLon: SantiagoBounds.centerLongitude,
    );
    for (final p in people) {
      _users[p.user.uid] = p.user;
    }
  }

  UserModel _defaultMe({
    String? email,
    String? displayName,
  }) {
    final now = DateTime.now();
    // Ubicación siempre referencial (~150 m), nunca exacta.
    final approx = LocationPrivacy.santiagoCenterApprox();
    return UserModel(
      uid: AppConfig.demoUid,
      email: email ?? AppConfig.demoEmail,
      displayName: displayName ?? AppConfig.demoDisplayName,
      bio: AppConfig.demoBio,
      interests: const ['demo', 'santiago', 'café'],
      latitude: approx.latitude,
      longitude: approx.longitude,
      isOnline: true,
      isVisible: true,
      lastSeen: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ── Auth API ───────────────────────────────────────────────────────────

  Future<UserModel> signInDemo({
    String? email,
    String? displayName,
  }) async {
    // Sin delay artificial: en web se siente como freeze.
    final me = _users[AppConfig.demoUid] ??
        _defaultMe(email: email, displayName: displayName);
    final profile = me.copyWith(
      email: email ?? me.email,
      displayName: displayName ?? me.displayName,
      isOnline: true,
      lastSeen: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users[profile.uid] = profile;
    _notifyUser(profile.uid);

    // Seed un chat de bienvenida con Camila si no hay chats.
    _ensureWelcomeChat(profile.uid);

    _session = AuthSession(
      uid: profile.uid,
      email: profile.email,
      displayName: profile.displayName,
    );
    _authCtrl.add(_session);
    _chatsCtrl.add(null);
    return profile;
  }

  Future<void> signOut() async {
    final uid = _session?.uid;
    if (uid != null) {
      final u = _users[uid];
      if (u != null) {
        _users[uid] = u.copyWith(isOnline: false, lastSeen: DateTime.now());
        _notifyUser(uid);
      }
    }
    _session = null;
    _authCtrl.add(null);
  }

  void _ensureWelcomeChat(String myUid) {
    const other = 'demo_camila';
    final chatId = ChatModel.chatIdFor(myUid, other);
    if (_chats.containsKey(chatId)) return;

    final now = DateTime.now();
    final msgs = <MessageModel>[
      MessageModel(
        id: 'm1_$chatId',
        chatId: chatId,
        senderId: other,
        text: '¡Hola! 👋 Soy Camila (demo). ¿Cómo va el día?',
        createdAt: now.subtract(const Duration(minutes: 28)),
        isRead: false,
      ),
      MessageModel(
        id: 'm2_$chatId',
        chatId: chatId,
        senderId: other,
        text: 'Esto es modo demo: puedes responder y se guarda solo en memoria.',
        createdAt: now.subtract(const Duration(minutes: 27)),
        isRead: false,
      ),
    ];
    _messages[chatId] = msgs;
    _chats[chatId] = ChatModel(
      id: chatId,
      participantIds: [myUid, other]..sort(),
      lastMessage: msgs.last.text,
      lastMessageSenderId: other,
      lastMessageAt: msgs.last.createdAt,
      unreadCount: {myUid: 2, other: 0},
      createdAt: now.subtract(const Duration(minutes: 30)),
      updatedAt: msgs.last.createdAt,
    );
  }

  // ── Users API ──────────────────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    _users[user.uid] = user;
    _notifyUser(user.uid);
  }

  Future<UserModel?> getUser(String uid) async {
    if (uid.startsWith('demo_') || uid == AppConfig.demoUid) {
      return _users[uid] ?? _lookupCatalog(uid);
    }
    return _users[uid];
  }

  UserModel? _lookupCatalog(String uid) {
    final people = DemoNearby.people(
      originLat: SantiagoBounds.centerLatitude,
      originLon: SantiagoBounds.centerLongitude,
    );
    for (final p in people) {
      if (p.user.uid == uid) {
        _users[uid] = p.user;
        return p.user;
      }
    }
    return null;
  }

  Stream<UserModel?> watchUser(String uid) {
    final ctrl = _userWatchers.putIfAbsent(
      uid,
      () => StreamController<UserModel?>.broadcast(),
    );
    return Stream.multi((listener) {
      listener.add(_users[uid] ?? _lookupCatalog(uid));
      final sub = ctrl.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = () => sub.cancel();
    });
  }

  void _notifyUser(String uid) {
    _userWatchers[uid]?.add(_users[uid]);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoUrl,
    List<String>? interests,
    bool? isVisible,
  }) async {
    final current = _users[uid] ?? _defaultMe();
    _users[uid] = current.copyWith(
      displayName: displayName ?? current.displayName,
      bio: bio ?? current.bio,
      photoUrl: photoUrl,
      interests: interests ?? current.interests,
      isVisible: isVisible ?? current.isVisible,
      updatedAt: DateTime.now(),
    );
    _notifyUser(uid);
  }

  Future<void> updateLocation({
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    final current = _users[uid];
    if (current == null) return;
    _users[uid] = current.copyWith(
      latitude: latitude,
      longitude: longitude,
      lastSeen: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notifyUser(uid);
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    final current = _users[uid];
    if (current == null) return;
    _users[uid] = current.copyWith(
      isOnline: isOnline,
      lastSeen: DateTime.now(),
    );
    _notifyUser(uid);
  }

  List<UserModel> nearbyUsers({
    required String currentUid,
    required double latitude,
    required double longitude,
  }) {
    final originLat = latitude;
    final originLon = longitude;
    return DemoNearby.people(originLat: originLat, originLon: originLon)
        .map((e) => e.user)
        .where((u) => u.uid != currentUid)
        .toList();
  }

  // ── Chat API ───────────────────────────────────────────────────────────

  Future<ChatModel> getOrCreateChat({
    required String currentUid,
    required String otherUid,
  }) async {
    final chatId = ChatModel.chatIdFor(currentUid, otherUid);
    final existing = _chats[chatId];
    if (existing != null) return existing;

    // Asegurar que el otro exista en catálogo.
    await getUser(otherUid);

    final now = DateTime.now();
    final chat = ChatModel(
      id: chatId,
      participantIds: [currentUid, otherUid]..sort(),
      createdAt: now,
      updatedAt: now,
      unreadCount: {currentUid: 0, otherUid: 0},
    );
    _chats[chatId] = chat;
    _messages[chatId] ??= [];
    _chatsCtrl.add(null);
    return chat;
  }

  Stream<List<ChatModel>> watchUserChats(String uid) {
    return Stream.multi((listener) {
      void emit() {
        final list = _chats.values
            .where((c) => c.participantIds.contains(uid))
            .toList()
          ..sort((a, b) {
            final aT = a.lastMessageAt ?? a.createdAt ?? DateTime(2000);
            final bT = b.lastMessageAt ?? b.createdAt ?? DateTime(2000);
            return bT.compareTo(aT);
          });
        listener.add(list);
      }

      emit();
      final sub = _chatsCtrl.stream.listen((_) => emit());
      listener.onCancel = () => sub.cancel();
    });
  }

  Stream<ChatModel?> watchChat(String chatId) {
    return Stream.multi((listener) {
      void emit() => listener.add(_chats[chatId]);
      emit();
      final sub = _chatsCtrl.stream.listen((_) => emit());
      listener.onCancel = () => sub.cancel();
    });
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    final ctrl = _messageCtrls.putIfAbsent(
      chatId,
      () => StreamController<void>.broadcast(),
    );
    return Stream.multi((listener) {
      void emit() {
        final list = List<MessageModel>.from(_messages[chatId] ?? const []);
        list.sort((a, b) {
          final aT = a.createdAt ?? DateTime(2000);
          final bT = b.createdAt ?? DateTime(2000);
          return aT.compareTo(bT);
        });
        listener.add(list);
      }

      emit();
      final sub = ctrl.stream.listen((_) => emit());
      listener.onCancel = () => sub.cancel();
    });
  }

  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String otherUid,
  }) async {
    final trimmed = text.trim();
    final now = DateTime.now();
    final id = 'local_${now.microsecondsSinceEpoch}_${_rng.nextInt(9999)}';
    final message = MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: trimmed,
      createdAt: now,
      isRead: true,
    );

    final list = _messages.putIfAbsent(chatId, () => []);
    list.add(message);

    final prev = _chats[chatId];
    final participants = prev?.participantIds ?? ([senderId, otherUid]..sort());
    final unread = Map<String, int>.from(prev?.unreadCount ?? {});
    unread[senderId] = 0;
    unread[otherUid] = (unread[otherUid] ?? 0) + 1;

    _chats[chatId] = ChatModel(
      id: chatId,
      participantIds: participants,
      lastMessage: trimmed,
      lastMessageSenderId: senderId,
      lastMessageAt: now,
      unreadCount: unread,
      createdAt: prev?.createdAt ?? now,
      updatedAt: now,
    );

    _messageCtrls[chatId]?.add(null);
    _chatsCtrl.add(null);

    // Auto-respuesta simpática del demo (solo si el otro es demo).
    if (otherUid.startsWith('demo_')) {
      unawaited(_scheduleAutoReply(
        chatId: chatId,
        myUid: senderId,
        otherUid: otherUid,
      ));
    }

    return message;
  }

  Future<void> _scheduleAutoReply({
    required String chatId,
    required String myUid,
    required String otherUid,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (_session?.uid != myUid) return;

    final replies = [
      'Jaja sí, en demo se siente real ✨',
      '¿Tomamos un café por Providencia algún día?',
      'Buena onda. Estoy por el barrio (demo).',
      'Me carga el minimalismo de la app 💚',
      'Dale, seguimos charlando acá.',
    ];
    final text = replies[_rng.nextInt(replies.length)];
    final now = DateTime.now();
    final id = 'auto_${now.microsecondsSinceEpoch}';
    final message = MessageModel(
      id: id,
      chatId: chatId,
      senderId: otherUid,
      text: text,
      createdAt: now,
      isRead: false,
    );
    _messages.putIfAbsent(chatId, () => []).add(message);

    final prev = _chats[chatId]!;
    final unread = Map<String, int>.from(prev.unreadCount);
    unread[myUid] = (unread[myUid] ?? 0) + 1;
    unread[otherUid] = 0;

    _chats[chatId] = prev.copyWith(
      lastMessage: text,
      lastMessageSenderId: otherUid,
      lastMessageAt: now,
      unreadCount: unread,
      updatedAt: now,
    );
    _messageCtrls[chatId]?.add(null);
    _chatsCtrl.add(null);
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String uid,
  }) async {
    final chat = _chats[chatId];
    if (chat == null) return;

    // Si ya está en 0, no notificar (evita rebuild loops).
    final currentUnread = chat.unreadCount[uid] ?? 0;
    if (currentUnread == 0) return;

    final unread = Map<String, int>.from(chat.unreadCount);
    unread[uid] = 0;
    _chats[chatId] = chat.copyWith(unreadCount: unread);

    // Actualiza isRead en mensajes SIN re-emitir el stream de mensajes
    // (re-emitir + listen(markAsRead) = loop infinito / freeze).
    final msgs = _messages[chatId];
    if (msgs != null) {
      _messages[chatId] = [
        for (final m in msgs)
          m.senderId == uid || m.isRead ? m : m.copyWith(isRead: true),
      ];
    }

    // Solo notifica lista de chats / badge — NO message stream.
    _chatsCtrl.add(null);
  }

  /// Snapshot síncrono de usuarios (UI chat sin esperar StreamProvider).
  Map<String, UserModel> get usersSnapshot =>
      Map<String, UserModel>.unmodifiable(_users);

  /// Snapshot síncrono de mensajes de un chat.
  List<MessageModel> messagesSnapshot(String chatId) {
    final list = List<MessageModel>.from(_messages[chatId] ?? const []);
    list.sort((a, b) {
      final aT = a.createdAt ?? DateTime(2000);
      final bT = b.createdAt ?? DateTime(2000);
      return aT.compareTo(bT);
    });
    return list;
  }

  Stream<int> watchTotalUnread(String uid) {
    return watchUserChats(uid).map((chats) {
      var total = 0;
      for (final c in chats) {
        total += c.unreadFor(uid);
      }
      return total;
    });
  }
}
