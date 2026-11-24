import '../entities/gamificacion_usuario.dart';
import '../entities/intento_ejercicio.dart';
import '../entities/progreso_modulo.dart';

/// Resultado atómico de registrar una respuesta:
/// intento + progreso adaptativo + gamificación actualizados.
class RegistroIntentoResultado {
  const RegistroIntentoResultado({
    required this.intento,
    required this.progreso,
    required this.gamificacion,
  });

  final IntentoEjercicio intento;
  final ProgresoModulo progreso;
  final GamificacionUsuario gamificacion;

  int get xpGanado => intento.xpGanado;
}
