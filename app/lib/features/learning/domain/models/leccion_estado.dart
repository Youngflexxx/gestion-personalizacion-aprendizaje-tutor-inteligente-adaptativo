import '../../domain/entities/leccion.dart';

/// Estado visual de una lección en la ruta de aprendizaje.
enum EstadoLeccion { bloqueada, disponible, completada }

/// Lección + su estado derivado del historial de intentos.
class LeccionEstado {
  const LeccionEstado({
    required this.leccion,
    required this.estado,
    required this.ejerciciosTotales,
    required this.ejerciciosCorrectos,
  });

  final Leccion leccion;
  final EstadoLeccion estado;
  final int ejerciciosTotales;
  final int ejerciciosCorrectos;

  bool get puedeAbrir => estado != EstadoLeccion.bloqueada;

  double get progreso {
    if (ejerciciosTotales == 0) return 0;
    return ejerciciosCorrectos / ejerciciosTotales;
  }
}
