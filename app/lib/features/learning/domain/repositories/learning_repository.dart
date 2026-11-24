import '../../../auth/domain/entities/usuario.dart';
import '../entities/ejercicio.dart';
import '../entities/gamificacion_usuario.dart';
import '../entities/intento_ejercicio.dart';
import '../entities/leccion.dart';
import '../entities/modulo.dart';
import '../entities/progreso_modulo.dart';
import '../models/module_overview.dart';
import '../models/registro_intento_resultado.dart';
import '../models/resumen_leccion.dart';

/// Contrato de acceso a datos de aprendizaje.
///
/// La app depende de esta interfaz, no de una implementación concreta. Hoy se
/// usa `InMemoryLearningRepository` (datos de `03_seed.sql`); mañana se puede
/// inyectar un repositorio REST/Supabase sin tocar la UI ni el dominio.
abstract interface class LearningRepository {
  Future<List<Usuario>> obtenerEstudiantes();

  Future<Usuario> obtenerUsuario(int usuarioId);

  Future<GamificacionUsuario> obtenerGamificacion(int usuarioId);

  Future<ProgresoModulo> obtenerProgreso(int usuarioId, int moduloId);

  Future<Modulo> obtenerModulo(int moduloId);

  Future<List<Leccion>> obtenerLecciones(int moduloId);

  Future<Leccion> obtenerLeccion(int leccionId);

  Future<List<Ejercicio>> obtenerEjercicios(int leccionId);

  Future<Set<int>> obtenerLeccionesCompletadas(int usuarioId, int moduloId);

  Future<List<IntentoEjercicio>> obtenerIntentos(int usuarioId, {int? moduloId});

  Future<ModuleOverview> obtenerResumenModulo(int usuarioId, int moduloId);

  /// Registra el intento y actualiza atómicamente el progreso adaptativo y la
  /// gamificación (equivalente a la transacción ACID del esquema PostgreSQL).
  Future<RegistroIntentoResultado> registrarIntento({
    required int usuarioId,
    required int moduloId,
    required Ejercicio ejercicio,
    required bool esCorrecto,
    required int tiempoRespuestaMs,
    required double nuevoDominio,
    required int nuevaDificultad,
    required int rachaErroresConsecutivos,
    required int xpGanado,
  });

  /// Cierra la sesión, otorga el bonus de lección (una sola vez) e insignias.
  Future<ResumenLeccion> finalizarLeccion({
    required int usuarioId,
    required int moduloId,
    required Leccion leccion,
    required List<IntentoEjercicio> intentosSesion,
    required double dominioAntes,
    required int dificultadAntes,
    required int respuestasTotales,
    required int respuestasCorrectas,
    required int vidasRestantes,
  });
}
