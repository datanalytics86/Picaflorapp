/// Motivos de reporte. El id viaja al servidor; la etiqueta es es-CL.
abstract final class ReportReasons {
  static const ids = [
    'spam',
    'harassment',
    'sexual',
    'minor',
    'fake',
    'other',
  ];

  static String label(String id) {
    return switch (id) {
      'spam' => 'Spam o estafa',
      'harassment' => 'Acoso',
      'sexual' => 'Contenido sexual no deseado',
      'minor' => 'Posible menor de edad',
      'fake' => 'Perfil falso',
      _ => 'Otro',
    };
  }
}
