import '../../../learning/domain/entities/ejercicio.dart';

/// Servicio de dominio que orquesta el cálculo adaptativo y la selección
/// del siguiente ejercicio.
///
/// La lógica matemática vive en `AdaptiveCalculator` (función pura) y este
/// servicio añade la política de selección del banco de preguntas.
class AdaptiveEngine {
  const AdaptiveEngine();

  /// Selecciona el siguiente ejercicio del subtema (lección) según la
  /// dificultad objetivo.
  ///
  /// * Modo normal: prioriza la dificultad exacta; si no existe, la más
  ///   cercana (fallback) y, a igualdad, el menor `id` (orden estable).
  /// * Modo refuerzo: prioriza la dificultad más baja disponible para
  ///   reducir la frustración tras dos errores consecutivos.
  Ejercicio selectNextExercise({
    required List<Ejercicio> remaining,
    required int targetDifficulty,
    required bool reinforcement,
  }) {
    if (remaining.isEmpty) {
      throw StateError('No quedan ejercicios disponibles para esta lección.');
    }

    final candidates = List<Ejercicio>.of(remaining);
    if (reinforcement) {
      candidates.sort((a, b) {
        final byDifficulty = a.nivelDificultad.compareTo(b.nivelDificultad);
        if (byDifficulty != 0) return byDifficulty;
        return a.id.compareTo(b.id);
      });
      return candidates.first;
    }

    candidates.sort((a, b) {
      final distanceA = (a.nivelDificultad - targetDifficulty).abs();
      final distanceB = (b.nivelDificultad - targetDifficulty).abs();
      if (distanceA != distanceB) return distanceA.compareTo(distanceB);
      return a.id.compareTo(b.id);
    });
    return candidates.first;
  }
}
