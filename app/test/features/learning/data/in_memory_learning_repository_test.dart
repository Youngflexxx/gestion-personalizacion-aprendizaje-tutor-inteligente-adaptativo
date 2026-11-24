import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/features/auth/domain/entities/usuario.dart';
import 'package:tutor_adaptativo_sabd/features/learning/data/repositories/in_memory_learning_repository.dart';

void main() {
  InMemoryLearningRepository crearRepositorio() {
    return InMemoryLearningRepository(clock: () => DateTime(2026, 11, 23, 10));
  }

  test('el seed contiene dos estudiantes y 5 módulos de SABD', () async {
    final repo = crearRepositorio();
    final estudiantes = await repo.obtenerEstudiantes();
    expect(estudiantes, hasLength(2));
    final modulo = await repo.obtenerModulo(1);
    expect(modulo.titulo, isNotEmpty);
    final lecciones = await repo.obtenerLecciones(1);
    expect(lecciones, hasLength(3));
  });

  test('el estudiante con progreso tiene las lecciones 1 y 2 completadas',
      () async {
    final repo = crearRepositorio();
    final estudiantes = await repo.obtenerEstudiantes();
    final conProgreso = await _estudianteConProgreso(repo, estudiantes);

    final completadas = await repo.obtenerLeccionesCompletadas(
      conProgreso.id,
      1,
    );
    expect(completadas, containsAll(<int>[1, 2]));
    expect(completadas, isNot(contains(3)));
  });

  test('registrar intentos correctos completa la lección y otorga el bonus',
      () async {
    final repo = crearRepositorio();
    final estudiantes = await repo.obtenerEstudiantes();
    final nuevo = await _estudianteSinProgreso(repo, estudiantes);
    final leccion = (await repo.obtenerLecciones(1)).first;
    final ejercicios = await repo.obtenerEjercicios(leccion.id);

    for (final ejercicio in ejercicios) {
      await repo.registrarIntento(
        usuarioId: nuevo.id,
        moduloId: 1,
        ejercicio: ejercicio,
        esCorrecto: true,
        tiempoRespuestaMs: 1000,
        nuevoDominio: 30,
        nuevaDificultad: 2,
        rachaErroresConsecutivos: 0,
        xpGanado: 10,
      );
    }

    final resumen = await repo.finalizarLeccion(
      usuarioId: nuevo.id,
      moduloId: 1,
      leccion: leccion,
      intentosSesion: const [],
      dominioAntes: 20,
      dificultadAntes: 1,
      respuestasTotales: ejercicios.length,
      respuestasCorrectas: ejercicios.length,
      vidasRestantes: 3,
    );

    expect(resumen.leccionCompletada, isTrue);
    expect(resumen.xpBonus, leccion.xpRecompensa);
    expect(resumen.dominioDespues, 30);
  });
}

Future<Usuario> _estudianteConProgreso(
  InMemoryLearningRepository repo,
  List<Usuario> estudiantes,
) async {
  for (final estudiante in estudiantes) {
    final completadas = await repo.obtenerLeccionesCompletadas(
      estudiante.id,
      1,
    );
    if (completadas.isNotEmpty) return estudiante;
  }
  throw StateError('Sin estudiante con progreso en el seed.');
}

Future<Usuario> _estudianteSinProgreso(
  InMemoryLearningRepository repo,
  List<Usuario> estudiantes,
) async {
  for (final estudiante in estudiantes) {
    final completadas = await repo.obtenerLeccionesCompletadas(
      estudiante.id,
      1,
    );
    if (completadas.isEmpty) return estudiante;
  }
  throw StateError('Sin estudiante nuevo en el seed.');
}
