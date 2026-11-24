/// Resultado auditable de evaluar una respuesta con el modelo adaptativo.
///
/// Fórmulas tomadas literalmente de `docs/agents.md` (Módulo 3):
///  * acierto rápido (t <= t_ref):  dM = +(6 + d)
///  * acierto lento  (t >  t_ref):  dM = +(3 + 0.5 * d)
///  * error:                        dM = -(8 - d)
///  * M_nuevo = clamp(M_actual + dM, 0, 100)
///  * M < 25 -> d=1; 25..<45 -> d=2; 45..<65 -> d=3; 65..<85 -> d=4; >=85 -> d=5
///  * 2 errores consecutivos -> d_sig = max(1, d_base - 1) + refuerzo.
class AdaptiveDecision {
  const AdaptiveDecision({
    required this.previousMastery,
    required this.newMastery,
    required this.masteryDelta,
    required this.isFast,
    required this.newConsecutiveErrors,
    required this.targetDifficulty,
    required this.needsReinforcement,
  });

  final double previousMastery;
  final double newMastery;
  final double masteryDelta;
  final bool isFast;
  final int newConsecutiveErrors;
  final int targetDifficulty;
  final bool needsReinforcement;

  String get difficultyLabel =>
      AdaptiveCalculator.difficultyLabel(targetDifficulty);

  bool get masteryIncreased => masteryDelta > 0;
}

/// Motor matemático puro del Módulo 3.
///
/// No depende de Flutter ni de la base de datos: es 100% testeable con
/// `flutter_test` y auditable ante el docente.
abstract final class AdaptiveCalculator {
  static const double initialMastery = 20;
  static const int minDifficulty = 1;
  static const int maxDifficulty = 5;
  static const int reinforcementThreshold = 2;

  static double clampMastery(double value) {
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  static int clampDifficulty(int value) {
    if (value < minDifficulty) return minDifficulty;
    if (value > maxDifficulty) return maxDifficulty;
    return value;
  }

  /// Ajuste de dominio dM según acierto/error, dificultad y fluidez.
  static double masteryDelta({
    required bool isCorrect,
    required int difficulty,
    required int responseTimeMs,
    required int expectedTimeMs,
  }) {
    final d = clampDifficulty(difficulty);
    if (!isCorrect) {
      return -(8 - d).toDouble();
    }
    if (responseTimeMs <= expectedTimeMs) {
      return (6 + d).toDouble();
    }
    return 3 + 0.5 * d;
  }

  static double nextMastery({
    required double currentMastery,
    required bool isCorrect,
    required int difficulty,
    required int responseTimeMs,
    required int expectedTimeMs,
  }) {
    return clampMastery(
      currentMastery +
          masteryDelta(
            isCorrect: isCorrect,
            difficulty: difficulty,
            responseTimeMs: responseTimeMs,
            expectedTimeMs: expectedTimeMs,
          ),
    );
  }

  /// Dificultad objetivo a partir del nivel de dominio M.
  static int difficultyForMastery(double mastery) {
    final m = clampMastery(mastery);
    if (m < 25) return 1;
    if (m < 45) return 2;
    if (m < 65) return 3;
    if (m < 85) return 4;
    return 5;
  }

  /// Evalúa una respuesta y devuelve el estado adaptativo completo.
  static AdaptiveDecision evaluateAnswer({
    required double currentMastery,
    required bool isCorrect,
    required int difficulty,
    required int responseTimeMs,
    required int expectedTimeMs,
    required int previousConsecutiveErrors,
  }) {
    final delta = masteryDelta(
      isCorrect: isCorrect,
      difficulty: difficulty,
      responseTimeMs: responseTimeMs,
      expectedTimeMs: expectedTimeMs,
    );
    final newMastery = clampMastery(currentMastery + delta);
    final newErrors =
        isCorrect ? 0 : (previousConsecutiveErrors + 1);
    final needsReinforcement = newErrors >= reinforcementThreshold;
    final baseDifficulty = difficultyForMastery(newMastery);
    final targetDifficulty = needsReinforcement
        ? clampDifficulty(baseDifficulty - 1)
        : baseDifficulty;

    return AdaptiveDecision(
      previousMastery: currentMastery,
      newMastery: newMastery,
      masteryDelta: delta,
      isFast: isCorrect && responseTimeMs <= expectedTimeMs,
      newConsecutiveErrors: newErrors,
      targetDifficulty: targetDifficulty,
      needsReinforcement: needsReinforcement,
    );
  }

  static String difficultyLabel(int difficulty) {
    return switch (clampDifficulty(difficulty)) {
      1 => 'Básico',
      2 => 'Elemental',
      3 => 'Intermedio',
      4 => 'Avanzado',
      _ => 'Experto',
    };
  }
}
