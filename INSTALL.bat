@echo off
chcp 65001 > nul
title AIT-QB - Instalador Interactivo
color 0B

echo.
echo ═══════════════════════════════════════════════════════════
echo   AIT-QB - Instalador Interactivo
echo   Advanced Intelligence Technology
echo ═══════════════════════════════════════════════════════════
echo.
echo Este script te guiará en la instalación de AIT-QB
echo.
echo OPCIONES:
echo.
echo   1. Instalación Completa (Recomendado)
echo   2. Instalación Personalizada
echo   3. Solo Base de Datos
echo   4. Verificar Instalación
echo   5. Modo Seguro
echo   0. Salir
echo.

set /p choice="Selecciona una opción (0-5): "

if "%choice%"=="0" goto end
if "%choice%"=="1" goto full
if "%choice%"=="2" goto custom
if "%choice%"=="3" goto database
if "%choice%"=="4" goto verify
if "%choice%"=="5" goto safemode

echo Opción no válida
pause
goto end

:full
echo.
echo ═══════════════════════════════════════════════════════════
echo   INSTALACIÓN COMPLETA
echo ═══════════════════════════════════════════════════════════
echo.
echo Esto instalará:
echo   ✓ Base de datos completa
echo   ✓ Todos los engines recomendados
echo   ✓ Jobs de emergencia (Police, EMS, Mechanic)
echo   ✓ Todos los módulos del cliente
echo   ✓ Configuración por defecto
echo.
pause

REM Copiar configuración predeterminada
copy /Y "installer\configs\full.json" "installer\startup_config.json" > nul

REM Importar base de datos (requiere MySQL en PATH)
echo.
echo Instalando base de datos...
set /p dbuser="Usuario MySQL (default: root): "
if "%dbuser%"=="" set dbuser=root

set /p dbpass="Contraseña MySQL: "
set /p dbname="Nombre de la base de datos (default: ait-qb): "
if "%dbname%"=="" set dbname=ait-qb

mysql -u %dbuser% -p%dbpass% %dbname% < install.sql

if %errorlevel% equ 0 (
    echo ✓ Base de datos instalada correctamente
) else (
    echo ✗ Error al instalar la base de datos
    echo   Asegúrate de que MySQL está instalado y configurado
    pause
    goto end
)

echo.
echo ✓ Instalación completa finalizada
echo.
echo PRÓXIMOS PASOS:
echo   1. Configura oxmysql en tu server.cfg
echo   2. Añade: ensure ait-qb
echo   3. Reinicia tu servidor
echo.
pause
goto end

:custom
echo.
echo ═══════════════════════════════════════════════════════════
echo   INSTALACIÓN PERSONALIZADA
echo ═══════════════════════════════════════════════════════════
echo.
echo Por favor, edita manualmente el archivo:
echo   installer/startup_config.json
echo.
echo Activa/desactiva los módulos que desees y guarda el archivo.
echo.
echo Luego reinicia el servidor.
echo.
pause
notepad installer\startup_config.json
goto end

:database
echo.
echo ═══════════════════════════════════════════════════════════
echo   INSTALACIÓN DE BASE DE DATOS
echo ═══════════════════════════════════════════════════════════
echo.

set /p dbuser="Usuario MySQL (default: root): "
if "%dbuser%"=="" set dbuser=root

set /p dbpass="Contraseña MySQL: "
set /p dbname="Nombre de la base de datos (default: ait-qb): "
if "%dbname%"=="" set dbname=ait-qb

echo.
echo Instalando base de datos en: %dbname%
echo.

mysql -u %dbuser% -p%dbpass% %dbname% < install.sql

if %errorlevel% equ 0 (
    echo.
    echo ✓ Base de datos instalada correctamente
) else (
    echo.
    echo ✗ Error al instalar la base de datos
)
echo.
pause
goto end

:verify
echo.
echo ═══════════════════════════════════════════════════════════
echo   VERIFICACIÓN DE INSTALACIÓN
echo ═══════════════════════════════════════════════════════════
echo.

set errors=0

echo Verificando archivos críticos...
echo.

if exist "fxmanifest.lua" (
    echo ✓ fxmanifest.lua
) else (
    echo ✗ fxmanifest.lua NO ENCONTRADO
    set /a errors+=1
)

if exist "server\main.lua" (
    echo ✓ server\main.lua
) else (
    echo ✗ server\main.lua NO ENCONTRADO
    set /a errors+=1
)

if exist "client\main.lua" (
    echo ✓ client\main.lua
) else (
    echo ✗ client\main.lua NO ENCONTRADO
    set /a errors+=1
)

if exist "install.sql" (
    echo ✓ install.sql
) else (
    echo ✗ install.sql NO ENCONTRADO
    set /a errors+=1
)

if exist "core\bootstrap.lua" (
    echo ✓ core\bootstrap.lua
) else (
    echo ✗ core\bootstrap.lua NO ENCONTRADO
    set /a errors+=1
)

echo.
if %errors% equ 0 (
    echo ✓ VERIFICACIÓN EXITOSA
    echo   Todos los archivos críticos están presentes
) else (
    echo ✗ ERRORES ENCONTRADOS: %errors%
    echo   Reinstala los componentes faltantes
)
echo.
pause
goto end

:safemode
echo.
echo ═══════════════════════════════════════════════════════════
echo   MODO SEGURO
echo ═══════════════════════════════════════════════════════════
echo.
echo El modo seguro carga solo los componentes esenciales:
echo   ✓ Core Engine
echo   ✓ Configuración básica
echo   ✓ Base de datos
echo   ✓ Economy e Inventory
echo   ✓ Cliente básico
echo.
echo Usa esto si tu servidor crashea al iniciar.
echo.

REM Crear config de modo seguro
echo { > installer\startup_config.json
echo   "mode": "safe", >> installer\startup_config.json
echo   "engines": { >> installer\startup_config.json
echo     "economy": true, >> installer\startup_config.json
echo     "inventory": true >> installer\startup_config.json
echo   }, >> installer\startup_config.json
echo   "jobs": {}, >> installer\startup_config.json
echo   "modules": { >> installer\startup_config.json
echo     "hud": true >> installer\startup_config.json
echo   } >> installer\startup_config.json
echo } >> installer\startup_config.json

echo ✓ Modo seguro activado
echo.
echo Configuración guardada en: installer\startup_config.json
echo.
echo Ahora reinicia tu servidor.
echo.
pause
goto end

:end
exit
