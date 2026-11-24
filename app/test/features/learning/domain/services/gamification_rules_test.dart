import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/features/learning/domain/services/gamification_rules.dart';

void main() {
  group('xpForAttempt', () {
    test('un error no otorga XP', () {
      expect(
        GamificationRules.xpForAttempt(
          isCorrect: false,
          difficulty: 3,
          responseTimeMs: 1000,
          expectedTimeMs: 5000,
        ),
        0,
      );
    });

    test('acierto rápido incluye bonus por fluidez', () {
      expect(
        GamificationRules.xpForAttempt(
          isCorrect: true,
          difficulty: 2,
          responseTimeMs: 1000,
          expectedTimeMs: 5000,
        ),
        17,
      );
    });

    test('acierto lento no incluye bonus por fluidez', () {
      expect(
        GamificationRules.xpForAttempt(
          isCorrect: true,
          difficulty: 2,
          responseTimeMs: 6000,
          expectedTimeMs: 5000,
        ),
        14,
      );
    });
  });

  test('levelForXp sube cada 100 XP', () {
    expect(GamificationRules.levelForXp(0), 1);
    expect(GamificationRules.levelForXp(99), 1);
    expect(GamificationRules.levelForXp(100), 2);
    expect(GamificationRules.levelForXp(213), 3);
  });

  group('nextStreak', () {
    final hoy = DateTime(2026, 11, 23, 10);

    test('primera práctica inicia la racha en 1', () {
      expect(
        GamificationRules.nextStreak(
          currentStreak: 0,
          lastPractice: null,
          today: hoy,
        ),
        1,
      );
    });

    test('mismo día conserva la racha', () {
      expect(
        GamificationRules.nextStreak(
          currentStreak: 6,
          lastPractice: DateTime(2026, 11, 23, 8),
          today: hoy,
        ),
        6,
      );
    });

    test('día consecutivo suma uno', () {
      expect(
        GamificationRules.nextStreak(
          currentStreak: 6,
          lastPractice: DateTime(2026, 11, 22, 20),
          today: hoy,
        ),
        7,
      );
    });

    test('hueco mayor reinicia en 1', () {
      expect(
        GamificationRules.nextStreak(
          currentStreak: 6,
          lastPractice: DateTime(2026, 11, 20),
          today: hoy,
        ),
        1,
      );
    });
  });
}
