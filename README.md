# Gestión y Personalización del Aprendizaje en Aulas Multigrado o Numerosas mediante un Tutor Inteligente de Micro-Aprendizaje Adaptativo

> Proyecto académico de la asignatura **Sistemas Administradores de Bases de Datos (SABD)**, UNEFA — Núcleo Falcón, Extensión Punto Fijo (sección `08S-2630-D2`).

Tutor de micro-aprendizaje gamificado (estilo Duolingo) para la materia SABD. Un motor adaptativo auditable ajusta la dificultad de cada ejercicio según el dominio del estudiante, y un panel docente (Módulo 4) detecta los conceptos con más errores del aula.

- **Identificador interno:** `tutor_adaptativo_sabd` (el nombre comercial aún no está definido; se centraliza en `app/lib/core/config/app_branding.dart`).
- **Frontend:** Flutter 3.x + Dart (Android, iOS y Web desde una única base de código).
- **Estado:** Riverpod · **Navegación:** GoRouter · **Arquitectura:** Clean Architecture por funcionalidades.
- **Base de datos:** PostgreSQL 16 (esquema 3FN, restricciones CHECK/ENUM, vistas analíticas y datos semilla).

## Estructura del repositorio

```text
.
├── agents.md                  # Especificación canónica para desarrolladores y agentes
├── docs/
│   ├── agents.md              # Copia de la especificación dentro de docs/
│   └── modelo_base_datos_sabd.md
├── database/
│   ├── 01_schema.sql          # Tablas, ENUM/CHECK, PK/FK e índices
│   ├── 02_views.sql           # Vistas analíticas para el docente
│   ├── 03_seed.sql            # 1 docente, 2 estudiantes, Módulo 1 con 3 lecciones y 15 ejercicios
│   ├── docker-compose.yml     # Levanta PostgreSQL y ejecuta los scripts automáticamente
│   └── .env.example           # Variables de entorno sin secretos
└── app/                       # Aplicación Flutter (paquete tutor_adaptativo_sabd)
    ├── lib/
    │   ├── core/              # Configuración, router, tema, widgets compartidos
    │   └── features/
    │       ├── auth/          # Selector de perfil de prueba (sin autenticación)
    │       ├── learning/      # Ruta, lecciones, resumen y gamificación
    │       └── adaptive_engine/ # Fórmulas puras del Módulo 3 y selección de ejercicios
    └── test/                  # Pruebas unitarias y de widget
```

## Inicio rápido (lanzador de escritorio, sin Docker)

1. Ejecuta `tools\launcher\dist\TutorAdaptativoSABD.exe`.
2. Pulsa **Iniciar todo**: arranca PostgreSQL, crea la base con sus scripts la primera vez, levanta la aplicación y abre el navegador en `http://localhost:8080`.
3. Pulsa **Detener todo** al terminar.

Detalles, requisitos y cómo generar el ejecutable en [`tools/launcher/README.md`](tools/launcher/README.md).

Docker sigue disponible en `database/docker-compose.yml` como alternativa opcional.
## Aplicación Flutter

Requisitos: Flutter SDK 3.27 o superior (probado con Flutter 3.50.1 / Dart 3.14).

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome          # Web
flutter run                    # Android/iOS/escritorio, según dispositivo disponible
```

Los datos de la aplicación provienen de un repositorio en memoria que replica exactamente `database/03_seed.sql`. La interfaz `LearningRepository` permite conectar una API REST o Supabase/PostgreSQL sin modificar las pantallas (cambiar la implementación en `learningRepositoryProvider`).

## Motor adaptativo (Módulo 3)

Fórmulas implementadas literalmente en `app/lib/features/adaptive_engine/domain/adaptive_calculator.dart`:

| Caso | Ajuste del dominio M |
| --- | --- |
| Acierto rápido (t ≤ t_ref) | +(6 + d) |
| Acierto lento (t > t_ref) | +(3 + 0.5·d) |
| Error | −(8 − d) |

`M_nuevo = clamp(M + ΔM, 0, 100)`. Umbrales de dificultad: M < 25 → 1; < 45 → 2; < 65 → 3; < 85 → 4; ≥ 85 → 5. Dos errores consecutivos reducen la dificultad objetivo en 1 (mínimo 1) y activan un ejercicio de refuerzo.

Las pruebas en `app/test/features/adaptive_engine/` verifican la subida de dificultad tras aciertos, la bajada tras errores consecutivos y los límites `clamp(0, 100)`.

## Convenciones

- Commits con [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/): `feat(db):`, `feat(app):`, `chore:`, `test:`, `docs:`.
- Ningún secreto en el repositorio. `.env` y llaves están excluidos por `.gitignore`.
- La lógica adaptativa vive en funciones puras del dominio; los widgets no contienen reglas de negocio.

## Licencia

Uso académico. Pendiente de definir por los autores.
