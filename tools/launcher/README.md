# Lanzador de Tutor Adaptativo SABD

Aplicación de escritorio para Windows que inicia todo el proyecto sin Docker:

- **PostgreSQL local:** la primera vez crea el almacenamiento en `database/pgdata`, crea la base `tutor_adaptativo_sabd` y carga `01_schema.sql`, `02_views.sql` y `03_seed.sql`.
- **Servidor de la aplicación:** sirve la versión web compilada (`app/build/web`) en `http://localhost:8080` y abre el navegador.

## Uso

1. Ejecuta `TutorAdaptativoSABD.exe` (dentro de `tools/launcher/dist/`).
2. Pulsa **Iniciar todo**.
3. Para cerrar, pulsa **Detener todo** o cierra la ventana (te preguntará si detener los servicios).

| Botón | Qué hace |
| --- | --- |
| Iniciar todo | Arranca PostgreSQL, prepara la base si hace falta y levanta el servidor web |
| Detener todo | Detiene el servidor web y PostgreSQL |
| Abrir en navegador | Abre `http://localhost:8080` |
| Recompilar app | Ejecuta `flutter build web --release` dentro de `app/` |

## Requisitos

- **PostgreSQL 16** (binarios `bin` con `pg_ctl`, `initdb`, `psql` y `createdb`). Se busca en este orden: `pg_bin` de `config.json`, la variable `PGBIN`, `%LOCALAPPDATA%\pgsql16\pgsql\bin` y `C:\Program Files\PostgreSQL\*\bin`.
- **Flutter** solo si quieres usar "Recompilar app". Se busca en `%LOCALAPPDATA%\flutter-sdk\flutter\bin` o en el PATH.

## Configuración opcional

Copia `config.example.json` como `config.json` junto al ejecutable y ajusta lo necesario. `config.json` no se versiona.

## Generar el ejecutable

```bat
tools\launcher\build_exe.bat
```

Requiere Python 3.10 o superior con tkinter. El script instala PyInstaller y genera `dist\TutorAdaptativoSABD.exe`.

## Notas de seguridad

PostgreSQL acepta conexiones sin contraseña (`trust`) pero solo escucha en `127.0.0.1`. Es adecuado para uso local en la demostración, no para un servidor compartido.
