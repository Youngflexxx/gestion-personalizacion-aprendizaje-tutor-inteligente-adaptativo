-- ============================================================================
-- PROYECTO: Tutor Inteligente de Micro-Aprendizaje Adaptativo (Enfoque SABD)
-- ARCHIVO : 03_seed.sql
-- OBJETIVO: Datos semilla realistas y coherentes con el motor adaptativo.
-- REQUIERE: 01_schema.sql y 02_views.sql
--
-- CONTENIDO
--   * 1 docente y 2 estudiantes (María inicia desde cero; Carlos ya completó
--     las lecciones 1 y 2 del Módulo 1).
--   * 1 aula: SABD Sección D2 (código SABD-2026-D2).
--   * 5 módulos del plan curricular; el Módulo 1 está completamente poblado
--     con 3 lecciones y 15 ejercicios (6 fáciles, 6 medios y 3 difíciles).
--   * Historial de intentos de Carlos que justifica su dominio (70.00) y XP.
--   * Catálogo de insignias y logros desbloqueados.
--
-- SEGURIDAD: los password_hash son marcadores de posición de demo. En
-- producción deben generarse con bcrypt/Argon2 y nunca almacenarse en texto
-- plano. No se incluyen credenciales reales en este archivo.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. ROLES
-- ---------------------------------------------------------------------------
INSERT INTO roles (id, nombre) OVERRIDING SYSTEM VALUE VALUES
    (1, 'ESTUDIANTE'),
    (2, 'DOCENTE'),
    (3, 'ADMIN');

-- ---------------------------------------------------------------------------
-- 2. USUARIOS (1 docente + 2 estudiantes)
-- ---------------------------------------------------------------------------
INSERT INTO usuarios
    (id, rol_id, nombre_completo, correo, password_hash, activo, creado_en)
OVERRIDING SYSTEM VALUE VALUES
    (1, 2, 'Prof. Docente Demo', 'docente.demo@sabd.edu.ve',
     '$2b$12$DEMO_ONLY_REPLACE_WITH_BCRYPT_HASH', TRUE, NOW() - INTERVAL '90 days'),
    (2, 1, 'María González', 'maria.gonzalez@sabd.edu.ve',
     '$2b$12$DEMO_ONLY_REPLACE_WITH_BCRYPT_HASH', TRUE, NOW() - INTERVAL '60 days'),
    (3, 1, 'Carlos Pérez', 'carlos.perez@sabd.edu.ve',
     '$2b$12$DEMO_ONLY_REPLACE_WITH_BCRYPT_HASH', TRUE, NOW() - INTERVAL '60 days');

-- ---------------------------------------------------------------------------
-- 3. AULA E INSCRIPCIONES
-- ---------------------------------------------------------------------------
INSERT INTO aulas
    (id, docente_id, nombre, codigo_acceso, periodo_academico, activa, creado_en)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'SABD Sección D2', 'SABD-2026-D2', '2026-II', TRUE,
     NOW() - INTERVAL '30 days');

INSERT INTO aula_estudiantes (aula_id, estudiante_id, fecha_inscripcion) VALUES
    (1, 2, NOW() - INTERVAL '28 days'),
    (1, 3, NOW() - INTERVAL '28 days');

-- ---------------------------------------------------------------------------
-- 4. MÓDULOS DEL PLAN CURRICULAR SABD
--    Solo el Módulo 1 tiene contenido completo en este MVP.
-- ---------------------------------------------------------------------------
INSERT INTO modulos (id, titulo, descripcion, orden, icono, activo)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'Fundamentos de BD y SGBD',
     'Datos vs. información, arquitectura de un SGBD y modelos de bases de datos.',
     1, 'storage', TRUE),
    (2, 'Modelo Entidad-Relación (E-R)',
     'Entidades, atributos, claves y cardinalidades del modelo conceptual.',
     2, 'account_tree', TRUE),
    (3, 'Normalización Relacional',
     'Primera, segunda y tercera forma normal para eliminar redundancias.',
     3, 'schema', TRUE),
    (4, 'SQL Esencial (DDL y DML)',
     'CREATE TABLE, INSERT, UPDATE, DELETE y consultas SELECT con WHERE.',
     4, 'code', TRUE),
    (5, 'Consultas Avanzadas e Integridad',
     'JOIN, GROUP BY, HAVING, transacciones ACID e índices.',
     5, 'insights', TRUE);

-- ---------------------------------------------------------------------------
-- 5. LECCIONES DEL MÓDULO 1
-- ---------------------------------------------------------------------------
INSERT INTO lecciones
    (id, modulo_id, titulo, resumen_teorico, orden, xp_recompensa)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Datos, información y bases de datos',
     'Un dato es un hecho sin contexto; la información surge al procesarlo. Una base de datos organiza datos relacionados y un SGBD los administra con integridad.',
     1, 20),
    (2, 1, 'Arquitectura y componentes de un SGBD',
     'El SGBD incluye gestor de almacenamiento, procesador de consultas, optimizador, gestor de transacciones y catálogo de metadatos. Su meta es garantizar ACID y acceso eficiente.',
     2, 25),
    (3, 1, 'Modelos de bases de datos',
     'El modelo relacional usa tablas, filas y columnas. Existen también modelos jerárquicos, en red, orientados a documentos y a grafos, cada uno con ventajas según el dominio.',
     3, 30);

-- ---------------------------------------------------------------------------
-- 6. EJERCICIOS DEL MÓDULO 1 (15: dificultad 1 = fácil, 2 = media, 3 = difícil)
-- ---------------------------------------------------------------------------
INSERT INTO ejercicios
    (id, leccion_id, tipo_ejercicio, nivel_dificultad, enunciado,
     fragmento_codigo, tiempo_estimado_seg, explicacion_pedagogica, activo)
OVERRIDING SYSTEM VALUE VALUES
    -- Lección 1: Datos, información y bases de datos
    (1, 1, 'MULTIPLE_CHOICE', 1, '¿Qué es un dato?', NULL, 25,
     'Un dato es la representación simbólica de un hecho (por ejemplo, «18»). Solo se convierte en información cuando se procesa y se le da contexto (por ejemplo, «18 estudiantes aprobaron»).', TRUE),
    (2, 1, 'TRUE_FALSE', 1, 'Una base de datos es un conjunto organizado de datos relacionados que permite almacenarlos y consultarlos de forma estructurada.', NULL, 20,
     'Una base de datos organiza datos relacionados y facilita su almacenamiento, búsqueda y actualización; el SGBD es el software que la administra.', TRUE),
    (3, 1, 'MULTIPLE_CHOICE', 2, '¿Cuál es la diferencia principal entre dato e información?', NULL, 30,
     'Los datos son la materia prima; la información es el resultado de procesarlos y contextualizarlos para que sean útiles en una decisión.', TRUE),
    (4, 1, 'MULTIPLE_CHOICE', 2, '¿Cuál de las siguientes NO es una ventaja de usar una base de datos frente a archivos sueltos?', NULL, 35,
     'Duplicar datos es precisamente el problema que una base de datos busca evitar. Reducir redundancia, compartir datos y garantizar integridad sí son ventajas reales.', TRUE),
    (5, 1, 'TRUE_FALSE', 3, 'En un archivo de texto plano, el sistema operativo garantiza automáticamente la integridad referencial entre registros.', NULL, 30,
     'Los archivos planos no tienen un motor que valide relaciones. La integridad referencial se logra con restricciones de clave foránea en un SGBD relacional.', TRUE),
    -- Lección 2: Arquitectura y componentes de un SGBD
    (6, 2, 'MULTIPLE_CHOICE', 1, '¿Qué significa la sigla SGBD?', NULL, 20,
     'SGBD significa Sistema Gestor de Bases de Datos (DBMS en inglés). Es el software que define, administra y consulta la base de datos.', TRUE),
    (7, 2, 'TRUE_FALSE', 1, 'El SGBD es el software que permite definir, administrar y consultar una base de datos.', NULL, 20,
     'El SGBD actúa como intermediario entre los usuarios o aplicaciones y los datos almacenados.', TRUE),
    (8, 2, 'MULTIPLE_CHOICE', 2, '¿Qué componente del SGBD interpreta una consulta SQL y elige un plan de ejecución eficiente?', NULL, 30,
     'El optimizador analiza alternativas de acceso (índices, orden de JOIN, etc.) y selecciona el plan con menor costo estimado.', TRUE),
    (9, 2, 'FILL_SQL', 2, 'Completa la cláusula que permite filtrar filas en una consulta SQL.',
     'SELECT * FROM estudiantes ___ nivel = 3;', 30,
     'WHERE filtra filas antes de agrupar. HAVING filtra grupos después de GROUP BY.', TRUE),
    (10, 2, 'MULTIPLE_CHOICE', 3, '¿Cuál es la función principal del gestor de transacciones de un SGBD?', NULL, 35,
     'El gestor de transacciones asegura atomicidad, consistencia, aislamiento y durabilidad (ACID), incluso ante fallos o concurrencia.', TRUE),
    -- Lección 3: Modelos de bases de datos
    (11, 3, 'MULTIPLE_CHOICE', 1, '¿Qué representa el modelo relacional?', NULL, 25,
     'El modelo relacional, propuesto por E. F. Codd, organiza los datos en relaciones (tablas) y usa álgebra relacional para consultarlos.', TRUE),
    (12, 3, 'TRUE_FALSE', 1, 'En el modelo relacional, una fila representa una entidad o registro y una columna representa un atributo.', NULL, 20,
     'Cada fila (tupla) es una instancia de la entidad y cada columna (atributo) describe una propiedad de esa entidad.', TRUE),
    (13, 3, 'MULTIPLE_CHOICE', 2, '¿Qué tipo de modelo de datos organiza la información en documentos con estructura flexible?', NULL, 30,
     'Los modelos orientados a documentos, como MongoDB, guardan documentos semiestructurados (JSON/BSON) sin un esquema rígido de tablas.', TRUE),
    (14, 3, 'FILL_SQL', 2, 'Completa la cláusula que ordena los resultados de una consulta.',
     'SELECT * FROM modulos ___ orden;', 30,
     'ORDER BY ordena el resultado por una o más columnas, de forma ascendente (ASC) o descendente (DESC).', TRUE),
    (15, 3, 'MULTIPLE_CHOICE', 3, 'La tabla estudiantes tiene una columna aula_id que referencia aulas.id. ¿Qué tipo de clave es aula_id?', NULL, 35,
     'Una clave foránea referencia la clave primaria de otra tabla y garantiza la integridad referencial entre ambas.', TRUE);

-- ---------------------------------------------------------------------------
-- 7. OPCIONES DE EJERCICIO (un valor atómico por fila -> 1FN)
-- ---------------------------------------------------------------------------
INSERT INTO opciones_ejercicio
    (id, ejercicio_id, texto_opcion, es_correcta, orden_correcto)
OVERRIDING SYSTEM VALUE VALUES
    -- Ejercicio 1
    (1, 1, 'Un hecho o valor sin contexto que aún no se ha interpretado.', TRUE, NULL),
    (2, 1, 'Una conclusión lista para tomar decisiones.', FALSE, NULL),
    (3, 1, 'Un conjunto de tablas relacionadas.', FALSE, NULL),
    (4, 1, 'Un programa que administra archivos.', FALSE, NULL),
    -- Ejercicio 2
    (5, 2, 'Verdadero', TRUE, NULL),
    (6, 2, 'Falso', FALSE, NULL),
    -- Ejercicio 3
    (7, 3, 'La información es el resultado de procesar datos con contexto y propósito.', TRUE, NULL),
    (8, 3, 'El dato siempre es numérico y la información siempre es textual.', FALSE, NULL),
    (9, 3, 'La información se almacena y el dato no puede almacenarse.', FALSE, NULL),
    (10, 3, 'No existe diferencia: son sinónimos exactos.', FALSE, NULL),
    -- Ejercicio 4
    (11, 4, 'Duplicar la información en cada área de la organización.', TRUE, NULL),
    (12, 4, 'Reducir la redundancia y las inconsistencias.', FALSE, NULL),
    (13, 4, 'Compartir datos entre varias aplicaciones.', FALSE, NULL),
    (14, 4, 'Garantizar integridad mediante restricciones.', FALSE, NULL),
    -- Ejercicio 5
    (15, 5, 'Verdadero', FALSE, NULL),
    (16, 5, 'Falso', TRUE, NULL),
    -- Ejercicio 6
    (17, 6, 'Sistema Gestor de Bases de Datos.', TRUE, NULL),
    (18, 6, 'Sistema General de Bloques de Datos.', FALSE, NULL),
    (19, 6, 'Servidor Gráfico de Bases Dinámicas.', FALSE, NULL),
    (20, 6, 'Secuencia de Gestión Básica de Datos.', FALSE, NULL),
    -- Ejercicio 7
    (21, 7, 'Verdadero', TRUE, NULL),
    (22, 7, 'Falso', FALSE, NULL),
    -- Ejercicio 8
    (23, 8, 'El optimizador (planificador) de consultas.', TRUE, NULL),
    (24, 8, 'El gestor de almacenamiento.', FALSE, NULL),
    (25, 8, 'El catálogo de usuarios.', FALSE, NULL),
    (26, 8, 'El compilador del lenguaje anfitrión.', FALSE, NULL),
    -- Ejercicio 9
    (27, 9, 'WHERE', TRUE, NULL),
    (28, 9, 'GROUP BY', FALSE, NULL),
    (29, 9, 'ORDER BY', FALSE, NULL),
    (30, 9, 'HAVING', FALSE, NULL),
    -- Ejercicio 10
    (31, 10, 'Garantizar las propiedades ACID de cada transacción.', TRUE, NULL),
    (32, 10, 'Diseñar el modelo entidad-relación.', FALSE, NULL),
    (33, 10, 'Construir la interfaz gráfica de la aplicación.', FALSE, NULL),
    (34, 10, 'Comprimir los archivos de respaldo.', FALSE, NULL),
    -- Ejercicio 11
    (35, 11, 'Datos organizados en tablas (relaciones) con filas y columnas.', TRUE, NULL),
    (36, 11, 'Documentos JSON anidados sin esquema.', FALSE, NULL),
    (37, 11, 'Grafos de nodos y aristas.', FALSE, NULL),
    (38, 11, 'Archivos XML estrictamente jerárquicos.', FALSE, NULL),
    -- Ejercicio 12
    (39, 12, 'Verdadero', TRUE, NULL),
    (40, 12, 'Falso', FALSE, NULL),
    -- Ejercicio 13
    (41, 13, 'Orientado a documentos (NoSQL).', TRUE, NULL),
    (42, 13, 'Relacional.', FALSE, NULL),
    (43, 13, 'Jerárquico.', FALSE, NULL),
    (44, 13, 'En red.', FALSE, NULL),
    -- Ejercicio 14
    (45, 14, 'ORDER BY', TRUE, NULL),
    (46, 14, 'WHERE', FALSE, NULL),
    (47, 14, 'GROUP BY', FALSE, NULL),
    (48, 14, 'HAVING', FALSE, NULL),
    -- Ejercicio 15
    (49, 15, 'Clave foránea (FK).', TRUE, NULL),
    (50, 15, 'Clave primaria (PK).', FALSE, NULL),
    (51, 15, 'Clave candidata.', FALSE, NULL),
    (52, 15, 'Superclave.', FALSE, NULL);

-- ---------------------------------------------------------------------------
-- 8. INSIGNIAS
-- ---------------------------------------------------------------------------
INSERT INTO insignias (id, codigo, nombre, descripcion, icono)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'PRIMER_PASO', 'Primer paso', 'Completa tu primera lección de SABD.', 'flag'),
    (2, 'RACHA_3', 'Constancia', 'Mantén una racha de 3 días consecutivos.', 'local_fire_department'),
    (3, 'EXPLORADOR_BD', 'Explorador de BD', 'Completa el Módulo 1: Fundamentos de BD y SGBD.', 'explore'),
    (4, 'MAESTRO_SQL', 'Maestro SQL', 'Domina el módulo de SQL Esencial.', 'code');

-- ---------------------------------------------------------------------------
-- 9. GAMIFICACIÓN Y PROGRESO ADAPTATIVO
--    María inicia desde cero. Carlos completó las lecciones 1 y 2.
-- ---------------------------------------------------------------------------
INSERT INTO gamificacion_usuario
    (usuario_id, xp_total, nivel_actual, racha_dias_actual, mejor_racha_dias,
     ultima_fecha_practica)
VALUES
    (2, 0, 1, 0, 0, NULL),
    (3, 213, 3, 6, 6, CURRENT_DATE - 1);

INSERT INTO progreso_modulo_usuario
    (usuario_id, modulo_id, nivel_dominio, dificultad_actual,
     racha_errores_consecutivos, estado, actualizado_en)
VALUES
    (2, 1, 20.00, 1, 0, 'EN_PROGRESO', NOW() - INTERVAL '28 days'),
    (3, 1, 70.00, 4, 0, 'EN_PROGRESO', NOW() - INTERVAL '3 days');

-- ---------------------------------------------------------------------------
-- 10. HISTORIAL DE INTENTOS DE CARLOS (14 intentos)
--     El nivel de dominio resultante (70.00) se obtiene aplicando exactamente
--     las fórmulas de docs/agents.md:
--       acierto rápido  -> +(6 + d)
--       acierto lento   -> +(3 + 0.5 * d)
--       error           -> -(8 - d)
--     Secuencia: 20 -> 27 -> 30.5 -> 24.5 -> 28.5 -> 36.5 -> 31.5 -> 40.5
--                -> 47.5 -> 51 -> 55 -> 49 -> 53 -> 62 -> 70.
-- ---------------------------------------------------------------------------
INSERT INTO intentos_ejercicio
    (id, usuario_id, ejercicio_id, es_correcto, tiempo_respuesta_ms,
     dificultad_al_momento, xp_ganado, fecha_intento)
OVERRIDING SYSTEM VALUE VALUES
    (1, 3, 1, TRUE, 20000, 1, 15, NOW() - INTERVAL '6 days'),
    (2, 3, 2, TRUE, 26000, 1, 12, NOW() - INTERVAL '6 days' + INTERVAL '1 minute'),
    (3, 3, 3, FALSE, 35000, 2, 0, NOW() - INTERVAL '6 days' + INTERVAL '2 minutes'),
    (4, 3, 3, TRUE, 34000, 2, 14, NOW() - INTERVAL '6 days' + INTERVAL '3 minutes'),
    (5, 3, 4, TRUE, 28000, 2, 17, NOW() - INTERVAL '6 days' + INTERVAL '4 minutes'),
    (6, 3, 5, FALSE, 40000, 3, 0, NOW() - INTERVAL '6 days' + INTERVAL '5 minutes'),
    (7, 3, 5, TRUE, 30000, 3, 19, NOW() - INTERVAL '6 days' + INTERVAL '6 minutes'),
    (8, 3, 6, TRUE, 18000, 1, 15, NOW() - INTERVAL '3 days'),
    (9, 3, 7, TRUE, 26000, 1, 12, NOW() - INTERVAL '3 days' + INTERVAL '1 minute'),
    (10, 3, 8, TRUE, 34000, 2, 14, NOW() - INTERVAL '3 days' + INTERVAL '2 minutes'),
    (11, 3, 9, FALSE, 32000, 2, 0, NOW() - INTERVAL '3 days' + INTERVAL '3 minutes'),
    (12, 3, 9, TRUE, 32000, 2, 14, NOW() - INTERVAL '3 days' + INTERVAL '4 minutes'),
    (13, 3, 10, TRUE, 30000, 3, 19, NOW() - INTERVAL '3 days' + INTERVAL '5 minutes'),
    (14, 3, 8, TRUE, 25000, 2, 17, NOW() - INTERVAL '3 days' + INTERVAL '6 minutes');

INSERT INTO usuario_insignias (usuario_id, insignia_id, fecha_obtencion) VALUES
    (3, 1, NOW() - INTERVAL '6 days'),
    (3, 2, NOW() - INTERVAL '3 days');

-- ---------------------------------------------------------------------------
-- 11. SINCRONIZAR SECUENCIAS DE IDENTIDAD
--     Como el seed insertó IDs explícitos, se avanza cada secuencia para que
--     los próximos INSERT generados por la aplicación no colisionen.
-- ---------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('roles', 'id'),
              (SELECT MAX(id) FROM roles), TRUE);
SELECT setval(pg_get_serial_sequence('usuarios', 'id'),
              (SELECT MAX(id) FROM usuarios), TRUE);
SELECT setval(pg_get_serial_sequence('aulas', 'id'),
              (SELECT MAX(id) FROM aulas), TRUE);
SELECT setval(pg_get_serial_sequence('modulos', 'id'),
              (SELECT MAX(id) FROM modulos), TRUE);
SELECT setval(pg_get_serial_sequence('lecciones', 'id'),
              (SELECT MAX(id) FROM lecciones), TRUE);
SELECT setval(pg_get_serial_sequence('ejercicios', 'id'),
              (SELECT MAX(id) FROM ejercicios), TRUE);
SELECT setval(pg_get_serial_sequence('opciones_ejercicio', 'id'),
              (SELECT MAX(id) FROM opciones_ejercicio), TRUE);
SELECT setval(pg_get_serial_sequence('intentos_ejercicio', 'id'),
              (SELECT MAX(id) FROM intentos_ejercicio), TRUE);
SELECT setval(pg_get_serial_sequence('insignias', 'id'),
              (SELECT MAX(id) FROM insignias), TRUE);

COMMIT;
