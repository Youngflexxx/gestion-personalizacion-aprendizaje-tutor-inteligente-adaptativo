import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/session_providers.dart';
import '../../features/auth/presentation/screens/profile_selector_screen.dart';
import '../../features/learning/domain/models/resumen_leccion.dart';
import '../../features/learning/presentation/screens/learning_path_screen.dart';
import '../../features/learning/presentation/screens/lesson_runner_screen.dart';
import '../../features/learning/presentation/screens/lesson_summary_screen.dart';
import '../config/app_config.dart';
import 'route_error_screen.dart';

/// Router declarativo con guarda de sesión.
///
/// * Sin estudiante seleccionado solo se puede estar en `/`.
/// * Con estudiante seleccionado, `/` redirige al módulo 1.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<int?>(ref.read(selectedStudentIdProvider));

  ref.listen<int?>(selectedStudentIdProvider, (previous, next) {
    session.value = next;
  });

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final studentId = ref.read(selectedStudentIdProvider);
      final atProfileSelector = state.matchedLocation == '/';

      if (studentId == null && !atProfileSelector) {
        return '/';
      }
      if (studentId != null && atProfileSelector) {
        return '/module/${AppConfig.primerModuloId}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'profiles',
        builder: (context, state) => const ProfileSelectorScreen(),
      ),
      GoRoute(
        path: '/module/:moduleId',
        name: 'module',
        builder: (context, state) {
          final moduleId = int.tryParse(
            state.pathParameters['moduleId'] ?? '',
          );
          if (moduleId == null) {
            return const RouteErrorScreen(
              message: 'El identificador del módulo no es válido.',
            );
          }
          return LearningPathScreen(moduloId: moduleId);
        },
        routes: [
          GoRoute(
            path: 'lesson/:lessonId',
            name: 'lesson',
            builder: (context, state) {
              final moduloId = int.tryParse(
                state.pathParameters['moduleId'] ?? '',
              );
              final leccionId = int.tryParse(
                state.pathParameters['lessonId'] ?? '',
              );
              final usuarioId = ref.read(selectedStudentIdProvider);

              if (moduloId == null ||
                  leccionId == null ||
                  usuarioId == null) {
                return const RouteErrorScreen(
                  message:
                      'No pudimos abrir la lección. Vuelve a la ruta e '
                      'inténtalo de nuevo.',
                );
              }

              return LessonRunnerScreen(
                usuarioId: usuarioId,
                moduloId: moduloId,
                leccionId: leccionId,
              );
            },
          ),
          GoRoute(
            path: 'summary',
            name: 'summary',
            builder: (context, state) {
              final moduloId = int.tryParse(
                    state.pathParameters['moduleId'] ?? '',
                  ) ??
                  AppConfig.primerModuloId;
              final extra = state.extra;
              final resumen = extra is ResumenLeccion ? extra : null;
              return LessonSummaryScreen(
                moduloId: moduloId,
                resumen: resumen,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return RouteErrorScreen(
        message: state.error?.toString() ?? 'La ruta solicitada no existe.',
      );
    },
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });

  return router;
});
