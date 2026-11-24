-- ============================================================================
-- PROYECTO: Tutor Inteligente de Micro-Aprendizaje Adaptativo (Enfoque SABD)
-- ARCHIVO : 01_schema.sql
-- SGBD    : PostgreSQL 15+ (probado sobre PostgreSQL 16)
-- OBJETIVO: Crear el modelo relacional normalizado en 3FN definido en
--           docs/modelo_base_datos_sabd.md.
--
-- NOTAS DE DISEÑO
--  * Se usan restricciones CHECK (en lugar de tipos ENUM nativos) para los
--    catálogos de valores cerrados: son auditables, portables y permiten
--    evolucionar el catálogo con un ALTER TABLE sin recrear el tipo.
--  * Todas las claves primarias simples usan BIGINT GENERATED ALWAYS AS
--    IDENTITY. Las tablas puente usan clave primaria compuesta pura (2FN).
--  * Los índices de las claves foráneas se declaran explícitamente porque
--    PostgreSQL NO indexa automáticamente las columnas referenciantes.
-- ============================================================================

BEGIN;

-- 1. ROLES -------------------------------------------------------------------
CREATE TABLE roles (
    id     SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
        CHECK (nombre IN ('ESTUDIANTE', 'DOCENTE', 'ADMIN'))
);

-- 2. USUARIOS ----------------------------------------------------------------
CREATE TABLE usuarios (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rol_id         SMALLINT NOT NULL
        REFERENCES roles(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    nombre_completo VARCHAR(120) NOT NULL,
    correo         VARCHAR(150) NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. AULAS (soporte para aulas numerosas y multigrado) -----------------------
CREATE TABLE aulas (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    docente_id        BIGINT NOT NULL
        REFERENCES usuarios(id) ON DELETE RESTRICT,
    nombre            VARCHAR(120) NOT NULL,
    codigo_acceso     VARCHAR(20) NOT NULL UNIQUE,
    periodo_academico VARCHAR(30) NOT NULL, -- Ej.: '2026-II'
    activa            BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. INSCRIPCIONES DE ESTUDIANTES EN AULAS (relación N:M) --------------------
CREATE TABLE aula_estudiantes (
    aula_id           BIGINT NOT NULL
        REFERENCES aulas(id) ON DELETE CASCADE,
    estudiante_id     BIGINT NOT NULL
        REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_inscripcion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (aula_id, estudiante_id)
);

-- 5. MÓDULOS TEMÁTICOS (ruta tipo Duolingo) ----------------------------------
CREATE TABLE modulos (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo      VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    orden       SMALLINT NOT NULL UNIQUE CHECK (orden > 0),
    icono       VARCHAR(50),
    activo      BOOLEAN NOT NULL DEFAULT TRUE
);

-- 6. LECCIONES (micro-unidades dentro de cada módulo) ------------------------
CREATE TABLE lecciones (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    modulo_id      BIGINT NOT NULL
        REFERENCES modulos(id) ON DELETE CASCADE,
    titulo         VARCHAR(120) NOT NULL,
    resumen_teorico TEXT, -- Micro-cápsula previa al ejercicio o de refuerzo
    orden          SMALLINT NOT NULL CHECK (orden > 0),
    xp_recompensa  INTEGER NOT NULL DEFAULT 20 CHECK (xp_recompensa > 0),
    UNIQUE (modulo_id, orden)
);

-- 7. EJERCICIOS --------------------------------------------------------------
CREATE TABLE ejercicios (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    leccion_id            BIGINT NOT NULL
        REFERENCES lecciones(id) ON DELETE CASCADE,
    tipo_ejercicio        VARCHAR(30) NOT NULL CHECK (
        tipo_ejercicio IN ('MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_SQL', 'ORDER_QUERY')
    ),
    nivel_dificultad      SMALLINT NOT NULL CHECK (nivel_dificultad BETWEEN 1 AND 5),
    enunciado             TEXT NOT NULL,
    fragmento_codigo      TEXT, -- Bloque SQL opcional mostrado en pantalla
    tiempo_estimado_seg   SMALLINT NOT NULL DEFAULT 30 CHECK (tiempo_estimado_seg > 0),
    explicacion_pedagogica TEXT NOT NULL,
    activo                BOOLEAN NOT NULL DEFAULT TRUE
);

-- 8. OPCIONES DE EJERCICIO (garantiza 1FN: un valor atómico por fila) --------
CREATE TABLE opciones_ejercicio (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ejercicio_id  BIGINT NOT NULL
        REFERENCES ejercicios(id) ON DELETE CASCADE,
    texto_opcion  TEXT NOT NULL,
    es_correcta   BOOLEAN NOT NULL DEFAULT FALSE,
    orden_correcto SMALLINT -- Solo para ORDER_QUERY; NULL en los demás tipos
);

-- 9. INTENTOS DE EJERCICIO (historial transaccional inmutable) ---------------
CREATE TABLE intentos_ejercicio (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id            BIGINT NOT NULL
        REFERENCES usuarios(id) ON DELETE CASCADE,
    ejercicio_id          BIGINT NOT NULL
        REFERENCES ejercicios(id) ON DELETE RESTRICT,
    es_correcto           BOOLEAN NOT NULL,
    tiempo_respuesta_ms   INTEGER NOT NULL CHECK (tiempo_respuesta_ms > 0),
    dificultad_al_momento SMALLINT NOT NULL CHECK (dificultad_al_momento BETWEEN 1 AND 5),
    xp_ganado             INTEGER NOT NULL DEFAULT 0 CHECK (xp_ganado >= 0),
    fecha_intento         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. PROGRESO Y ESTADO ADAPTATIVO POR MÓDULO -------------------------------
CREATE TABLE progreso_modulo_usuario (
    usuario_id              BIGINT NOT NULL
        REFERENCES usuarios(id) ON DELETE CASCADE,
    modulo_id               BIGINT NOT NULL
        REFERENCES modulos(id) ON DELETE CASCADE,
    nivel_dominio           NUMERIC(5,2) NOT NULL DEFAULT 20.00
        CHECK (nivel_dominio BETWEEN 0 AND 100),
    dificultad_actual       SMALLINT NOT NULL DEFAULT 1
        CHECK (dificultad_actual BETWEEN 1 AND 5),
    racha_errores_consecutivos SMALLINT NOT NULL DEFAULT 0
        CHECK (racha_errores_consecutivos >= 0),
    estado                  VARCHAR(20) NOT NULL DEFAULT 'EN_PROGRESO'
        CHECK (estado IN ('BLOQUEADO', 'EN_PROGRESO', 'DOMINADO')),
    actualizado_en          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, modulo_id)
);

-- 11. GAMIFICACIÓN DEL USUARIO (relación 1:1 con estudiantes) ----------------
CREATE TABLE gamificacion_usuario (
    usuario_id           BIGINT PRIMARY KEY
        REFERENCES usuarios(id) ON DELETE CASCADE,
    xp_total             INTEGER NOT NULL DEFAULT 0 CHECK (xp_total >= 0),
    nivel_actual         SMALLINT NOT NULL DEFAULT 1 CHECK (nivel_actual >= 1),
    racha_dias_actual    INTEGER NOT NULL DEFAULT 0 CHECK (racha_dias_actual >= 0),
    mejor_racha_dias     INTEGER NOT NULL DEFAULT 0 CHECK (mejor_racha_dias >= 0),
    ultima_fecha_practica DATE
);

-- 12. INSIGNIAS Y LOGROS -----------------------------------------------------
CREATE TABLE insignias (
    id          SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo      VARCHAR(40) NOT NULL UNIQUE,
    nombre      VARCHAR(80) NOT NULL,
    descripcion TEXT NOT NULL,
    icono       VARCHAR(50)
);

CREATE TABLE usuario_insignias (
    usuario_id    BIGINT NOT NULL
        REFERENCES usuarios(id) ON DELETE CASCADE,
    insignia_id   SMALLINT NOT NULL
        REFERENCES insignias(id) ON DELETE RESTRICT,
    fecha_obtencion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, insignia_id)
);

-- ============================================================================
-- ÍNDICES ESTRATÉGICOS (optimización para aulas numerosas)
-- ============================================================================
-- Definidos en el modelo base
CREATE INDEX idx_intentos_usuario_fecha
    ON intentos_ejercicio (usuario_id, fecha_intento DESC);
CREATE INDEX idx_intentos_ejercicio_correcto
    ON intentos_ejercicio (ejercicio_id, es_correcto);
CREATE INDEX idx_ejercicios_leccion_dificultad
    ON ejercicios (leccion_id, nivel_dificultad) WHERE activo = TRUE;
CREATE INDEX idx_aula_estudiantes_estudiante
    ON aula_estudiantes (estudiante_id);

-- Índices adicionales para cubrir claves foráneas y el motor adaptativo
CREATE INDEX idx_usuarios_rol ON usuarios (rol_id);
CREATE INDEX idx_aulas_docente ON aulas (docente_id);
CREATE INDEX idx_lecciones_modulo ON lecciones (modulo_id);
CREATE INDEX idx_opciones_ejercicio ON opciones_ejercicio (ejercicio_id);
CREATE INDEX idx_progreso_modulo ON progreso_modulo_usuario (modulo_id);
CREATE INDEX idx_usuario_insignias_insignia ON usuario_insignias (insignia_id);
CREATE INDEX idx_intentos_usuario_ejercicio
    ON intentos_ejercicio (usuario_id, ejercicio_id);

COMMIT;
