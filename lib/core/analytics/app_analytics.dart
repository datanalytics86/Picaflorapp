/// Eventos sin PII, sin coordenadas y sin texto de mensajes.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.params = const {}]);

  final String name;
  final Map<String, Object> params;

  static const forbiddenKeys = {
    'lat',
    'lon',
    'latitude',
    'longitude',
    'email',
    'phone',
    'token',
    'message',
    'text',
    'note',
  };

  bool get hasForbiddenKey {
    for (final key in params.keys) {
      if (forbiddenKeys.contains(key.toLowerCase())) return true;
    }
    return false;
  }
}

abstract class AppAnalytics {
  void track(AnalyticsEvent event);
}

class MemoryAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> events = [];
  bool consent = false;

  @override
  void track(AnalyticsEvent event) {
    if (!consent) return;
    if (event.hasForbiddenKey) {
      throw ArgumentError('Evento con dato prohibido: ${event.name}');
    }
    events.add(event);
  }
}
