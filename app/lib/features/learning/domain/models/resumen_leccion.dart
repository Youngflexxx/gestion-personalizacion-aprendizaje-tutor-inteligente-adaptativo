import '../entities/insignia.dart';
import '../entities/leccion.dart';

/// Fila compacta del historial mostrado en el resumen de la lección.
class ResumenIntento {
  const ResumenIntento({
    required this.enunciado,
    required this.esCorrecto,
    required this.tiempoRespuestaMs,
    required this.dificultadAlMomento,
  });

  final String enunciado;
  final bool esCorrecto;
  final int tiempoRespuestaMs;
  final int dificultadAlMomento;

  String get tiempoLabel =>
      '${(tiempoRespuestaMs / 1000).toStringAsFixed(1)} s';
}

/// Datos completos de la pantalla de resumen y del registro del intento.
class ResumenLeccion {
  const ResumenLeccion({
    required this.usuarioId,
    required this.moduloId,
    required this.leccion,
    required this.leccionCompletada,
    required this.xpSesion,
    required this.xpBonus,
    required this.respuestasTotales,
    required this.respuestasCorrectas,
    required this.dominioAntes,
    required this.dominioDespues,
    required this.dificultadAntes,
    required this.dificultadDespues,
    required this.vidasRestantes,
    required this.intentos,
    required this.nuevasInsignias,
  });

  final int usuarioId;
  final int moduloId;
  final Leccion leccion;
  final bool leccionCompletada;
  final int xpSesion;
  final int xpBonus;
  final int respuestasTotales;
  final int respuestasCorrectas;
  final double dominioAntes;
  final double dominioDespues;
  final int dificultadAntes;
  final int dificultadDespues;
  final int vidasRestantes;
  final List<ResumenIntento> intentos;
  final List<Insignia> nuevasInsignias;

  int get xpTotal => xpSesion + xpBonus;

  double get precision {
    if (respuestasTotales == 0) return 0;
    return respuestasCorrectas / respuestasTotales;
  }

  double get deltaDominio => dominioDespues - dominioAntes;
}
