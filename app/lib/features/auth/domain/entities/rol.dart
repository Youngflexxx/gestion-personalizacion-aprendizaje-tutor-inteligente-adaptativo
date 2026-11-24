/// Catálogo de roles (`roles`).
class Rol {
  const Rol({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}
