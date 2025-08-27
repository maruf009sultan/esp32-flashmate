@echo off
title ESP32 Firmware Backup / Restore Tool
setlocal enabledelayedexpansion

:: Ensure esptool is installed
where esptool >nul 2>nul
if errorlevel 1 (
    echo [ERROR] esptool not found. Please install with:
    echo   pip install esptool
    pause
    exit /b
)

echo =========================================
echo   ESP32 Firmware Backup / Restore Tool
echo =========================================
echo.

:: Show available COM ports (raw output)
echo [INFO] Available serial ports:
mode
echo.

:: Ask user for COM port
set /p COMPORT=Enter COM port (e.g. COM6 or COM7): 

echo.
echo [INFO] Reading chip information on %COMPORT% ...
esptool --port %COMPORT% flash-id
if errorlevel 1 (
    echo [ERROR] Could not connect to ESP32 on %COMPORT%.
    pause
    exit /b
)

:: Determine flash size dynamically (grab the last word)
set flashsize=4MB
for /f "tokens=*" %%S in ('esptool --port %COMPORT% flash-id ^| findstr "Detected flash size"') do (
    for %%T in (%%S) do set last=%%T
    set flashsize=!last!
)

if "%flashsize%"=="4MB" set sizehex=0x400000
if "%flashsize%"=="8MB" set sizehex=0x800000
if "%flashsize%"=="16MB" set sizehex=0x1000000

echo.
echo Detected flash size: %flashsize%
echo.

:: Choose backup or restore
echo Select operation:
echo   1) Backup firmware
echo   2) Restore firmware
echo.
set /p op=Enter 1 or 2: 

if "%op%"=="1" goto backup
if "%op%"=="2" goto restore
goto end

:backup
echo.
set /p namespec=Enter a name specifier for backup file: 
set filename=esp32_%namespec%_backup.bin

echo.
echo [INFO] Backing up full %flashsize% flash to %filename% ...
esptool --port %COMPORT% --baud 115200 read-flash 0 %sizehex% %filename%
echo.
echo [DONE] Backup saved as %filename%.
goto end

:restore
echo.
set /p binfile=Enter firmware filename (.bin) [or drag file here]: 

if not exist %binfile% (
    echo [ERROR] File %binfile% not found.
    pause
    exit /b
)

echo.
echo [INFO] Restoring firmware from %binfile% ...
esptool --port %COMPORT% --baud 115200 write-flash 0x0 %binfile%
echo.
echo [DONE] Firmware restored.
goto end

:end
echo.
pause
