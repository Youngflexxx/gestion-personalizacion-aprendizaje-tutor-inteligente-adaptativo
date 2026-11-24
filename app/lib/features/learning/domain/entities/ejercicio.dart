/// Tipos de ejercicio soportados por el modelo (`ejercicios.tipo_ejercicio`).
enum TipoEjercicio {
  multipleChoice('MULTIPLE_CHOICE', 'Opción múltiple'),
  trueFalse('TRUE_FALSE', 'Verdadero / falso'),
  fillSql('FILL_SQL', 'Completar SQL'),
  orderQuery('ORDER_QUERY', 'Ordenar consulta');

  const TipoEjercicio(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static TipoEjercicio fromDbValue(String value) {
    for (final tipo in values) {
      if (tipo.dbValue == value) return tipo;
    }
    throw ArgumentError.value(value, 'value', 'Tipo de ejercicio no soportado');
  }
}

/// Opción de un ejercicio (`opciones_ejercicio`).
class OpcionEjercicio {
  const OpcionEjercicio({
    required this.id,
    required this.ejercicioId,
    required this.textoOpcion,
    required this.esCorrecta,
    required this.ordenCorrecto,
  });

  final int id;
  final int ejercicioId;
  final String textoOpcion;
  final bool esCorrecta;
  final int? ordenCorrecto;

  factory OpcionEjercicio.fromJson(Map<String, dynamic> json) {
    return OpcionEjercicio(
      id: (json['id'] as num).toInt(),
      ejercicioId: (json['ejercicio_id'] as num).toInt(),
      textoOpcion: json['texto_opcion'] as String,
      esCorrecta: json['es_correcta'] as bool,
      ordenCorrecto: (json['orden_correcto'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ejercicio_id': ejercicioId,
        'texto_opcion': textoOpcion,
        'es_correcta': esCorrecta,
        'orden_correcto': ordenCorrecto,
      };
}

/// Ejercicio del banco de preguntas (`ejercicios`).
class Ejercicio {
  const Ejercicio({
    required this.id,
    required this.leccionId,
    required this.tipo,
    required this.nivelDificultad,
    required this.enunciado,
    required this.fragmentoCodigo,
    required this.tiempoEstimadoSeg,
    required this.explicacionPedagogica,
    required this.activo,
    this.opciones = const <OpcionEjercicio>[],
  });

  final int id;
  final int leccionId;
  final TipoEjercicio tipo;
  final int nivelDificultad;
  final String enunciado;
  final String? fragmentoCodigo;
  final int tiempoEstimadoSeg;
  final String explicacionPedagogica;
  final bool activo;
  final List<OpcionEjercicio> opciones;

  int get tiempoEstimadoMs => tiempoEstimadoSeg * 1000;

  OpcionEjercicio? get opcionCorrecta {
    for (final opcion in opciones) {
      if (opcion.esCorrecta) return opcion;
    }
    return null;
  }

  Ejercicio copyWith({List<OpcionEjercicio>? opciones}) {
    return Ejercicio(
      id: id,
      leccionId: leccionId,
      tipo: tipo,
      nivelDificultad: nivelDificultad,
      enunciado: enunciado,
      fragmentoCodigo: fragmentoCodigo,
      tiempoEstimadoSeg: tiempoEstimadoSeg,
      explicacionPedagogica: explicacionPedagogica,
      activo: activo,
      opciones: opciones ?? this.opciones,
    );
  }

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    final opcionesJson = json['opciones'] as List<dynamic>? ?? const [];
    return Ejercicio(
      id: (json['id'] as num).toInt(),
      leccionId: (json['leccion_id'] as num).toInt(),
      tipo: TipoEjercicio.fromDbValue(json['tipo_ejercicio'] as String),
      nivelDificultad: (json['nivel_dificultad'] as num).toInt(),
      enunciado: json['enunciado'] as String,
      fragmentoCodigo: json['fragmento_codigo'] as String?,
      tiempoEstimadoSeg: (json['tiempo_estimado_seg'] as num).toInt(),
      explicacionPedagogica: json['explicacion_pedagogica'] as String,
      activo: json['activo'] as bool,
      opciones: opcionesJson
          .map(
            (opcion) => OpcionEjercicio.fromJson(
              Map<String, dynamic>.from(opcion as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leccion_id': leccionId,
        'tipo_ejercicio': tipo.dbValue,
        'nivel_dificultad': nivelDificultad,
        'enunciado': enunciado,
        'fragmento_codigo': fragmentoCodigo,
        'tiempo_estimado_seg': tiempoEstimadoSeg,
        'explicacion_pedagogica': explicacionPedagogica,
        'activo': activo,
        'opciones': opciones.map((opcion) => opcion.toJson()).toList(),
      };
}
