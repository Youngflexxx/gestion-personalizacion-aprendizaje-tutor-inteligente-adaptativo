/// Módulo temático de la ruta de aprendizaje (`modulos`).
class Modulo {
  const Modulo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.orden,
    required this.icono,
    required this.activo,
  });

  final int id;
  final String titulo;
  final String descripcion;
  final int orden;
  final String? icono;
  final bool activo;

  factory Modulo.fromJson(Map<String, dynamic> json) {
    return Modulo(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      orden: (json['orden'] as num).toInt(),
      icono: json['icono'] as String?,
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'orden': orden,
        'icono': icono,
        'activo': activo,
      };
}
