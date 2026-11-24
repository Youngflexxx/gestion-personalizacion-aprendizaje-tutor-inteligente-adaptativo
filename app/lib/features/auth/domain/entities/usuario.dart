/// Usuario del sistema (`usuarios`).
///
/// `password_hash` no forma parte del modelo de dominio del cliente: solo vive
/// en el servidor y nunca se expone a la aplicación Flutter.
class Usuario {
  const Usuario({
    required this.id,
    required this.rolId,
    required this.nombreCompleto,
    required this.correo,
    required this.activo,
    required this.creadoEn,
  });

  final int id;
  final int rolId;
  final String nombreCompleto;
  final String correo;
  final bool activo;
  final DateTime creadoEn;

  String get iniciales {
    final partes = nombreCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num).toInt(),
      rolId: (json['rol_id'] as num).toInt(),
      nombreCompleto: json['nombre_completo'] as String,
      correo: json['correo'] as String,
      activo: json['activo'] as bool,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rol_id': rolId,
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'activo': activo,
        'creado_en': creadoEn.toIso8601String(),
      };
}
