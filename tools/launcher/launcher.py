"""Lanzador de escritorio de Tutor Adaptativo SABD (sin Docker).

Inicia PostgreSQL local (creando la base y cargando los scripts la primera vez)
y sirve la aplicación Flutter compilada para web. Todo se controla desde una
ventana con botones de inicio y parada.
"""

import json
import os
import queue
import shutil
import socket
import subprocess
import sys
import threading
import tkinter as tk
import webbrowser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from tkinter import messagebox, scrolledtext

APP_TITLE = "Tutor Adaptativo SABD - Lanzador"
DB_NAME = "tutor_adaptativo_sabd"
DB_USER = "postgres"
DEFAULT_PG_PORT = 55432
DEFAULT_WEB_PORT = 8080
SCRIPTS = ["01_schema.sql", "02_views.sql", "03_seed.sql"]
NO_WINDOW = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0


def exe(name: str) -> str:
    return f"{name}.exe" if os.name == "nt" else name


def base_dir() -> Path:
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def find_project_root(start: Path) -> Path | None:
    for candidate in [start, *start.parents]:
        if (candidate / "app").is_dir() and (candidate / "database").is_dir():
            return candidate
    return None


def load_config() -> dict:
    cfg = {
        "pg_bin": "",
        "pg_data": "",
        "pg_port": DEFAULT_PG_PORT,
        "web_port": DEFAULT_WEB_PORT,
        "flutter_bin": "",
    }
    for path in (base_dir() / "config.json", base_dir().parent / "config.json"):
        if path.is_file():
            cfg.update(json.loads(path.read_text(encoding="utf-8")))
            break
    return cfg


def find_pg_bin(cfg: dict) -> Path | None:
    candidatos: list[Path] = []
    if cfg.get("pg_bin"):
        candidatos.append(Path(cfg["pg_bin"]))
    if os.environ.get("PGBIN"):
        candidatos.append(Path(os.environ["PGBIN"]))
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidatos.append(Path(local) / "pgsql16" / "pgsql" / "bin")
    for variable in ("ProgramFiles", "ProgramFiles(x86)"):
        raiz = os.environ.get(variable)
        if raiz:
            candidatos += sorted(Path(raiz, "PostgreSQL").glob("*/bin"), reverse=True)
    for candidato in candidatos:
        if (candidato / exe("pg_ctl")).is_file():
            return candidato
    encontrado = shutil.which(exe("pg_ctl"))
    return Path(encontrado).parent if encontrado else None


def find_flutter(cfg: dict) -> Path | None:
    candidatos: list[Path] = []
    if cfg.get("flutter_bin"):
        candidatos.append(Path(cfg["flutter_bin"]))
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidatos.append(Path(local) / "flutter-sdk" / "flutter" / "bin")
    for candidato in candidatos:
        for nombre in ("flutter.bat", "flutter"):
            if (candidato / nombre).is_file():
                return candidato / nombre
    encontrado = shutil.which("flutter")
    return Path(encontrado) if encontrado else None


def run(args: list, timeout: int = 120, cwd: Path | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [str(a) for a in args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        cwd=cwd,
        creationflags=NO_WINDOW,
    )


def check(result: subprocess.CompletedProcess, paso: str) -> None:
    if result.returncode != 0:
        detalle = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(f"{paso} falló:\n{detalle}")


def port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        return sock.connect_ex(("127.0.0.1", port)) == 0


def make_spa_handler(web_dir: Path):
    class SpaHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(web_dir), **kwargs)

        def send_head(self):
            # Rutas como /module/1 no son archivos: se entregan a index.html.
            if not Path(self.translate_path(self.path)).exists():
                self.path = "/index.html"
            return super().send_head()

        def log_message(self, format, *args):
            return

    return SpaHandler


class Services:
    """Operaciones de base de datos y servidor web, sin interfaz gráfica."""

    def __init__(self, log=print):
        self.log = log
        self.cfg = load_config()
        self.root_dir = find_project_root(base_dir()) or find_project_root(Path.cwd())
        self.pg_bin = find_pg_bin(self.cfg)
        self.web_port = int(self.cfg["web_port"])
        self.pg_port = int(self.cfg["pg_port"])
        self.server = None
        if self.root_dir is None:
            raise RuntimeError("No se encontró la carpeta del proyecto (app/ y database/).")
        self.data_dir = (
            Path(self.cfg["pg_data"]) if self.cfg.get("pg_data")
            else self.root_dir / "database" / "pgdata"
        )
        self.pg_log = self.data_dir.parent / "postgres.log"

    @property
    def web_dir(self) -> Path:
        return self.root_dir / "app" / "build" / "web"

    @property
    def url(self) -> str:
        return f"http://localhost:{self.web_port}"

    def _pg(self, nombre: str) -> Path:
        if self.pg_bin is None:
            raise RuntimeError(
                "No se encontró PostgreSQL. Instálalo o indica la carpeta 'bin' "
                "en config.json (clave pg_bin)."
            )
        return self.pg_bin / exe(nombre)

    def db_running(self) -> bool:
        if self.pg_bin is None or not (self.data_dir / "PG_VERSION").exists():
            return False
        return run([self._pg("pg_ctl"), "-D", self.data_dir, "status"]).returncode == 0

    def web_running(self) -> bool:
        return self.server is not None

    def _psql(self, args: list) -> subprocess.CompletedProcess:
        return run(
            [self._pg("psql"), "-h", "127.0.0.1", "-p", self.pg_port, "-U", DB_USER, *args],
            timeout=300,
        )

    def start_db(self) -> None:
        self._pg("pg_ctl")  # valida que PostgreSQL exista
        if not (self.data_dir / "PG_VERSION").exists():
            self.log("Primera vez: creando el almacenamiento de PostgreSQL...")
            check(
                run([
                    self._pg("initdb"), "-D", self.data_dir, "-U", DB_USER,
                    "-A", "trust", "-E", "UTF8", "--locale=C",
                ], timeout=300),
                "initdb",
            )
        if self.db_running():
            self.log(f"PostgreSQL ya está en ejecución (puerto {self.pg_port}).")
        else:
            self.log(f"Iniciando PostgreSQL en el puerto {self.pg_port}...")
            subprocess.run(
                [self._pg("pg_ctl"), "-D", self.data_dir, "-l", self.pg_log,
                 "-o", f"-p {self.pg_port}", "-w", "start"],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=180,
                creationflags=NO_WINDOW,
            )
            if not self.db_running():
                raise RuntimeError(f"PostgreSQL no arrancó. Revisa el log: {self.pg_log}")
        self._ensure_database()

    def _ensure_database(self) -> None:
        existe = self._psql([
            "-d", "postgres", "-tAc",
            f"SELECT 1 FROM pg_database WHERE datname = '{DB_NAME}'",
        ])
        check(existe, "consulta de base de datos")
        if existe.stdout.strip() == "1":
            self.log(f"La base '{DB_NAME}' ya existe.")
            return
        self.log(f"Creando la base '{DB_NAME}' y cargando los scripts...")
        check(
            run([self._pg("createdb"), "-h", "127.0.0.1", "-p", self.pg_port,
                 "-U", DB_USER, DB_NAME]),
            "createdb",
        )
        try:
            for script in SCRIPTS:
                ruta = self.root_dir / "database" / script
                check(
                    self._psql(["-d", DB_NAME, "-v", "ON_ERROR_STOP=1", "-f", ruta]),
                    f"carga de {script}",
                )
                self.log(f"  OK {script}")
        except RuntimeError:
            # Evita dejar una base a medias que luego parecería válida.
            self._psql(["-d", "postgres", "-c", f"DROP DATABASE IF EXISTS {DB_NAME}"])
            raise

    def stop_db(self) -> None:
        if not self.db_running():
            self.log("PostgreSQL ya estaba detenido.")
            return
        check(
            run([self._pg("pg_ctl"), "-D", self.data_dir, "stop", "-m", "fast", "-w"]),
            "detener PostgreSQL",
        )
        self.log("PostgreSQL detenido.")

    def start_web(self) -> None:
        if self.web_running():
            self.log(f"El servidor web ya está activo en {self.url}.")
            return
        if not (self.web_dir / "index.html").is_file():
            raise RuntimeError("Falta la app compilada (app/build/web). Usa 'Recompilar app'.")
        if port_in_use(self.web_port):
            raise RuntimeError(f"El puerto {self.web_port} ya está en uso por otro programa.")
        self.server = ThreadingHTTPServer(
            ("127.0.0.1", self.web_port), make_spa_handler(self.web_dir)
        )
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.log(f"Servidor web activo en {self.url}")

    def stop_web(self) -> None:
        if self.server is None:
            return
        self.server.shutdown()
        self.server.server_close()
        self.server = None
        self.log("Servidor web detenido.")

    def rebuild_web(self) -> None:
        flutter = find_flutter(self.cfg)
        if flutter is None:
            raise RuntimeError("No se encontró Flutter. Indica flutter_bin en config.json.")
        self.log("Compilando la app para web (puede tardar un par de minutos)...")
        resultado = run(
            [flutter, "build", "web", "--release"],
            timeout=1200,
            cwd=self.root_dir / "app",
        )
        check(resultado, "flutter build web")
        self.log("App compilada en app/build/web.")


class LauncherWindow:
    def __init__(self, root: tk.Tk, services: Services):
        self.root = root
        self.svc = services
        self.queue: queue.Queue = queue.Queue()
        self.svc.log = lambda msg: self.queue.put(("log", msg))
        self.busy = False

        root.title(APP_TITLE)
        root.geometry("720x520")
        root.minsize(620, 460)
        root.protocol("WM_DELETE_WINDOW", self.on_close)

        tk.Label(root, text="Tutor Adaptativo SABD", font=("Segoe UI", 16, "bold")).pack(pady=(14, 2))
        tk.Label(
            root,
            text="Inicia la base de datos y la aplicación con un solo clic.",
            font=("Segoe UI", 10),
        ).pack()

        estado = tk.Frame(root)
        estado.pack(pady=12)
        self.db_label = tk.Label(estado, font=("Segoe UI", 11), width=44, anchor="w")
        self.db_label.pack(anchor="w")
        self.web_label = tk.Label(estado, font=("Segoe UI", 11), width=44, anchor="w")
        self.web_label.pack(anchor="w")

        botones = tk.Frame(root)
        botones.pack()
        self.btn_iniciar = self._boton(botones, "Iniciar todo", self.iniciar, 0)
        self.btn_detener = self._boton(botones, "Detener todo", self.detener, 1)
        self.btn_abrir = self._boton(botones, "Abrir en navegador", self.abrir, 2)
        self.btn_recompilar = self._boton(botones, "Recompilar app", self.recompilar, 3)

        self.log_area = scrolledtext.ScrolledText(root, height=14, font=("Consolas", 9), state="disabled")
        self.log_area.pack(fill="both", expand=True, padx=14, pady=12)

        if self.svc.root_dir is None:
            self.append("No se encontró la carpeta del proyecto.")
        self.append(f"Proyecto: {self.svc.root_dir}")
        self.append(f"PostgreSQL: {self.svc.pg_bin or 'no encontrado'}")
        self.append(f"Puerto base de datos: {self.svc.pg_port} · Puerto web: {self.svc.web_port}")

        self._refresh_labels()
        self.root.after(150, self._poll)
        self.root.after(3000, self._tick)

    def _boton(self, parent, texto, comando, columna):
        boton = tk.Button(parent, text=texto, width=20, height=2, command=comando, font=("Segoe UI", 10))
        boton.grid(row=0, column=columna, padx=6, pady=4)
        return boton

    def append(self, texto: str) -> None:
        self.log_area.configure(state="normal")
        self.log_area.insert("end", texto + "\n")
        self.log_area.see("end")
        self.log_area.configure(state="disabled")

    def _refresh_labels(self) -> None:
        db_on = self.svc.db_running()
        web_on = self.svc.web_running()
        self.db_label.configure(
            text=f"Base de datos PostgreSQL:  {'● activa' if db_on else '○ detenida'}",
            fg="#1F9D63" if db_on else "#888888",
        )
        self.web_label.configure(
            text=f"Servidor de la aplicación:  {'● activo en ' + self.svc.url if web_on else '○ detenido'}",
            fg="#1F9D63" if web_on else "#888888",
        )

    def _set_busy(self, value: bool) -> None:
        self.busy = value
        estado = "disabled" if value else "normal"
        for boton in (self.btn_iniciar, self.btn_detener, self.btn_recompilar):
            boton.configure(state=estado)

    def _ejecutar(self, etiqueta: str, funcion) -> None:
        if self.busy:
            return
        self._set_busy(True)

        def trabajo():
            try:
                funcion()
                self.queue.put(("log", f"{etiqueta}: listo"))
            except Exception as error:  # noqa: BLE001 - se muestra al usuario
                self.queue.put(("error", f"{etiqueta}: {error}"))
            finally:
                self.queue.put(("done", None))

        threading.Thread(target=trabajo, daemon=True).start()

    def iniciar(self) -> None:
        def accion():
            self.svc.start_db()
            self.svc.start_web()
            webbrowser.open(self.svc.url)

        self._ejecutar("Iniciar", accion)

    def detener(self) -> None:
        def accion():
            self.svc.stop_web()
            self.svc.stop_db()

        self._ejecutar("Detener", accion)

    def recompilar(self) -> None:
        self._ejecutar("Recompilar", self.svc.rebuild_web)

    def abrir(self) -> None:
        if self.svc.web_running():
            webbrowser.open(self.svc.url)
        else:
            self.append("El servidor no está activo. Pulsa 'Iniciar todo' primero.")

    def _poll(self) -> None:
        while True:
            try:
                tipo, dato = self.queue.get_nowait()
            except queue.Empty:
                break
            if tipo == "log":
                self.append(dato)
            elif tipo == "error":
                self.append(f"ERROR: {dato}")
                messagebox.showerror(APP_TITLE, dato)
            elif tipo == "done":
                self._set_busy(False)
                self._refresh_labels()
        self.root.after(150, self._poll)

    def _tick(self) -> None:
        if not self.busy:
            self._refresh_labels()
        self.root.after(3000, self._tick)

    def on_close(self) -> None:
        if self.svc.web_running() or self.svc.db_running():
            respuesta = messagebox.askyesnocancel(
                APP_TITLE,
                "¿Detener el servidor y la base de datos antes de salir?\n\n"
                "Sí: detener y cerrar.  No: cerrar dejando PostgreSQL activo.  Cancelar: volver.",
            )
            if respuesta is None:
                return
            if respuesta:
                try:
                    self.svc.stop_web()
                    self.svc.stop_db()
                except Exception as error:  # noqa: BLE001
                    messagebox.showerror(APP_TITLE, f"No se pudo detener todo: {error}")
                    return
        self.root.destroy()


def main() -> None:
    try:
        services = Services(log=print)
    except RuntimeError as error:
        raiz = tk.Tk()
        raiz.withdraw()
        messagebox.showerror(APP_TITLE, str(error))
        raiz.destroy()
        sys.exit(1)
    root = tk.Tk()
    LauncherWindow(root, services)
    root.mainloop()


if __name__ == "__main__":
    main()
