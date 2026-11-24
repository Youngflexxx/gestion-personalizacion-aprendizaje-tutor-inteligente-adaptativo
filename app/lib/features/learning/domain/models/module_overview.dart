import '../entities/gamificacion_usuario.dart';
import '../entities/modulo.dart';
import '../entities/progreso_modulo.dart';
import 'leccion_estado.dart';

/// Vista agregada del módulo para la pantalla de ruta de aprendizaje.
class ModuleOverview {
  const ModuleOverview({
    required this.modulo,
    required this.lecciones,
    required this.progreso,
    required this.gamificacion,
  });

  final Modulo modulo;
  final List<LeccionEstado> lecciones;
  final ProgresoModulo progreso;
  final GamificacionUsuario gamificacion;

  int get totalLecciones => lecciones.length;

  int get completadas => lecciones
      .where((leccion) => leccion.estado == EstadoLeccion.completada)
      .length;

  double get porcentajeCompletado {
    if (totalLecciones == 0) return 0;
    return completadas / totalLecciones;
  }
}
