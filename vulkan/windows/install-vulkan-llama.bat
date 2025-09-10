@echo off
REM Install Vulkan llama.cpp build for AMD GPU acceleration
REM Vulkan should work better than HIP for AMD integrated graphics
setlocal EnableDelayedExpansion

echo.
echo [INFO] Installing Vulkan llama.cpp build for AMD GPU acceleration
echo [INFO] Vulkan backend - better compatibility than HIP for AMD graphics
echo [INFO] Target: AMD 8945HS with Radeon 780M integrated graphics

REM Create Python virtual environment
set VENV_DIR=%~dp0vulkan-llama-env
if not exist "%VENV_DIR%" (
    echo [INFO] Creating Python virtual environment...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        echo Please ensure Python is installed and available in PATH
        exit /b 1
    )
    echo [OK] Virtual environment created: %VENV_DIR%
) else (
    echo [OK] Virtual environment already exists: %VENV_DIR%
)

REM Activate virtual environment
call "%VENV_DIR%\Scripts\activate.bat"

REM Install huggingface-hub
echo [INFO] Installing huggingface-hub...
pip install huggingface-hub --quiet
if errorlevel 1 (
    echo [ERROR] Failed to install huggingface-hub
    exit /b 1
)
echo [OK] huggingface-hub installed

REM Vulkan build download - Updated to b6432 for better optimizations
set DOWNLOAD_URL=https://github.com/ggml-org/llama.cpp/releases/download/b6432/llama-b6432-bin-win-vulkan-x64.zip
set TEMP_DIR=%TEMP%\vulkan-llama
set ZIP_FILE=%TEMP_DIR%\llama-vulkan.zip
set BIN_DIR=%~dp0bin

echo.
echo Downloading Vulkan llama.cpp build...
echo Source: %DOWNLOAD_URL%
echo Target: %BIN_DIR%

REM Create directories
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if exist "%BIN_DIR%" (
    echo [INFO] Backing up existing bin directory...
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set DATE_BACKUP=%%c%%a%%b
    move "%BIN_DIR%" "%BIN_DIR%.backup.!DATE_BACKUP!" >nul 2>&1
)

REM Download Vulkan build
echo [INFO] Downloading llama.cpp Vulkan build (b6418)...
powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Write-Host 'Downloading...'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing -TimeoutSec 600 } catch { Write-Host 'Error:' $_.Exception.Message -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Download failed
    echo Please manually download: %DOWNLOAD_URL%
    echo Save as: %ZIP_FILE%
    echo Then run this script again
    pause
    exit /b 1
)

echo [OK] Downloaded: %ZIP_FILE%

REM Extract Vulkan build
echo [INFO] Extracting Vulkan build...
powershell -Command "try { Write-Host 'Extracting...'; Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to extract ZIP file
    exit /b 1
)

REM Find and move the extracted files
set FOUND_BUILD=0
for /d %%d in ("%TEMP_DIR%\*") do (
    if exist "%%d\llama-server.exe" (
        echo [INFO] Moving Vulkan build to: %BIN_DIR%
        move "%%d" "%BIN_DIR%" >nul 2>&1
        set FOUND_BUILD=1
        goto found_vulkan_build
    )
)

REM Check if files are directly in temp dir
if exist "%TEMP_DIR%\llama-server.exe" (
    echo [INFO] Moving Vulkan build to: %BIN_DIR%
    mkdir "%BIN_DIR%" 2>nul
    move "%TEMP_DIR%\*.exe" "%BIN_DIR%\" >nul 2>&1
    move "%TEMP_DIR%\*.dll" "%BIN_DIR%\" >nul 2>&1 2>nul
    set FOUND_BUILD=1
)

:found_vulkan_build
if %FOUND_BUILD%==0 (
    echo [ERROR] Could not locate llama-server.exe in extracted files
    echo Contents of extraction directory:
    dir "%TEMP_DIR%" /s /b
    exit /b 1
)

echo [OK] Vulkan build installed: %BIN_DIR%

REM Verify installation
if exist "%BIN_DIR%\llama-server.exe" (
    echo [OK] llama-server.exe found: %BIN_DIR%\llama-server.exe
    echo [INFO] Testing Vulkan build...
    "%BIN_DIR%\llama-server.exe" --version
    if errorlevel 1 (
        echo [WARNING] Version check failed, but binary exists
    )
) else (
    echo [ERROR] llama-server.exe not found after installation
    exit /b 1
)

REM Clean up
echo [INFO] Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo [SUCCESS] Vulkan llama.cpp installation complete!
echo [INFO] Virtual environment: %VENV_DIR%
echo [INFO] Binary location: %BIN_DIR%\llama-server.exe
echo [INFO] Backend: Vulkan (AMD GPU acceleration)
echo.
echo Next steps:
echo 1. Use start-mistral-small-3.2-24b-vulkan.bat to run the server
echo 2. Vulkan should provide better AMD GPU compatibility than HIP
echo.

pause
