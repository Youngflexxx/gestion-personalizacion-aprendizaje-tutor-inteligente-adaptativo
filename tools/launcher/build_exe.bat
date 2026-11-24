@echo off
rem Genera tools\launcher\dist\TutorAdaptativoSABD.exe (un solo archivo, sin consola).
cd /d "%~dp0"
python -m pip install --quiet pyinstaller || goto :error
python -m PyInstaller --noconfirm --onefile --windowed --name TutorAdaptativoSABD launcher.py || goto :error
echo.
echo Listo: %~dp0dist\TutorAdaptativoSABD.exe
exit /b 0
:error
echo Error al generar el ejecutable.
exit /b 1
