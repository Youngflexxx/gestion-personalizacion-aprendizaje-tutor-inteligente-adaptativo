# AGENTS.md — Tutor Inteligente de Micro-Aprendizaje Adaptativo (Enfoque SABD)

> **Proyecto Académico:** Gestión y Personalización del Aprendizaje en Aulas Multigrado o Numerosas mediante un Tutor Inteligente de Micro-Aprendizaje Adaptativo.  
> **Institución:** UNEFA — Núcleo Falcón, Extensión Punto Fijo (`08S-2630-D2`).  
> **Materia:** Sistemas Administradores de Bases de Datos (SABD) — Prof. Edwin Flores.  
> **Stack Principal:** Flutter + Dart (Frontend Multiplataforma) | PostgreSQL (SGBD Relacional).

---

## 1. Análisis del Proyecto y Estrategia de Acotamiento (MVP Cerrado)

### Diagnóstico del Documento Original
El planteamiento actual de la investigación es sólido en su estructura metodológica (Capítulo I, objetivos, 4 módulos y metodología Scrum), pero presenta un **alcance temático abierto** ("aulas multigrado o numerosas" sin definir asignatura ni currículo). Intentar crear contenido para múltiples materias y grados en un solo semestre haría inviable el desarrollo y debilitaría la demostración técnica.

### Solución: Enfoque Cerrado sin Romper la Tesis
Se mantiene intacta la arquitectura genérica del sistema (para que pueda escalar a cualquier aula multigrado o numerosa), pero el **Producto Mínimo Viable (MVP)** se cierra estrictamente en la materia **Sistemas Administradores de Bases de Datos (SABD)** bajo una experiencia de micro-aprendizaje gamificado estilo **Duolingo**.

* **¿Por qué esto justifica el título original?** Un salón universitario numeroso (como la sección `08S-2630-D2`) se comporta funcionalmente como un aula heterogénea/multinivel: coexisten estudiantes con experiencia previa en SQL y programación junto a estudiantes que requieren refuerzo en modelado básico. El tutor adapta la dificultad a cada ritmo individual.
* **Corrección menor detectada en el PDF original:** En la página 5 (*Justificación*, primera línea) aparece el anglicismo *"se considera **highly** conveniente"*. Corregir a *"se considera **altamente** conveniente"* antes de la entrega final.

---

## 2. Stack Tecnológico y Decisiones de Arquitectura

Toda contribución generada por desarrolladores o agentes de IA debe respetar estrictamente las siguientes tecnologías:

| Capa | Tecnología | Justificación Técnica y Académica |
| :--- | :--- | :--- |
| **UI / Frontend** | **Flutter 3.x + Dart** | Un único código base compila para **Android, iOS y Web**, cumpliendo literalmente el alcance (*"interfaces web o móviles"*). |
| **Gestión de Estado** | **Riverpod (`flutter_riverpod`)** | Manejo reactivo, testeable y seguro en tiempo de compilación para sesiones de lecciones, temporizadores y métricas en vivo. |
| **Navegación** | **GoRouter (`go_router`)** | Rutas declarativas con guardias de autenticación por rol (`estudiante` vs. `docente`). |
| **Base de Datos (SGBD)** | **PostgreSQL** | SGBD relacional robusto, 100% ACID, soporte de vistas analíticas, restricciones de integridad y excelente defensa en la cátedra SABD. |
| **Capa de Conexión** | **Supabase (PostgreSQL + Auth + REST/RPC)** o API REST propia (Dart/Node/Python) | Permite a Flutter consumir directamente la base de datos relacional PostgreSQL con autenticación JWT y políticas de seguridad por fila (RLS). |
| **Almacenamiento Local (Opcional)** | **SharedPreferences / Drift (SQLite)** | Caché ligero de sesión y soporte de resiliencia ante caídas breves de internet. |

---

## 3. Los 4 Módulos del Sistema (Alineados al Alcance del Proyecto)

El código y las funcionalidades deben mapearse 1 a 1 con los cuatro módulos definidos en el documento de investigación:

### Módulo 1: Gestión de Usuarios y Autenticación (`auth`)
* Registro e inicio de sesión con correo y contraseña.
* Control estricto de roles:
  * **Estudiante:** Se inscribe en un aula mediante código de sección (ej. `SABD-2026-D2`), realiza lecciones y consulta su progreso/XP.
  * **Docente:** Crea/gestiona aulas, visualiza analíticas del grupo y recibe alertas de conceptos con alto índice de error.

### Módulo 2: Micro-Aprendizaje y Gamificación (`learning`)
* **Ruta de Módulos (Estilo Duolingo):** Mapa vertical progresivo de unidades temáticas de SABD.
* **Micro-lecciones:** Sesiones cortas de 5 a 7 ejercicios (duración estimada: 3 a 5 minutos) para evitar la fatiga cognitiva.
* **Tipos de ejercicios interactivos en Flutter:**
  1. `multiple_choice`: Selección múltiple conceptual.
  2. `true_false`: Verdadero o falso rápido (ideal para reglas de normalización y ACID).
  3. `fill_sql`: Completar cláusulas SQL faltantes (ej. `SELECT * ___ usuarios WHERE ...`).
  4. `order_query`: Ordenar bloques/chips para construir una consulta SQL válida.
* **Mecánicas de Gamificación:**
  * Puntos de experiencia (**XP**) otorgados según dificultad y precisión.
  * **Racha diaria (Streak)** para fomentar constancia.
  * **Feedback pedagógico inmediato** tras cada respuesta (explicando *por qué* es correcta o incorrecta).
  * **Insignias/Logros** al completar módulos o mantener rachas.

### Módulo 3: Algoritmo Adaptativo — Motor IA (`adaptive_engine`)
El motor adaptativo no requiere una red neuronal opaca ni costosa; utiliza un **Modelo de Dificultad Dinámica Basado en Dominio (Adaptación de BKT / Escala Elo simplificada)** completamente auditable, matemático y defendible ante el profesor.

#### Variables de Entrada por Intento
* $a \in \{0, 1\}$: Resultado del intento ($1$ = acierto, $0$ = error).
* $t$: Tiempo de respuesta en milisegundos comparado contra el tiempo esperado del ejercicio ($t_{\text{ref}}$).
* $d \in \{1, 2, 3, 4, 5\}$: Nivel de dificultad del ejercicio respondido.

#### Regla de Actualización del Nivel de Dominio ($M$)
Cada estudiante posee un puntaje de dominio por módulo $M \in [0, 100]$ (inicia en $M = 20$ o mediante un diagnóstico corto de 3 preguntas):

$$M_{\text{nuevo}} = \text{clamp}\left(M_{\text{actual}} + \Delta M,\; 0,\; 100\right)$$

Donde el ajuste $\Delta M$ se calcula según desempeño y fluidez:
* **Acierto rápido** ($a = 1$ y $t \le t_{\text{ref}}$): $\Delta M = +(6 + d)$
* **Acierto lento** ($a = 1$ y $t > t_{\text{ref}}$): $\Delta M = +(3 + 0.5 \cdot d)$
* **Error** ($a = 0$): $\Delta M = -(8 - d)$ *(fallar un ejercicio básico penaliza más el dominio que fallar uno experto)*.

#### Selección de Siguiente Dificultad ($d_{\text{sig}}$) y Rutas Personalizadas
* $M < 25 \Rightarrow d_{\text{sig}} = 1$ (Nivel Básico + sugerencia de micro-repaso teórico).
* $25 \le M < 45 \Rightarrow d_{\text{sig}} = 2$ (Nivel Elemental).
* $45 \le M < 65 \Rightarrow d_{\text{sig}} = 3$ (Nivel Intermedio).
* $65 \le M < 85 \Rightarrow d_{\text{sig}} = 4$ (Nivel Avanzado).
* $M \ge 85 \Rightarrow d_{\text{sig}} = 5$ (Nivel Experto / Reto).
* **Regla de Seguridad contra Frustración:** Si el estudiante comete $2$ errores consecutivos, el motor reduce automáticamente $d_{\text{sig}}$ en $1$ (mínimo $1$) e inyecta un ejercicio de refuerzo del mismo subtema.

### Módulo 4: Reportes y Analítica Docente (`analytics`)
* **Panel del Aula:** KPIs principales (promedio de dominio del salón, estudiantes activos hoy, lecciones completadas).
* **Radar de Deficiencias Grupales:** Ranking de los módulos y lecciones con mayor porcentaje de error en el aula (indica al profesor qué tema debe reforzar en clase presencial).
* **Semáforo de Estudiantes:**
  * **Rojo (Rezago):** Dominio promedio $< 40\%$ o tasa de error reciente $> 50\%$.
  * **Amarillo (En progreso):** Dominio entre $40\%$ y $75\%$.
  * **Verde (Avanzado):** Dominio $> 75\%$.

---

## 4. Plan Curricular del MVP (Contenido Cerrado: Materia SABD)

Para demostrar el sistema de forma convincente, la base de datos incluirá inicialmente **5 módulos progresivos** propios de la materia:

| Orden | Módulo | Lecciones Ejemplo | Dificultades |
| :---: | :--- | :--- | :---: |
| **1** | **Fundamentos de BD y SGBD** | Datos vs. Información, Arquitectura SGBD, Modelos de BD | 1 a 3 |
| **2** | **Modelo Entidad-Relación (E-R)** | Entidades y Atributos, Claves (PK/FK), Cardinalidades (`1:1`, `1:N`, `N:M`) | 1 a 4 |
| **3** | **Normalización Relacional** | 1FN (Atomicidad), 2FN (Dependencia Parcial), 3FN (Transitividad) | 2 a 5 |
| **4** | **SQL Esencial (DDL y DML)** | `CREATE TABLE`, `INSERT`, `UPDATE`, `DELETE`, `SELECT` + `WHERE` | 1 a 4 |
| **5** | **Consultas Avanzadas e Integridad** | `INNER/LEFT JOIN`, `GROUP BY/HAVING`, Transacciones `ACID`, Índices | 2 a 5 |

---

## 5. Estructura de Carpetas en Flutter (Clean Architecture Feature-First)

Los agentes de código deben respetar estrictamente esta organización bajo `lib/`:

```text
lib/
├── main.dart
├── app.dart                         # MaterialApp.router + Theme + ProviderScope
├── core/
│   ├── config/                      # Variables de entorno, cliente Supabase/API
│   ├── router/                      # Configuración de GoRouter y guards de rol
│   ├── theme/                       # Material 3, paleta gamificada, tipografía
│   ├── errors/                      # Failures y Exceptions tipadas
│   └── utils/                       # Formateadores de tiempo, constantes
└── features/
    ├── auth/                        # Módulo 1: Login, Registro, Roles, Aulas
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── learning/                    # Módulo 2: Mapa Duolingo, Lecciones, Gamificación
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │       ├── screens/             # PathScreen, LessonRunnerScreen, SummaryScreen
    │       └── widgets/             # ExerciseCard, XpBadge, StreakCounter, SqlChipBuilder
    ├── adaptive_engine/             # Módulo 3: Cálculo de dominio y selección adaptativa
    │   ├── domain/
    │   │   └── adaptive_calculator.dart
    │   └── data/
    └── analytics/                   # Módulo 4: Dashboard Docente y Alertas
        ├── data/
        ├── domain/
        └── presentation/
```

---

## 6. Reglas de Codificación y Guías para Agentes de Desarrollo

1. **Null-Safety Estricto:** Prohibido usar el operador `!` sin validación previa. Usar modelos inmutables (recomendado `freezed` o clases `const` con `copyWith`).
2. **Separación de Responsabilidades:**
   * Los widgets en `presentation/` **nunca** realizan consultas SQL ni llaman directamente a la base de datos.
   * Toda regla del algoritmo adaptativo vive en `features/adaptive_engine/domain/` como funciones puras fáciles de probar con `flutter_test`.
3. **Medición Precisa de Tiempo:** Cada ejercicio en `LessonRunnerScreen` debe iniciar un `Stopwatch` al renderizarse y detenerlo al pulsar "Comprobar" para enviar `tiempo_respuesta_ms` exacto a la base de datos.
4. **UI/UX Estilo Micro-Aprendizaje:**
   * Diseño limpio en Material 3 con alto contraste y retroalimentación táctil/visual clara (verde para acierto + explicación, rojo suave para error + pista pedagógica).
   * Toda pantalla debe ser **responsiva** (funcional tanto en teléfonos Android como en navegador Web de escritorio para el panel docente).
5. **Integridad de Datos:** Nunca guardar resultados de ejercicios sin registrar el registro completo en `intentos_ejercicio` y actualizar atómicamente `progreso_modulo_usuario` y `gamificacion_usuario`.
6. **Pruebas Obligatorias:** Todo cambio en `adaptive_calculator.dart` debe incluir pruebas unitarias verificando: subida de dificultad tras aciertos, bajada tras errores consecutivos y límites de `clamp(0, 100)`.

---

## 7. Planificación Ágil (Scrum — 4 Sprints)

Alineado a la *Delimitación Teórica* del proyecto:

* **Sprint 1 (Base y Módulo 1):** Modelado final PostgreSQL, despliegue del esquema DDL, configuración de Flutter + GoRouter + Riverpod, registro/login por roles e inscripción a aulas.
* **Sprint 2 (Módulo 2 — Core Duolingo):** Carga de datos semilla (5 módulos de SABD, $\ge 50$ ejercicios), pantalla de ruta de módulos, motor de ejecución de ejercicios, feedback inmediato y sistema de XP/rachas.
* **Sprint 3 (Módulo 3 — Motor Adaptativo):** Integración de `adaptive_calculator.dart`, registro de tiempos de respuesta en `intentos_ejercicio`, selección dinámica de dificultad y rutas de refuerzo automático.
* **Sprint 4 (Módulo 4 — Analítica Docente y Defensa):** Panel de profesor con gráficas (ej. `fl_chart`), vistas SQL de deficiencias grupales, pruebas de carga simuladas y preparación de demo en vivo.