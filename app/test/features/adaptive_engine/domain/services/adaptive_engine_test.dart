import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/features/adaptive_engine/domain/services/adaptive_engine.dart';
import 'package:tutor_adaptativo_sabd/features/learning/domain/entities/ejercicio.dart';

Ejercicio _ejercicio(int id, int dificultad) {
  return Ejercicio(
    id: id,
    leccionId: 1,
    tipo: TipoEjercicio.multipleChoice,
    nivelDificultad: dificultad,
    enunciado: 'Ejercicio $id',
    fragmentoCodigo: null,
    tiempoEstimadoSeg: 20,
    explicacionPedagogica: 'Explicación $id',
    activo: true,
  );
}

void main() {
  const engine = AdaptiveEngine();
  final banco = [
    _ejercicio(1, 1),
    _ejercicio(2, 2),
    _ejercicio(3, 3),
    _ejercicio(4, 4),
  ];

  test('selecciona la dificultad objetivo exacta cuando existe', () {
    final elegido = engine.selectNextExercise(
      remaining: banco,
      targetDifficulty: 3,
      reinforcement: false,
    );
    expect(elegido.nivelDificultad, 3);
  });

  test('usa la dificultad más cercana cuando la objetivo no existe', () {
    final elegido = engine.selectNextExercise(
      remaining: [_ejercicio(1, 1), _ejercicio(2, 2)],
      targetDifficulty: 5,
      reinforcement: false,
    );
    expect(elegido.nivelDificultad, 2);
  });

  test('en refuerzo prioriza la dificultad más baja disponible', () {
    final elegido = engine.selectNextExercise(
      remaining: banco,
      targetDifficulty: 4,
      reinforcement: true,
    );
    expect(elegido.nivelDificultad, 1);
  });

  test('lanza error si no quedan ejercicios', () {
    expect(
      () => engine.selectNextExercise(
        remaining: const [],
        targetDifficulty: 1,
        reinforcement: false,
      ),
      throwsStateError,
    );
  });
}
