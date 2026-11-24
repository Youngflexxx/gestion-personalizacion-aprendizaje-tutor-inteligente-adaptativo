/// Estado del módulo para un estudiante (`progreso_modulo_usuario.estado`).
enum EstadoProgreso {
  bloqueado('BLOQUEADO', 'Bloqueado'),
  enProgreso('EN_PROGRESO', 'En progreso'),
  dominado('DOMINADO', 'Dominado');

  const EstadoProgreso(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static EstadoProgreso fromDbValue(String value) {
    for (final estado in values) {
      if (estado.dbValue == value) return estado;
    }
    throw ArgumentError.value(value, 'value', 'Estado de progreso no válido');
  }
}

/// Estado adaptativo actual de un estudiante en un módulo.
class ProgresoModulo {
  const ProgresoModulo({
    required this.usuarioId,
    required this.moduloId,
    required this.nivelDominio,
    required this.dificultadActual,
    required this.rachaErroresConsecutivos,
    required this.estado,
    required this.actualizadoEn,
  });

  final int usuarioId;
  final int moduloId;
  final double nivelDominio;
  final int dificultadActual;
  final int rachaErroresConsecutivos;
  final EstadoProgreso estado;
  final DateTime actualizadoEn;

  ProgresoModulo copyWith({
    double? nivelDominio,
    int? dificultadActual,
    int? rachaErroresConsecutivos,
    EstadoProgreso? estado,
    DateTime? actualizadoEn,
  }) {
    return ProgresoModulo(
      usuarioId: usuarioId,
      moduloId: moduloId,
      nivelDominio: nivelDominio ?? this.nivelDominio,
      dificultadActual: dificultadActual ?? this.dificultadActual,
      rachaErroresConsecutivos:
          rachaErroresConsecutivos ?? this.rachaErroresConsecutivos,
      estado: estado ?? this.estado,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  factory ProgresoModulo.fromJson(Map<String, dynamic> json) {
    return ProgresoModulo(
      usuarioId: (json['usuario_id'] as num).toInt(),
      moduloId: (json['modulo_id'] as num).toInt(),
      nivelDominio: (json['nivel_dominio'] as num).toDouble(),
      dificultadActual: (json['dificultad_actual'] as num).toInt(),
      rachaErroresConsecutivos:
          (json['racha_errores_consecutivos'] as num).toInt(),
      estado: EstadoProgreso.fromDbValue(json['estado'] as String),
      actualizadoEn: DateTime.parse(json['actualizado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'modulo_id': moduloId,
        'nivel_dominio': nivelDominio,
        'dificultad_actual': dificultadActual,
        'racha_errores_consecutivos': rachaErroresConsecutivos,
        'estado': estado.dbValue,
        'actualizado_en': actualizadoEn.toIso8601String(),
      };
}
