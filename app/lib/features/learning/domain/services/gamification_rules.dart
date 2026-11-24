/// Reglas de gamificación (XP, niveles y racha diaria).
///
/// Se mantienen separadas del motor adaptativo porque responden a una
/// finalidad distinta: motivación, no cálculo de dominio.
abstract final class GamificationRules {
  static const int xpBase = 10;
  static const int xpPorDificultad = 2;
  static const int bonusRapidez = 3;
  static const int xpPorNivel = 100;

  /// XP por respuesta correcta: base + dificultad + bonus por fluidez.
  /// Una respuesta incorrecta no otorga XP.
  static int xpForAttempt({
    required bool isCorrect,
    required int difficulty,
    required int responseTimeMs,
    required int expectedTimeMs,
  }) {
    if (!isCorrect) return 0;
    final speedBonus = responseTimeMs <= expectedTimeMs ? bonusRapidez : 0;
    return xpBase + xpPorDificultad * difficulty + speedBonus;
  }

  static int levelForXp(int xpTotal) {
    final safeXp = xpTotal < 0 ? 0 : xpTotal;
    return 1 + safeXp ~/ xpPorNivel;
  }

  /// Calcula la racha diaria al practicar hoy.
  ///
  /// * Sin práctica previa -> 1.
  /// * Misma fecha -> conserva la racha.
  /// * Día consecutivo -> +1.
  /// * Hueco mayor -> reinicia en 1.
  static int nextStreak({
    required int currentStreak,
    required DateTime? lastPractice,
    required DateTime today,
  }) {
    if (lastPractice == null) return 1;
    final last = DateTime(
      lastPractice.year,
      lastPractice.month,
      lastPractice.day,
    );
    final now = DateTime(today.year, today.month, today.day);
    final difference = now.difference(last).inDays;
    if (difference <= 0) {
      return currentStreak <= 0 ? 1 : currentStreak;
    }
    if (difference == 1) {
      return currentStreak + 1;
    }
    return 1;
  }
}
