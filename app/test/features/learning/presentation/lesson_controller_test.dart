import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/features/learning/data/repositories/in_memory_learning_repository.dart';
import 'package:tutor_adaptativo_sabd/features/learning/domain/entities/ejercicio.dart';
import 'package:tutor_adaptativo_sabd/features/learning/presentation/controllers/lesson_controller.dart';

void main() {
  test('una respuesta correcta sube el dominio y registra el intento',
      () async {
    final repo = InMemoryLearningRepository(
      clock: () => DateTime(2026, 11, 23, 10),
    );
    final estudiantes = await repo.obtenerEstudiantes();
    final leccion = (await repo.obtenerLecciones(1)).first;
    final usuarioId = estudiantes.first.id;

    final controller = LessonController(
      repository: repo,
      request: LessonRequest(
        usuarioId: usuarioId,
        moduloId: 1,
        leccionId: leccion.id,
      ),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, isNull);
    expect(controller.state.totalEjercicios, 5);

    final ejercicio = controller.state.ejercicioActual;
    if (ejercicio == null) {
      fail('La lección debería exponer un ejercicio inicial.');
    }
    final correcta = ejercicio.opciones.where((o) => o.esCorrecta).toList();
    expect(correcta, hasLength(1));

    final dominioAntes = controller.state.dominioActual;
    controller.seleccionarOpcion(correcta.single.id);
    await controller.comprobarRespuesta();

    expect(controller.state.respuestaVerificada, isTrue);
    expect(controller.state.esCorrecta, isTrue);
    expect(controller.state.dominioActual, greaterThan(dominioAntes));
    expect(controller.state.respondidos, 1);
    expect(controller.state.xpSesion, greaterThan(0));
  });

  test('una respuesta incorrecta descuenta una vida', () async {
    final repo = InMemoryLearningRepository(
      clock: () => DateTime(2026, 11, 23, 10),
    );
    final estudiantes = await repo.obtenerEstudiantes();
    final leccion = (await repo.obtenerLecciones(1)).first;

    final controller = LessonController(
      repository: repo,
      request: LessonRequest(
        usuarioId: estudiantes.first.id,
        moduloId: 1,
        leccionId: leccion.id,
      ),
    );
    addTearDown(controller.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    final ejercicio = controller.state.ejercicioActual;
    if (ejercicio == null) {
      fail('La lección debería exponer un ejercicio inicial.');
    }
    final incorrectas = ejercicio.opciones
        .where((OpcionEjercicio o) => !o.esCorrecta)
        .toList();
    controller.seleccionarOpcion(incorrectas.first.id);
    await controller.comprobarRespuesta();

    expect(controller.state.esCorrecta, isFalse);
    expect(controller.state.vidas, 2);
    expect(controller.state.erroresConsecutivos, 1);
  });
}
