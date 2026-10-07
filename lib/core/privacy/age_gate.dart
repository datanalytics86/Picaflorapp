/// Puerta de edad 18+. Puro Dart, sin plugins.
abstract final class AgeGate {
  static const int minAge = 18;

  /// Cumple [minAge] en el calendario (no solo 18*365 días).
  static bool isAdult(DateTime birthDate, DateTime today) {
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final now = DateTime(today.year, today.month, today.day);
    if (birth.isAfter(now)) return false;
    var age = now.year - birth.year;
    final birthdayThisYear = DateTime(now.year, birth.month, birth.day);
    if (now.isBefore(birthdayThisYear)) age -= 1;
    return age >= minAge;
  }

  static int ageYears(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final birthdayThisYear = DateTime(today.year, birthDate.month, birthDate.day);
    if (today.isBefore(birthdayThisYear)) age -= 1;
    return age;
  }
}
