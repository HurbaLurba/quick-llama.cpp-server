@echo off
REM LLaMA.cpp HIP AMD GPU Installer for Windows
REM Downloads and sets up llama.cpp with HIP support for AMD GPUs

setlocal enabledelayedexpansion

echo LLaMA.cpp HIP AMD GPU Installer
echo ====================================
echo Target: AMD 8945HS with Radeon 780M integrated graphics
echo Backend: HIP (AMD's CUDA equivalent for Windows)

REM Configuration
set LLAMA_VERSION=b6423
set DOWNLOAD_URL=https://github.com/ggml-org/llama.cpp/releases/download/%LLAMA_VERSION%/llama-%LLAMA_VERSION%-bin-win-hip-radeon-x64.zip
set ZIP_FILE=llama-%LLAMA_VERSION%-bin-win-hip-radeon-x64.zip
set EXTRACT_DIR=llama-hip-extracted
set VENV_DIR=hip-llama-env

echo.
echo Downloading llama.cpp HIP build...
echo URL: %DOWNLOAD_URL%

REM Check if we already have the executable
if exist "llama-server.exe" (
    echo [OK] llama-server.exe already exists
    echo Do you want to re-download? (y/n)
    set /p choice="> "
    if /i "!choice!" neq "y" goto :check_deps
)

REM Create temp directory
if not exist "temp" mkdir temp
cd temp

REM Download using PowerShell (more reliable than curl on Windows)
echo Downloading... (this may take a few minutes)
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%'}"

if not exist "%ZIP_FILE%" (
    echo [ERROR] Download failed!
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)

echo [OK] Download completed: %ZIP_FILE%

REM Extract using PowerShell
echo Extracting files...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

if not exist "%EXTRACT_DIR%" (
    echo [ERROR] Extraction failed!
    pause
    exit /b 1
)

echo [OK] Extraction completed

REM Find and copy the server executable
echo Locating llama-server.exe...
for /r "%EXTRACT_DIR%" %%f in (llama-server.exe) do (
    echo Found: %%f
    copy "%%f" "..\llama-server.exe" >nul
    if exist "..\llama-server.exe" (
        echo [OK] llama-server.exe copied successfully
        goto :copy_success
    )
)

echo [ERROR] Could not find llama-server.exe in the extracted files
echo Available files:
dir "%EXTRACT_DIR%" /s /b | findstr ".exe"
pause
exit /b 1

:copy_success
REM Clean up temp files
cd ..
echo Cleaning up temporary files...
rmdir /s /q temp 2>nul

:check_deps
echo.
echo Checking dependencies and system setup...

REM Check AMD drivers using PowerShell (modern method)
echo.
echo AMD Graphics Detection:
powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -match 'AMD|Radeon'} | Select-Object Name" >nul 2>&1
if errorlevel 1 (
    echo [WARNING] No AMD graphics detected - please install AMD Adrenalin drivers
) else (
    echo [OK] AMD graphics hardware detected:
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -match 'AMD|Radeon'} | ForEach-Object {Write-Host '   ' $_.Name}"
)

REM Check HIP runtime (if available)
echo.
echo HIP Runtime Check:
where hipconfig >nul 2>&1
if errorlevel 1 (
    echo [INFO] HIP runtime not found in PATH
    echo This is OK - llama-server.exe includes HIP runtime
) else (
    echo [OK] HIP runtime found in system PATH
    hipconfig --version 2>nul
)

REM Check Python
echo.
echo Python Check:
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found! Please install Python 3.8+
    echo Download from: https://www.python.org/downloads/
    set PYTHON_MISSING=1
    goto :skip_venv
) else (
    echo [OK] Python found:
    python --version
)

REM Create virtual environment
echo.
echo Creating Python virtual environment: %VENV_DIR%
if exist "%VENV_DIR%" (
    echo [INFO] Virtual environment already exists
) else (
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        set VENV_FAILED=1
        goto :skip_venv
    )
    echo [OK] Virtual environment created successfully
)

REM Activate virtual environment and install packages
echo Activating virtual environment...
call "%VENV_DIR%\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    set VENV_FAILED=1
    goto :skip_venv
)

echo [OK] Virtual environment activated
echo Installing huggingface-hub in virtual environment...
pip install huggingface-hub
if errorlevel 1 (
    echo [ERROR] Failed to install huggingface-hub in venv
    set HF_MISSING=1
) else (
    echo [OK] huggingface-hub installed successfully in venv
)

goto :test_executable

:skip_venv
echo [WARNING] Skipping virtual environment setup due to errors

:test_executable
REM Test the executable
echo.
echo Testing llama-server.exe...
if exist "llama-server.exe" (
    echo [OK] llama-server.exe found
    echo Testing HIP backend availability...
    llama-server.exe --help | findstr /i "hip" >nul
    if errorlevel 1 (
        echo [INFO] HIP backend not mentioned in help (may still work)
    ) else (
        echo [OK] HIP backend confirmed in help text
    )
) else (
    echo [ERROR] llama-server.exe not found after installation
    exit /b 1
)

REM Create cache directory
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
if not exist "%LLAMA_CACHE%\models" mkdir "%LLAMA_CACHE%\models"
if not exist "%LLAMA_CACHE%\mmproj" mkdir "%LLAMA_CACHE%\mmproj"
echo [OK] Cache directory ready: %LLAMA_CACHE%

REM Create activation script
echo.
echo Creating activation script...
echo @echo off > activate-hip-env.bat
echo echo Activating HIP LLaMA environment... >> activate-hip-env.bat
if not defined VENV_FAILED (
    echo call "%VENV_DIR%\Scripts\activate.bat" >> activate-hip-env.bat
    echo if errorlevel 1 echo [ERROR] Failed to activate virtual environment >> activate-hip-env.bat
) else (
    echo echo [WARNING] Virtual environment not available >> activate-hip-env.bat
)
echo [OK] Created activate-hip-env.bat

echo.
echo Installation Complete!
echo ========================
echo.
echo Ready to run:
echo   start-mistral-small-3.2-24b-hip-amd.bat
echo   start-gemma3-27b-it-abliterated-hip-amd.bat
echo.
echo HIP Backend Notes:
echo   - HIP is AMD's CUDA equivalent for Windows
echo   - Should provide much better performance than Vulkan
echo   - Optimized specifically for AMD Radeon graphics
echo.
echo Virtual Environment:
if not defined VENV_FAILED (
    echo   [OK] Created: %VENV_DIR%
    echo   - Use activate-hip-env.bat to activate manually
    echo   - Model scripts will auto-activate the environment
) else (
    echo   [WARNING] Virtual environment setup failed
)
echo.
if defined PYTHON_MISSING (
    echo [WARNING] Python installation required for model downloads
)
if defined HF_MISSING (
    echo [WARNING] huggingface-hub installation failed - may need manual install
)
echo.
pause
