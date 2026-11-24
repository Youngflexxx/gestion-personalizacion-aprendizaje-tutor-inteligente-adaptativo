/// Origen de datos activo de la aplicación.
enum DataSourceMode {
  /// Datos precargados en memoria con el mismo contenido de `03_seed.sql`.
  inMemory,

  /// API REST / Supabase conectada a PostgreSQL (siguiente iteración).
  remoteApi,
}

/// Configuración de entorno de la aplicación.
///
/// No contiene credenciales. La URL de la API se inyectará aquí (o mediante
/// `--dart-define`) cuando se habilite [DataSourceMode.remoteApi].
abstract final class AppConfig {
  /// Cambiar a [DataSourceMode.remoteApi] para conectar la API real.
  static const DataSourceMode dataSourceMode = DataSourceMode.inMemory;

  static const String? apiBaseUrl = null;

  /// Módulo curricular demostrado en este vertical slice.
  static const int primerModuloId = 1;

  /// Vidas por sesión de lección (mecánica estilo Duolingo).
  static const int vidasPorLeccion = 3;
}
