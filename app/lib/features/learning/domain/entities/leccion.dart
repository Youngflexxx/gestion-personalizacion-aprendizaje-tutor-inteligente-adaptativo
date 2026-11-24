/// Micro-lección dentro de un módulo (`lecciones`).
class Leccion {
  const Leccion({
    required this.id,
    required this.moduloId,
    required this.titulo,
    required this.resumenTeorico,
    required this.orden,
    required this.xpRecompensa,
  });

  final int id;
  final int moduloId;
  final String titulo;
  final String? resumenTeorico;
  final int orden;
  final int xpRecompensa;

  factory Leccion.fromJson(Map<String, dynamic> json) {
    return Leccion(
      id: (json['id'] as num).toInt(),
      moduloId: (json['modulo_id'] as num).toInt(),
      titulo: json['titulo'] as String,
      resumenTeorico: json['resumen_teorico'] as String?,
      orden: (json['orden'] as num).toInt(),
      xpRecompensa: (json['xp_recompensa'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'modulo_id': moduloId,
        'titulo': titulo,
        'resumen_teorico': resumenTeorico,
        'orden': orden,
        'xp_recompensa': xpRecompensa,
      };
}
