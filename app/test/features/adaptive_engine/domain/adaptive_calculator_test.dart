import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/features/adaptive_engine/domain/adaptive_calculator.dart';

void main() {
  group('masteryDelta', () {
    test('acierto rápido suma 6 + d', () {
      final delta = AdaptiveCalculator.masteryDelta(
        isCorrect: true,
        difficulty: 1,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
      );
      expect(delta, 7);
    });

    test('acierto lento suma 3 + 0.5·d', () {
      final delta = AdaptiveCalculator.masteryDelta(
        isCorrect: true,
        difficulty: 3,
        responseTimeMs: 6000,
        expectedTimeMs: 5000,
      );
      expect(delta, closeTo(4.5, 1e-9));
    });

    test('error resta 8 - d', () {
      final delta = AdaptiveCalculator.masteryDelta(
        isCorrect: false,
        difficulty: 2,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
      );
      expect(delta, -6);
    });
  });

  group('difficultyForMastery', () {
    test('respeta los umbrales 25, 45, 65 y 85', () {
      expect(AdaptiveCalculator.difficultyForMastery(0), 1);
      expect(AdaptiveCalculator.difficultyForMastery(24.9), 1);
      expect(AdaptiveCalculator.difficultyForMastery(25), 2);
      expect(AdaptiveCalculator.difficultyForMastery(44.9), 2);
      expect(AdaptiveCalculator.difficultyForMastery(45), 3);
      expect(AdaptiveCalculator.difficultyForMastery(65), 4);
      expect(AdaptiveCalculator.difficultyForMastery(84.9), 4);
      expect(AdaptiveCalculator.difficultyForMastery(85), 5);
      expect(AdaptiveCalculator.difficultyForMastery(100), 5);
    });
  });

  group('clamp de dominio', () {
    test('nunca supera 100 tras un acierto rápido en dificultad 5', () {
      final decision = AdaptiveCalculator.evaluateAnswer(
        currentMastery: 98,
        isCorrect: true,
        difficulty: 5,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
        previousConsecutiveErrors: 0,
      );
      expect(decision.newMastery, 100);
    });

    test('nunca baja de 0 tras un error en dificultad 1', () {
      final decision = AdaptiveCalculator.evaluateAnswer(
        currentMastery: 2,
        isCorrect: false,
        difficulty: 1,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
        previousConsecutiveErrors: 0,
      );
      expect(decision.newMastery, 0);
    });
  });

  group('ajuste de dificultad', () {
    test('la dificultad sube tras una racha de aciertos rápidos', () {
      var mastery = AdaptiveCalculator.initialMastery;
      var difficulty = AdaptiveCalculator.difficultyForMastery(mastery);
      final targets = <int>[];

      for (var i = 0; i < 4; i++) {
        final decision = AdaptiveCalculator.evaluateAnswer(
          currentMastery: mastery,
          isCorrect: true,
          difficulty: difficulty,
          responseTimeMs: 1000,
          expectedTimeMs: 5000,
          previousConsecutiveErrors: 0,
        );
        mastery = decision.newMastery;
        difficulty = decision.targetDifficulty;
        targets.add(difficulty);
      }

      expect(targets.first, 2);
      expect(targets.last, greaterThan(targets.first));
      expect(targets, orderedEquals([...targets]..sort()));
    });

    test('la dificultad baja tras dos errores consecutivos con refuerzo', () {
      final primero = AdaptiveCalculator.evaluateAnswer(
        currentMastery: 50,
        isCorrect: false,
        difficulty: 3,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
        previousConsecutiveErrors: 0,
      );
      expect(primero.needsReinforcement, isFalse);
      expect(primero.newConsecutiveErrors, 1);

      final segundo = AdaptiveCalculator.evaluateAnswer(
        currentMastery: primero.newMastery,
        isCorrect: false,
        difficulty: 3,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
        previousConsecutiveErrors: primero.newConsecutiveErrors,
      );
      expect(segundo.needsReinforcement, isTrue);
      expect(segundo.newConsecutiveErrors, 2);
      expect(segundo.targetDifficulty, lessThan(primero.targetDifficulty));
      expect(segundo.targetDifficulty, 1);
    });

    test('un acierto resetea el contador de errores consecutivos', () {
      final decision = AdaptiveCalculator.evaluateAnswer(
        currentMastery: 40,
        isCorrect: true,
        difficulty: 2,
        responseTimeMs: 1000,
        expectedTimeMs: 5000,
        previousConsecutiveErrors: 2,
      );
      expect(decision.newConsecutiveErrors, 0);
      expect(decision.needsReinforcement, isFalse);
    });
  });
}
