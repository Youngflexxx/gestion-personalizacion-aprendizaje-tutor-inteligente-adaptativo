/// Métricas de gamificación de un estudiante (`gamificacion_usuario`).
class GamificacionUsuario {
  const GamificacionUsuario({
    required this.usuarioId,
    required this.xpTotal,
    required this.nivelActual,
    required this.rachaDiasActual,
    required this.mejorRachaDias,
    required this.ultimaFechaPractica,
  });

  final int usuarioId;
  final int xpTotal;
  final int nivelActual;
  final int rachaDiasActual;
  final int mejorRachaDias;
  final DateTime? ultimaFechaPractica;

  GamificacionUsuario copyWith({
    int? xpTotal,
    int? nivelActual,
    int? rachaDiasActual,
    int? mejorRachaDias,
    DateTime? ultimaFechaPractica,
  }) {
    return GamificacionUsuario(
      usuarioId: usuarioId,
      xpTotal: xpTotal ?? this.xpTotal,
      nivelActual: nivelActual ?? this.nivelActual,
      rachaDiasActual: rachaDiasActual ?? this.rachaDiasActual,
      mejorRachaDias: mejorRachaDias ?? this.mejorRachaDias,
      ultimaFechaPractica: ultimaFechaPractica ?? this.ultimaFechaPractica,
    );
  }

  factory GamificacionUsuario.fromJson(Map<String, dynamic> json) {
    final fecha = json['ultima_fecha_practica'] as String?;
    return GamificacionUsuario(
      usuarioId: (json['usuario_id'] as num).toInt(),
      xpTotal: (json['xp_total'] as num).toInt(),
      nivelActual: (json['nivel_actual'] as num).toInt(),
      rachaDiasActual: (json['racha_dias_actual'] as num).toInt(),
      mejorRachaDias: (json['mejor_racha_dias'] as num).toInt(),
      ultimaFechaPractica: fecha == null ? null : DateTime.parse(fecha),
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'xp_total': xpTotal,
        'nivel_actual': nivelActual,
        'racha_dias_actual': rachaDiasActual,
        'mejor_racha_dias': mejorRachaDias,
        'ultima_fecha_practica':
            ultimaFechaPractica?.toIso8601String().split('T').first,
      };
}
