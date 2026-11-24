import '../../../auth/domain/entities/aula.dart';
import '../../../auth/domain/entities/rol.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../domain/entities/ejercicio.dart';
import '../../domain/entities/gamificacion_usuario.dart';
import '../../domain/entities/insignia.dart';
import '../../domain/entities/intento_ejercicio.dart';
import '../../domain/entities/leccion.dart';
import '../../domain/entities/modulo.dart';
import '../../domain/entities/progreso_modulo.dart';

class _OpcionSeed {
  const _OpcionSeed(this.texto, this.esCorrecta);

  final String texto;
  final bool esCorrecta;
}

class _EjercicioSeed {
  const _EjercicioSeed({
    required this.leccionId,
    required this.tipo,
    required this.dificultad,
    required this.enunciado,
    required this.tiempo,
    required this.explicacion,
    required this.opciones,
    this.fragmento,
  });

  final int leccionId;
  final TipoEjercicio tipo;
  final int dificultad;
  final String enunciado;
  final String? fragmento;
  final int tiempo;
  final String explicacion;
  final List<_OpcionSeed> opciones;
}

/// Dataset semilla en memoria.
///
/// Es un espejo fiel de `database/03_seed.sql`: mismos IDs, mismos textos y
/// misma actividad previa. Permite probar la app sin levantar PostgreSQL.
class SeedDatabase {
  SeedDatabase._({
    required this.roles,
    required this.usuarios,
    required this.aulas,
    required this.aulaEstudiantes,
    required this.modulos,
    required this.lecciones,
    required this.ejercicios,
    required this.insignias,
    required this.gamificacion,
    required this.progreso,
    required this.intentos,
    required this.usuarioInsignias,
  });

  factory SeedDatabase.create({DateTime? now}) {
    final reference = now ?? DateTime.now();
    final day6 = reference.subtract(const Duration(days: 6));
    final day3 = reference.subtract(const Duration(days: 3));

    final roles = <Rol>[
      const Rol(id: 1, nombre: 'ESTUDIANTE'),
      const Rol(id: 2, nombre: 'DOCENTE'),
      const Rol(id: 3, nombre: 'ADMIN'),
    ];

    final usuarios = <Usuario>[
      Usuario(
        id: 1,
        rolId: 2,
        nombreCompleto: 'Prof. Docente Demo',
        correo: 'docente.demo@sabd.edu.ve',
        activo: true,
        creadoEn: reference.subtract(const Duration(days: 90)),
      ),
      Usuario(
        id: 2,
        rolId: 1,
        nombreCompleto: 'María González',
        correo: 'maria.gonzalez@sabd.edu.ve',
        activo: true,
        creadoEn: reference.subtract(const Duration(days: 60)),
      ),
      Usuario(
        id: 3,
        rolId: 1,
        nombreCompleto: 'Carlos Pérez',
        correo: 'carlos.perez@sabd.edu.ve',
        activo: true,
        creadoEn: reference.subtract(const Duration(days: 60)),
      ),
    ];

    final aulas = <Aula>[
      Aula(
        id: 1,
        docenteId: 1,
        nombre: 'SABD Sección D2',
        codigoAcceso: 'SABD-2026-D2',
        periodoAcademico: '2026-II',
        activa: true,
        creadoEn: reference.subtract(const Duration(days: 30)),
      ),
    ];

    final aulaEstudiantes = <({int aulaId, int estudianteId, DateTime fecha})>[
      (
        aulaId: 1,
        estudianteId: 2,
        fecha: reference.subtract(const Duration(days: 28)),
      ),
      (
        aulaId: 1,
        estudianteId: 3,
        fecha: reference.subtract(const Duration(days: 28)),
      ),
    ];

    final modulos = <Modulo>[
      const Modulo(
        id: 1,
        titulo: 'Fundamentos de BD y SGBD',
        descripcion:
            'Datos vs. información, arquitectura de un SGBD y modelos de '
            'bases de datos.',
        orden: 1,
        icono: 'storage',
        activo: true,
      ),
      const Modulo(
        id: 2,
        titulo: 'Modelo Entidad-Relación (E-R)',
        descripcion:
            'Entidades, atributos, claves y cardinalidades del modelo '
            'conceptual.',
        orden: 2,
        icono: 'account_tree',
        activo: true,
      ),
      const Modulo(
        id: 3,
        titulo: 'Normalización Relacional',
        descripcion:
            'Primera, segunda y tercera forma normal para eliminar '
            'redundancias.',
        orden: 3,
        icono: 'schema',
        activo: true,
      ),
      const Modulo(
        id: 4,
        titulo: 'SQL Esencial (DDL y DML)',
        descripcion:
            'CREATE TABLE, INSERT, UPDATE, DELETE y consultas SELECT con '
            'WHERE.',
        orden: 4,
        icono: 'code',
        activo: true,
      ),
      const Modulo(
        id: 5,
        titulo: 'Consultas Avanzadas e Integridad',
        descripcion: 'JOIN, GROUP BY, HAVING, transacciones ACID e índices.',
        orden: 5,
        icono: 'insights',
        activo: true,
      ),
    ];

    final lecciones = <Leccion>[
      const Leccion(
        id: 1,
        moduloId: 1,
        titulo: 'Datos, información y bases de datos',
        resumenTeorico:
            'Un dato es un hecho sin contexto; la información surge al '
            'procesarlo. Una base de datos organiza datos relacionados y un '
            'SGBD los administra con integridad.',
        orden: 1,
        xpRecompensa: 20,
      ),
      const Leccion(
        id: 2,
        moduloId: 1,
        titulo: 'Arquitectura y componentes de un SGBD',
        resumenTeorico:
            'El SGBD incluye gestor de almacenamiento, procesador de '
            'consultas, optimizador, gestor de transacciones y catálogo de '
            'metadatos. Su meta es garantizar ACID y acceso eficiente.',
        orden: 2,
        xpRecompensa: 25,
      ),
      const Leccion(
        id: 3,
        moduloId: 1,
        titulo: 'Modelos de bases de datos',
        resumenTeorico:
            'El modelo relacional usa tablas, filas y columnas. Existen '
            'también modelos jerárquicos, en red, orientados a documentos y a '
            'grafos, cada uno con ventajas según el dominio.',
        orden: 3,
        xpRecompensa: 30,
      ),
    ];

    final ejercicios = _buildEjercicios();

    final insignias = <Insignia>[
      const Insignia(
        id: 1,
        codigo: 'PRIMER_PASO',
        nombre: 'Primer paso',
        descripcion: 'Completa tu primera lección de SABD.',
        icono: 'flag',
      ),
      const Insignia(
        id: 2,
        codigo: 'RACHA_3',
        nombre: 'Constancia',
        descripcion: 'Mantén una racha de 3 días consecutivos.',
        icono: 'local_fire_department',
      ),
      const Insignia(
        id: 3,
        codigo: 'EXPLORADOR_BD',
        nombre: 'Explorador de BD',
        descripcion: 'Completa el Módulo 1: Fundamentos de BD y SGBD.',
        icono: 'explore',
      ),
      const Insignia(
        id: 4,
        codigo: 'MAESTRO_SQL',
        nombre: 'Maestro SQL',
        descripcion: 'Domina el módulo de SQL Esencial.',
        icono: 'code',
      ),
    ];

    final gamificacion = <GamificacionUsuario>[
      const GamificacionUsuario(
        usuarioId: 2,
        xpTotal: 0,
        nivelActual: 1,
        rachaDiasActual: 0,
        mejorRachaDias: 0,
        ultimaFechaPractica: null,
      ),
      GamificacionUsuario(
        usuarioId: 3,
        xpTotal: 213,
        nivelActual: 3,
        rachaDiasActual: 6,
        mejorRachaDias: 6,
        ultimaFechaPractica: reference.subtract(const Duration(days: 1)),
      ),
    ];

    final progreso = <ProgresoModulo>[
      ProgresoModulo(
        usuarioId: 2,
        moduloId: 1,
        nivelDominio: 20,
        dificultadActual: 1,
        rachaErroresConsecutivos: 0,
        estado: EstadoProgreso.enProgreso,
        actualizadoEn: reference.subtract(const Duration(days: 28)),
      ),
      ProgresoModulo(
        usuarioId: 3,
        moduloId: 1,
        nivelDominio: 70,
        dificultadActual: 4,
        rachaErroresConsecutivos: 0,
        estado: EstadoProgreso.enProgreso,
        actualizadoEn: day3,
      ),
    ];

    final intentos = <IntentoEjercicio>[
      IntentoEjercicio(
        id: 1,
        usuarioId: 3,
        ejercicioId: 1,
        esCorrecto: true,
        tiempoRespuestaMs: 20000,
        dificultadAlMomento: 1,
        xpGanado: 15,
        fechaIntento: day6,
      ),
      IntentoEjercicio(
        id: 2,
        usuarioId: 3,
        ejercicioId: 2,
        esCorrecto: true,
        tiempoRespuestaMs: 26000,
        dificultadAlMomento: 1,
        xpGanado: 12,
        fechaIntento: day6.add(const Duration(minutes: 1)),
      ),
      IntentoEjercicio(
        id: 3,
        usuarioId: 3,
        ejercicioId: 3,
        esCorrecto: false,
        tiempoRespuestaMs: 35000,
        dificultadAlMomento: 2,
        xpGanado: 0,
        fechaIntento: day6.add(const Duration(minutes: 2)),
      ),
      IntentoEjercicio(
        id: 4,
        usuarioId: 3,
        ejercicioId: 3,
        esCorrecto: true,
        tiempoRespuestaMs: 34000,
        dificultadAlMomento: 2,
        xpGanado: 14,
        fechaIntento: day6.add(const Duration(minutes: 3)),
      ),
      IntentoEjercicio(
        id: 5,
        usuarioId: 3,
        ejercicioId: 4,
        esCorrecto: true,
        tiempoRespuestaMs: 28000,
        dificultadAlMomento: 2,
        xpGanado: 17,
        fechaIntento: day6.add(const Duration(minutes: 4)),
      ),
      IntentoEjercicio(
        id: 6,
        usuarioId: 3,
        ejercicioId: 5,
        esCorrecto: false,
        tiempoRespuestaMs: 40000,
        dificultadAlMomento: 3,
        xpGanado: 0,
        fechaIntento: day6.add(const Duration(minutes: 5)),
      ),
      IntentoEjercicio(
        id: 7,
        usuarioId: 3,
        ejercicioId: 5,
        esCorrecto: true,
        tiempoRespuestaMs: 30000,
        dificultadAlMomento: 3,
        xpGanado: 19,
        fechaIntento: day6.add(const Duration(minutes: 6)),
      ),
      IntentoEjercicio(
        id: 8,
        usuarioId: 3,
        ejercicioId: 6,
        esCorrecto: true,
        tiempoRespuestaMs: 18000,
        dificultadAlMomento: 1,
        xpGanado: 15,
        fechaIntento: day3,
      ),
      IntentoEjercicio(
        id: 9,
        usuarioId: 3,
        ejercicioId: 7,
        esCorrecto: true,
        tiempoRespuestaMs: 26000,
        dificultadAlMomento: 1,
        xpGanado: 12,
        fechaIntento: day3.add(const Duration(minutes: 1)),
      ),
      IntentoEjercicio(
        id: 10,
        usuarioId: 3,
        ejercicioId: 8,
        esCorrecto: true,
        tiempoRespuestaMs: 34000,
        dificultadAlMomento: 2,
        xpGanado: 14,
        fechaIntento: day3.add(const Duration(minutes: 2)),
      ),
      IntentoEjercicio(
        id: 11,
        usuarioId: 3,
        ejercicioId: 9,
        esCorrecto: false,
        tiempoRespuestaMs: 32000,
        dificultadAlMomento: 2,
        xpGanado: 0,
        fechaIntento: day3.add(const Duration(minutes: 3)),
      ),
      IntentoEjercicio(
        id: 12,
        usuarioId: 3,
        ejercicioId: 9,
        esCorrecto: true,
        tiempoRespuestaMs: 32000,
        dificultadAlMomento: 2,
        xpGanado: 14,
        fechaIntento: day3.add(const Duration(minutes: 4)),
      ),
      IntentoEjercicio(
        id: 13,
        usuarioId: 3,
        ejercicioId: 10,
        esCorrecto: true,
        tiempoRespuestaMs: 30000,
        dificultadAlMomento: 3,
        xpGanado: 19,
        fechaIntento: day3.add(const Duration(minutes: 5)),
      ),
      IntentoEjercicio(
        id: 14,
        usuarioId: 3,
        ejercicioId: 8,
        esCorrecto: true,
        tiempoRespuestaMs: 25000,
        dificultadAlMomento: 2,
        xpGanado: 17,
        fechaIntento: day3.add(const Duration(minutes: 6)),
      ),
    ];

    final usuarioInsignias = <({int usuarioId, int insigniaId, DateTime fecha})>[
      (
        usuarioId: 3,
        insigniaId: 1,
        fecha: reference.subtract(const Duration(days: 6)),
      ),
      (usuarioId: 3, insigniaId: 2, fecha: day3),
    ];

    return SeedDatabase._(
      roles: roles,
      usuarios: usuarios,
      aulas: aulas,
      aulaEstudiantes: aulaEstudiantes,
      modulos: modulos,
      lecciones: lecciones,
      ejercicios: ejercicios,
      insignias: insignias,
      gamificacion: gamificacion,
      progreso: progreso,
      intentos: intentos,
      usuarioInsignias: usuarioInsignias,
    );
  }

  final List<Rol> roles;
  final List<Usuario> usuarios;
  final List<Aula> aulas;
  final List<({int aulaId, int estudianteId, DateTime fecha})> aulaEstudiantes;
  final List<Modulo> modulos;
  final List<Leccion> lecciones;
  final List<Ejercicio> ejercicios;
  final List<Insignia> insignias;
  final List<GamificacionUsuario> gamificacion;
  final List<ProgresoModulo> progreso;
  final List<IntentoEjercicio> intentos;
  final List<({int usuarioId, int insigniaId, DateTime fecha})> usuarioInsignias;

  static List<Ejercicio> _buildEjercicios() {
    const seeds = <_EjercicioSeed>[
      _EjercicioSeed(
        leccionId: 1,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 1,
        enunciado: '¿Qué es un dato?',
        tiempo: 25,
        explicacion:
            'Un dato es la representación simbólica de un hecho (por ejemplo, '
            '«18»). Solo se convierte en información cuando se procesa y se le '
            'da contexto (por ejemplo, «18 estudiantes aprobaron»).',
        opciones: [
          _OpcionSeed(
            'Un hecho o valor sin contexto que aún no se ha interpretado.',
            true,
          ),
          _OpcionSeed('Una conclusión lista para tomar decisiones.', false),
          _OpcionSeed('Un conjunto de tablas relacionadas.', false),
          _OpcionSeed('Un programa que administra archivos.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 1,
        tipo: TipoEjercicio.trueFalse,
        dificultad: 1,
        enunciado:
            'Una base de datos es un conjunto organizado de datos '
            'relacionados que permite almacenarlos y consultarlos de forma '
            'estructurada.',
        tiempo: 20,
        explicacion:
            'Una base de datos organiza datos relacionados y facilita su '
            'almacenamiento, búsqueda y actualización; el SGBD es el software '
            'que la administra.',
        opciones: [
          _OpcionSeed('Verdadero', true),
          _OpcionSeed('Falso', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 1,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 2,
        enunciado: '¿Cuál es la diferencia principal entre dato e información?',
        tiempo: 30,
        explicacion:
            'Los datos son la materia prima; la información es el resultado '
            'de procesarlos y contextualizarlos para que sean útiles en una '
            'decisión.',
        opciones: [
          _OpcionSeed(
            'La información es el resultado de procesar datos con contexto y '
            'propósito.',
            true,
          ),
          _OpcionSeed(
            'El dato siempre es numérico y la información siempre es textual.',
            false,
          ),
          _OpcionSeed(
            'La información se almacena y el dato no puede almacenarse.',
            false,
          ),
          _OpcionSeed(
            'No existe diferencia: son sinónimos exactos.',
            false,
          ),
        ],
      ),
      _EjercicioSeed(
        leccionId: 1,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 2,
        enunciado:
            '¿Cuál de las siguientes NO es una ventaja de usar una base de '
            'datos frente a archivos sueltos?',
        tiempo: 35,
        explicacion:
            'Duplicar datos es precisamente el problema que una base de datos '
            'busca evitar. Reducir redundancia, compartir datos y garantizar '
            'integridad sí son ventajas reales.',
        opciones: [
          _OpcionSeed(
            'Duplicar la información en cada área de la organización.',
            true,
          ),
          _OpcionSeed('Reducir la redundancia y las inconsistencias.', false),
          _OpcionSeed('Compartir datos entre varias aplicaciones.', false),
          _OpcionSeed('Garantizar integridad mediante restricciones.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 1,
        tipo: TipoEjercicio.trueFalse,
        dificultad: 3,
        enunciado:
            'En un archivo de texto plano, el sistema operativo garantiza '
            'automáticamente la integridad referencial entre registros.',
        tiempo: 30,
        explicacion:
            'Los archivos planos no tienen un motor que valide relaciones. La '
            'integridad referencial se logra con restricciones de clave '
            'foránea en un SGBD relacional.',
        opciones: [
          _OpcionSeed('Verdadero', false),
          _OpcionSeed('Falso', true),
        ],
      ),
      _EjercicioSeed(
        leccionId: 2,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 1,
        enunciado: '¿Qué significa la sigla SGBD?',
        tiempo: 20,
        explicacion:
            'SGBD significa Sistema Gestor de Bases de Datos (DBMS en '
            'inglés). Es el software que define, administra y consulta la '
            'base de datos.',
        opciones: [
          _OpcionSeed('Sistema Gestor de Bases de Datos.', true),
          _OpcionSeed('Sistema General de Bloques de Datos.', false),
          _OpcionSeed('Servidor Gráfico de Bases Dinámicas.', false),
          _OpcionSeed('Secuencia de Gestión Básica de Datos.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 2,
        tipo: TipoEjercicio.trueFalse,
        dificultad: 1,
        enunciado:
            'El SGBD es el software que permite definir, administrar y '
            'consultar una base de datos.',
        tiempo: 20,
        explicacion:
            'El SGBD actúa como intermediario entre los usuarios o '
            'aplicaciones y los datos almacenados.',
        opciones: [
          _OpcionSeed('Verdadero', true),
          _OpcionSeed('Falso', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 2,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 2,
        enunciado:
            '¿Qué componente del SGBD interpreta una consulta SQL y elige un '
            'plan de ejecución eficiente?',
        tiempo: 30,
        explicacion:
            'El optimizador analiza alternativas de acceso (índices, orden de '
            'JOIN, etc.) y selecciona el plan con menor costo estimado.',
        opciones: [
          _OpcionSeed('El optimizador (planificador) de consultas.', true),
          _OpcionSeed('El gestor de almacenamiento.', false),
          _OpcionSeed('El catálogo de usuarios.', false),
          _OpcionSeed('El compilador del lenguaje anfitrión.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 2,
        tipo: TipoEjercicio.fillSql,
        dificultad: 2,
        enunciado:
            'Completa la cláusula que permite filtrar filas en una consulta '
            'SQL.',
        fragmento: 'SELECT * FROM estudiantes ___ nivel = 3;',
        tiempo: 30,
        explicacion:
            'WHERE filtra filas antes de agrupar. HAVING filtra grupos '
            'después de GROUP BY.',
        opciones: [
          _OpcionSeed('WHERE', true),
          _OpcionSeed('GROUP BY', false),
          _OpcionSeed('ORDER BY', false),
          _OpcionSeed('HAVING', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 2,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 3,
        enunciado:
            '¿Cuál es la función principal del gestor de transacciones de un '
            'SGBD?',
        tiempo: 35,
        explicacion:
            'El gestor de transacciones asegura atomicidad, consistencia, '
            'aislamiento y durabilidad (ACID), incluso ante fallos o '
            'concurrencia.',
        opciones: [
          _OpcionSeed(
            'Garantizar las propiedades ACID de cada transacción.',
            true,
          ),
          _OpcionSeed('Diseñar el modelo entidad-relación.', false),
          _OpcionSeed(
            'Construir la interfaz gráfica de la aplicación.',
            false,
          ),
          _OpcionSeed('Comprimir los archivos de respaldo.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 3,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 1,
        enunciado: '¿Qué representa el modelo relacional?',
        tiempo: 25,
        explicacion:
            'El modelo relacional, propuesto por E. F. Codd, organiza los '
            'datos en relaciones (tablas) y usa álgebra relacional para '
            'consultarlos.',
        opciones: [
          _OpcionSeed(
            'Datos organizados en tablas (relaciones) con filas y columnas.',
            true,
          ),
          _OpcionSeed('Documentos JSON anidados sin esquema.', false),
          _OpcionSeed('Grafos de nodos y aristas.', false),
          _OpcionSeed('Archivos XML estrictamente jerárquicos.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 3,
        tipo: TipoEjercicio.trueFalse,
        dificultad: 1,
        enunciado:
            'En el modelo relacional, una fila representa una entidad o '
            'registro y una columna representa un atributo.',
        tiempo: 20,
        explicacion:
            'Cada fila (tupla) es una instancia de la entidad y cada columna '
            '(atributo) describe una propiedad de esa entidad.',
        opciones: [
          _OpcionSeed('Verdadero', true),
          _OpcionSeed('Falso', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 3,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 2,
        enunciado:
            '¿Qué tipo de modelo de datos organiza la información en '
            'documentos con estructura flexible?',
        tiempo: 30,
        explicacion:
            'Los modelos orientados a documentos, como MongoDB, guardan '
            'documentos semiestructurados (JSON/BSON) sin un esquema rígido '
            'de tablas.',
        opciones: [
          _OpcionSeed('Orientado a documentos (NoSQL).', true),
          _OpcionSeed('Relacional.', false),
          _OpcionSeed('Jerárquico.', false),
          _OpcionSeed('En red.', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 3,
        tipo: TipoEjercicio.fillSql,
        dificultad: 2,
        enunciado:
            'Completa la cláusula que ordena los resultados de una consulta.',
        fragmento: 'SELECT * FROM modulos ___ orden;',
        tiempo: 30,
        explicacion:
            'ORDER BY ordena el resultado por una o más columnas, de forma '
            'ascendente (ASC) o descendente (DESC).',
        opciones: [
          _OpcionSeed('ORDER BY', true),
          _OpcionSeed('WHERE', false),
          _OpcionSeed('GROUP BY', false),
          _OpcionSeed('HAVING', false),
        ],
      ),
      _EjercicioSeed(
        leccionId: 3,
        tipo: TipoEjercicio.multipleChoice,
        dificultad: 3,
        enunciado:
            'La tabla estudiantes tiene una columna aula_id que referencia a '
            'aulas.id. ¿Qué tipo de clave es aula_id?',
        tiempo: 35,
        explicacion:
            'Una clave foránea referencia la clave primaria de otra tabla y '
            'garantiza la integridad referencial entre ambas.',
        opciones: [
          _OpcionSeed('Clave foránea (FK).', true),
          _OpcionSeed('Clave primaria (PK).', false),
          _OpcionSeed('Clave candidata.', false),
          _OpcionSeed('Superclave.', false),
        ],
      ),
    ];

    var optionId = 1;
    final ejercicios = <Ejercicio>[];
    for (var index = 0; index < seeds.length; index++) {
      final seed = seeds[index];
      final ejercicioId = index + 1;
      final opciones = <OpcionEjercicio>[];
      for (final opcion in seed.opciones) {
        opciones.add(
          OpcionEjercicio(
            id: optionId++,
            ejercicioId: ejercicioId,
            textoOpcion: opcion.texto,
            esCorrecta: opcion.esCorrecta,
            ordenCorrecto: null,
          ),
        );
      }
      ejercicios.add(
        Ejercicio(
          id: ejercicioId,
          leccionId: seed.leccionId,
          tipo: seed.tipo,
          nivelDificultad: seed.dificultad,
          enunciado: seed.enunciado,
          fragmentoCodigo: seed.fragmento,
          tiempoEstimadoSeg: seed.tiempo,
          explicacionPedagogica: seed.explicacion,
          activo: true,
          opciones: opciones,
        ),
      );
    }
    return ejercicios;
  }
}
