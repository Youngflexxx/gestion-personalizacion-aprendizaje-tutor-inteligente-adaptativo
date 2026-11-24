/// Aula o sección (`aulas`).
class Aula {
  const Aula({
    required this.id,
    required this.docenteId,
    required this.nombre,
    required this.codigoAcceso,
    required this.periodoAcademico,
    required this.activa,
    required this.creadoEn,
  });

  final int id;
  final int docenteId;
  final String nombre;
  final String codigoAcceso;
  final String periodoAcademico;
  final bool activa;
  final DateTime creadoEn;

  factory Aula.fromJson(Map<String, dynamic> json) {
    return Aula(
      id: (json['id'] as num).toInt(),
      docenteId: (json['docente_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      codigoAcceso: json['codigo_acceso'] as String,
      periodoAcademico: json['periodo_academico'] as String,
      activa: json['activa'] as bool,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'docente_id': docenteId,
        'nombre': nombre,
        'codigo_acceso': codigoAcceso,
        'periodo_academico': periodoAcademico,
        'activa': activa,
        'creado_en': creadoEn.toIso8601String(),
      };
}
