@echo off
REM Install CPU-only llama.cpp build for compatibility testing
REM Falls back to pure CPU when HIP/GPU has kernel compatibility issues
setlocal EnableDelayedExpansion

echo.
echo [INFO] Installing CPU-only llama.cpp build
echo [INFO] Fallback solution for HIP kernel compatibility issues
echo [INFO] This will allow testing without GPU acceleration

REM Check if we're in the right directory
if not exist "%~dp0hip-llama-env" (
    echo [ERROR] Virtual environment not found
    echo Please run install-hip-llama.bat first to create the environment
    exit /b 1
)

REM CPU build download URL (latest stable release)
set DOWNLOAD_URL=https://github.com/ggerganov/llama.cpp/releases/download/b4147/llama-b4147-bin-win-cpu-x64.zip
set TEMP_DIR=%TEMP%\llama-cpu
set ZIP_FILE=%TEMP_DIR%\llama-cpu.zip
set CPU_BIN_DIR=%~dp0cpu-bin

echo.
echo Downloading CPU-only llama.cpp build...
echo Source: https://github.com/ggerganov/llama.cpp/releases
echo Target: %CPU_BIN_DIR%

REM Create directories
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if exist "%CPU_BIN_DIR%" (
    echo [INFO] Backing up existing CPU bin directory...
    move "%CPU_BIN_DIR%" "%CPU_BIN_DIR%.backup.%DATE:~-4%%DATE:~4,2%%DATE:~7,2%" >nul 2>&1
)

REM Download CPU build
echo [INFO] Downloading llama.cpp CPU build...
powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing -TimeoutSec 300 } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Download failed
    echo Please manually download: %DOWNLOAD_URL%
    echo Save as: %ZIP_FILE%
    exit /b 1
)

echo [OK] Downloaded: %ZIP_FILE%

REM Extract CPU build
echo [INFO] Extracting CPU build...
powershell -Command "try { Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to extract ZIP file
    exit /b 1
)

REM Find and move the extracted files
for /d %%d in ("%TEMP_DIR%\*") do (
    if exist "%%d\llama-server.exe" (
        echo [INFO] Moving CPU build to: %CPU_BIN_DIR%
        move "%%d" "%CPU_BIN_DIR%" >nul 2>&1
        goto found_cpu_build
    )
)

echo [ERROR] Could not locate llama-server.exe in extracted files
exit /b 1

:found_cpu_build
echo [OK] CPU build installed: %CPU_BIN_DIR%

REM Verify installation
if exist "%CPU_BIN_DIR%\llama-server.exe" (
    echo [OK] llama-server.exe found: %CPU_BIN_DIR%\llama-server.exe
    "%CPU_BIN_DIR%\llama-server.exe" --version 2>nul
) else (
    echo [ERROR] llama-server.exe not found after installation
    exit /b 1
)

REM Clean up
echo [INFO] Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo [INFO] CPU-only llama.cpp installation complete!
echo [INFO] Use start-mistral-small-3.2-24b-cpu-only.bat to test CPU-only mode
echo.

pause
