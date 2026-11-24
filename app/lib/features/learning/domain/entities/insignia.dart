/// Insignia o logro (`insignias`).
class Insignia {
  const Insignia({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.icono,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String? icono;

  factory Insignia.fromJson(Map<String, dynamic> json) {
    return Insignia(
      id: (json['id'] as num).toInt(),
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      icono: json['icono'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'icono': icono,
      };
}
