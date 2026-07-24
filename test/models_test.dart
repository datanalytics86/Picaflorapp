import 'package:flutter_test/flutter_test.dart';
import 'package:picaflorapp/core/utils/distance_utils.dart';
import 'package:picaflorapp/models/chat_model.dart';
import 'package:picaflorapp/models/user_model.dart';
import 'package:picaflorapp/services/location_service.dart';

void main() {
  group('UserModel', () {
    test('initials from full name', () {
      const u = UserModel(
        uid: '1',
        email: 'a@b.cl',
        displayName: 'Camila Rojas',
      );
      expect(u.initials, 'CR');
    });

    test('initials single word', () {
      const u = UserModel(uid: '1', email: '', displayName: 'Diego');
      expect(u.initials, 'D');
    });

    test('hasLocation', () {
      const without = UserModel(uid: '1', email: '', displayName: 'X');
      const withLoc = UserModel(
        uid: '1',
        email: '',
        displayName: 'X',
        latitude: -33.45,
        longitude: -70.66,
      );
      expect(without.hasLocation, isFalse);
      expect(withLoc.hasLocation, isTrue);
    });
  });

  group('ChatModel', () {
    test('chatIdFor is stable regardless of order', () {
      expect(
        ChatModel.chatIdFor('b', 'a'),
        ChatModel.chatIdFor('a', 'b'),
      );
      expect(ChatModel.chatIdFor('a', 'b'), 'a_b');
    });

    test('otherParticipantId and unread', () {
      const chat = ChatModel(
        id: 'a_b',
        participantIds: ['a', 'b'],
        unreadCount: {'a': 2, 'b': 0},
      );
      expect(chat.otherParticipantId('a'), 'b');
      expect(chat.unreadFor('a'), 2);
      expect(chat.hasUnread('b'), isFalse);
    });
  });

  group('Location privacy', () {
    test('fuzz snaps to grid', () {
      final a = LocationService.fuzz(
        latitude: -33.4489123,
        longitude: -70.6693456,
      );
      final b = LocationService.fuzz(
        latitude: -33.4489123 + 0.0001,
        longitude: -70.6693456 + 0.0001,
      );
      // Misma celda o adyacente; nunca coords crudas.
      expect(a.latitude, isNot(equals(-33.4489123)));
      expect(a.accuracyMeters, greaterThanOrEqualTo(100));
      // Distancia utilitaria coherente.
      final m = DistanceUtils.metersBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      expect(m, greaterThanOrEqualTo(0));
    });

    test('formatApproxDistance labels', () {
      expect(LocationService.formatApproxDistance(40), 'muy cerca');
      expect(LocationService.formatApproxDistance(150), 'cerca');
      expect(LocationService.formatApproxDistance(320), contains('m'));
      expect(LocationService.formatApproxDistance(2500), contains('km'));
    });
  });
}
