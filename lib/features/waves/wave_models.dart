class Wave {
  const Wave({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final String status;
  final DateTime createdAt;
  final String? note;
}

class MemoryWaves {
  final List<Wave> items = [];
  int _seq = 0;

  int sentToday(String uid, DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    return items
        .where((w) => w.fromUid == uid && !w.createdAt.isBefore(start))
        .length;
  }

  Wave? pendingBetween(String from, String to) {
    for (final w in items) {
      if (w.fromUid == from && w.toUid == to && w.status == 'pending') {
        return w;
      }
    }
    return null;
  }

  List<Wave> incomingPending(String uid) => items
      .where((w) => w.toUid == uid && w.status == 'pending')
      .toList(growable: false);

  Wave add({
    required String fromUid,
    required String toUid,
    String? note,
  }) {
    final wave = Wave(
      id: 'wave_${++_seq}',
      fromUid: fromUid,
      toUid: toUid,
      status: 'pending',
      createdAt: DateTime.now(),
      note: note,
    );
    items.add(wave);
    return wave;
  }
}

final memoryWaves = MemoryWaves();
