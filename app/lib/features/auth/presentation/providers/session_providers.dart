import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID del estudiante seleccionado en el selector de perfiles.
///
/// `null` significa que no hay sesión activa y el router redirige a `/`.
final selectedStudentIdProvider = StateProvider<int?>((ref) => null);
