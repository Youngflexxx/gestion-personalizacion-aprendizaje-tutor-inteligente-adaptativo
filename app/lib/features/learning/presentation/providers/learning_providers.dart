import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/usuario.dart';
import '../../../auth/presentation/providers/session_providers.dart';
import '../../data/repositories/in_memory_learning_repository.dart';
import '../../domain/entities/gamificacion_usuario.dart';
import '../../domain/entities/progreso_modulo.dart';
import '../../domain/models/module_overview.dart';
import '../../domain/repositories/learning_repository.dart';
import '../controllers/lesson_controller.dart';

/// Punto único de inyección del repositorio.
///
/// Para conectar la API/PostgreSQL se reemplaza esta implementación (o se
/// sobreescribe el provider en `main.dart`/tests) sin tocar la UI.
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return InMemoryLearningRepository();
});

/// Estudiantes del aula semilla.
final studentsProvider = FutureProvider<List<Usuario>>((ref) {
  return ref.watch(learningRepositoryProvider).obtenerEstudiantes();
});

/// Estudiante actualmente seleccionado.
final currentStudentProvider = FutureProvider<Usuario?>((ref) {
  final id = ref.watch(selectedStudentIdProvider);
  if (id == null) return Future<Usuario?>.value(null);
  return ref.watch(learningRepositoryProvider).obtenerUsuario(id);
});

/// Gamificación de un estudiante.
final studentGamificationProvider =
    FutureProvider.family<GamificacionUsuario, int>((ref, usuarioId) {
  return ref.watch(learningRepositoryProvider).obtenerGamificacion(usuarioId);
});

/// Progreso adaptativo de un estudiante en un módulo.
final studentProgressProvider = FutureProvider.family<ProgresoModulo,
    ({int usuarioId, int moduloId})>((ref, args) {
  return ref.watch(learningRepositoryProvider).obtenerProgreso(
        args.usuarioId,
        args.moduloId,
      );
});

/// Vista agregada del módulo para la ruta de aprendizaje.
final moduleOverviewProvider =
    FutureProvider.family<ModuleOverview, int>((ref, moduloId) {
  final usuarioId = ref.watch(selectedStudentIdProvider);
  if (usuarioId == null) {
    throw StateError('Selecciona un estudiante para abrir el módulo.');
  }
  return ref
      .watch(learningRepositoryProvider)
      .obtenerResumenModulo(usuarioId, moduloId);
});

/// Controlador de la sesión de lección (se destruye al salir de la pantalla).
final lessonControllerProvider = StateNotifierProvider.autoDispose
    .family<LessonController, LessonState, LessonRequest>((ref, request) {
  final repository = ref.watch(learningRepositoryProvider);
  return LessonController(
    repository: repository,
    request: request,
    onDataChanged: () {
      ref.invalidate(moduleOverviewProvider(request.moduloId));
      ref.invalidate(studentGamificationProvider(request.usuarioId));
      ref.invalidate(
        studentProgressProvider(
          (usuarioId: request.usuarioId, moduloId: request.moduloId),
        ),
      );
    },
  );
});
