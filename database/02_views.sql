-- ============================================================================
-- PROYECTO: Tutor Inteligente de Micro-Aprendizaje Adaptativo (Enfoque SABD)
-- ARCHIVO : 02_views.sql
-- OBJETIVO: Vistas analíticas para el Módulo 4 (Panel Docente).
-- REQUIERE: 01_schema.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Vista 1: Deficiencias conceptuales comunes del aula.
-- Responde: ¿qué módulo/lección concentra más errores en mi sección?
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_deficiencias_por_aula AS
SELECT
    a.id AS aula_id,
    a.nombre AS aula_nombre,
    m.id AS modulo_id,
    m.titulo AS modulo_titulo,
    l.id AS leccion_id,
    l.titulo AS leccion_titulo,
    COUNT(i.id) AS total_intentos,
    SUM(CASE WHEN i.es_correcto = FALSE THEN 1 ELSE 0 END) AS total_errores,
    ROUND(
        (SUM(CASE WHEN i.es_correcto = FALSE THEN 1 ELSE 0 END)::NUMERIC
            / NULLIF(COUNT(i.id), 0)) * 100,
        2
    ) AS porcentaje_error,
    ROUND(AVG(i.tiempo_respuesta_ms) / 1000.0, 2) AS tiempo_promedio_seg
FROM aulas a
JOIN aula_estudiantes ae ON ae.aula_id = a.id
JOIN intentos_ejercicio i ON i.usuario_id = ae.estudiante_id
JOIN ejercicios e ON e.id = i.ejercicio_id
JOIN lecciones l ON l.id = e.leccion_id
JOIN modulos m ON m.id = l.modulo_id
GROUP BY a.id, a.nombre, m.id, m.titulo, l.id, l.titulo;

-- ----------------------------------------------------------------------------
-- Vista 2: Semáforo de rendimiento estudiantil.
-- Clasifica a cada estudiante para que el docente priorice la ayuda:
--   REZAGO      -> dominio promedio < 40 %
--   EN_PROGRESO -> dominio entre 40 % y 75 %
--   AVANZADO    -> dominio > 75 %
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_semaforo_estudiantes AS
SELECT
    ae.aula_id,
    u.id AS estudiante_id,
    u.nombre_completo,
    ROUND(COALESCE(AVG(p.nivel_dominio), 0), 2) AS dominio_promedio,
    COALESCE(g.xp_total, 0) AS xp_total,
    COALESCE(g.racha_dias_actual, 0) AS racha_dias,
    CASE
        WHEN COALESCE(AVG(p.nivel_dominio), 0) < 40 THEN 'REZAGO'
        WHEN COALESCE(AVG(p.nivel_dominio), 0) <= 75 THEN 'EN_PROGRESO'
        ELSE 'AVANZADO'
    END AS categoria_rendimiento
FROM aula_estudiantes ae
JOIN usuarios u ON u.id = ae.estudiante_id
LEFT JOIN progreso_modulo_usuario p ON p.usuario_id = u.id
LEFT JOIN gamificacion_usuario g ON g.usuario_id = u.id
GROUP BY ae.aula_id, u.id, u.nombre_completo, g.xp_total, g.racha_dias_actual;

-- ----------------------------------------------------------------------------
-- Vista 3: KPIs generales del aula (tarjetas del panel docente).
-- Usa CTEs para evitar la multiplicación de filas al agregar progreso e
-- intentos en la misma consulta.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_kpi_aula AS
WITH progreso AS (
    SELECT
        ae.aula_id,
        AVG(p.nivel_dominio) AS dominio_promedio
    FROM aula_estudiantes ae
    LEFT JOIN progreso_modulo_usuario p ON p.usuario_id = ae.estudiante_id
    GROUP BY ae.aula_id
),
actividad AS (
    SELECT
        ae.aula_id,
        COUNT(i.id) AS total_intentos,
        COUNT(DISTINCT CASE
            WHEN i.fecha_intento >= CURRENT_DATE THEN i.usuario_id
        END) AS estudiantes_activos_hoy,
        ROUND(
            (SUM(CASE WHEN i.es_correcto THEN 1 ELSE 0 END)::NUMERIC
                / NULLIF(COUNT(i.id), 0)) * 100,
            2
        ) AS porcentaje_acierto
    FROM aula_estudiantes ae
    LEFT JOIN intentos_ejercicio i ON i.usuario_id = ae.estudiante_id
    GROUP BY ae.aula_id
)
SELECT
    a.id AS aula_id,
    a.nombre AS aula_nombre,
    a.codigo_acceso,
    COUNT(DISTINCT ae.estudiante_id) AS estudiantes_inscritos,
    ROUND(COALESCE(p.dominio_promedio, 0), 2) AS dominio_promedio,
    COALESCE(ac.estudiantes_activos_hoy, 0) AS estudiantes_activos_hoy,
    COALESCE(ac.total_intentos, 0) AS total_intentos,
    COALESCE(ac.porcentaje_acierto, 0) AS porcentaje_acierto
FROM aulas a
LEFT JOIN aula_estudiantes ae ON ae.aula_id = a.id
LEFT JOIN progreso p ON p.aula_id = a.id
LEFT JOIN actividad ac ON ac.aula_id = a.id
GROUP BY
    a.id,
    a.nombre,
    a.codigo_acceso,
    p.dominio_promedio,
    ac.estudiantes_activos_hoy,
    ac.total_intentos,
    ac.porcentaje_acierto;

COMMIT;
