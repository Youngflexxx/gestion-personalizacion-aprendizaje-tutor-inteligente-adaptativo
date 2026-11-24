/// Registro histórico de una respuesta (`intentos_ejercicio`).
class IntentoEjercicio {
  const IntentoEjercicio({
    required this.id,
    required this.usuarioId,
    required this.ejercicioId,
    required this.esCorrecto,
    required this.tiempoRespuestaMs,
    required this.dificultadAlMomento,
    required this.xpGanado,
    required this.fechaIntento,
  });

  final int id;
  final int usuarioId;
  final int ejercicioId;
  final bool esCorrecto;
  final int tiempoRespuestaMs;
  final int dificultadAlMomento;
  final int xpGanado;
  final DateTime fechaIntento;

  factory IntentoEjercicio.fromJson(Map<String, dynamic> json) {
    return IntentoEjercicio(
      id: (json['id'] as num).toInt(),
      usuarioId: (json['usuario_id'] as num).toInt(),
      ejercicioId: (json['ejercicio_id'] as num).toInt(),
      esCorrecto: json['es_correcto'] as bool,
      tiempoRespuestaMs: (json['tiempo_respuesta_ms'] as num).toInt(),
      dificultadAlMomento: (json['dificultad_al_momento'] as num).toInt(),
      xpGanado: (json['xp_ganado'] as num).toInt(),
      fechaIntento: DateTime.parse(json['fecha_intento'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': usuarioId,
        'ejercicio_id': ejercicioId,
        'es_correcto': esCorrecto,
        'tiempo_respuesta_ms': tiempoRespuestaMs,
        'dificultad_al_momento': dificultadAlMomento,
        'xp_ganado': xpGanado,
        'fecha_intento': fechaIntento.toIso8601String(),
      };
}
