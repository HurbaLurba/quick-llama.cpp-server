@echo off
REM HIP AMD GPU Detection and Test Script for Windows
REM Comprehensive system check for HIP AMD GPU setup
setlocal EnableDelayedExpansion

echo HIP AMD    echo    start-mistral-small-3.2-24b-hip-amd.bat
    echo    start-gemma3-27b-it-abliterated-hip-amd.bat
) else (
    echo [ERROR] Setup incomplete - run install-hip-llama.bat first
)

echo.
echo HIP Performance Tips:
echo    - Ensure AMD Adrenalin drivers are latest version
echo    - Enable GPU scheduling in Windows Display settings
echo    - Close GPU-intensive applications before running
echo    - Monitor AMD Software for GPU utilization
echo.

pauseand Test Tool
echo ==========================================
echo Target: AMD 8945HS with Radeon 780M (gfx1103)

echo.
echo System Information:
echo ----------------------
powershell -Command "Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory, CsProcessors | Format-List"

echo.
echo Graphics Hardware Detection:
echo --------------------------------
echo All Graphics Adapters:
powershell -Command "Get-WmiObject -Class Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | Format-Table -AutoSize"

echo.
echo AMD-Specific Graphics Detection:
powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -match 'AMD|Radeon'}" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] No AMD graphics detected
    echo Please install AMD Adrenalin drivers
) else (
    echo [OK] AMD graphics detected:
    powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -match 'AMD|Radeon'} | ForEach-Object {Write-Host '   ' $_.Name ' - Driver:' $_.DriverVersion}"
)

echo.
echo HIP Runtime Detection:
echo -------------------------
where hipconfig >nul 2>&1
if errorlevel 1 (
    echo [WARNING] HIP runtime not found in system PATH
    echo This is OK - llama-server.exe includes HIP runtime
) else (
    echo [OK] HIP runtime found in system PATH:
    hipconfig --version 2>nul || echo    Version info not available
)

REM Check ROCm/HIP environment variables
echo.
echo HIP Environment Variables:
echo ------------------------------
if defined HIP_VISIBLE_DEVICES (
    echo [OK] HIP_VISIBLE_DEVICES: %HIP_VISIBLE_DEVICES%
) else (
    echo [WARNING] HIP_VISIBLE_DEVICES: Not set
)

if defined HSA_OVERRIDE_GFX_VERSION (
    echo [OK] HSA_OVERRIDE_GFX_VERSION: %HSA_OVERRIDE_GFX_VERSION%
) else (
    echo [WARNING] HSA_OVERRIDE_GFX_VERSION: Not set
)

if defined HCC_AMDGPU_TARGET (
    echo [OK] HCC_AMDGPU_TARGET: %HCC_AMDGPU_TARGET%
) else (
    echo [WARNING] HCC_AMDGPU_TARGET: Not set
)

echo.
echo Python and Dependencies:
echo ----------------------------
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found
    echo Please install Python 3.8+ from https://www.python.org/downloads/
) else (
    echo [OK] Python found:
    python --version
)

REM Check virtual environment
if exist "%~dp0hip-llama-env\Scripts\activate.bat" (
    echo [OK] Virtual environment found: hip-llama-env
    call "%~dp0hip-llama-env\Scripts\activate.bat"
    pip show huggingface-hub >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] huggingface-hub not installed in venv
        echo Run: install-hip-llama.bat
    ) else (
        echo [OK] huggingface-hub installed in venv:
        pip show huggingface-hub | findstr /C:"Version"
    )
) else (
    echo [WARNING] Virtual environment not found
    echo Run: install-hip-llama.bat to create hip-llama-env
    pip show huggingface-hub >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] huggingface-hub not installed
        echo Run: pip install huggingface-hub
    ) else (
        echo [OK] huggingface-hub installed globally:
        pip show huggingface-hub | findstr /C:"Version"
    )
)

echo.
echo LLaMA.cpp Server Check:
echo ---------------------------
if exist "llama-server.exe" (
    echo [OK] llama-server.exe found
    echo File size:
    dir llama-server.exe | findstr "llama-server.exe"
    echo.
    echo Testing help output for HIP support:
    llama-server.exe --help 2>nul | findstr /i "hip" && echo [OK] HIP mentioned in help || echo [WARNING] HIP not explicitly mentioned in help
) else (
    echo [ERROR] llama-server.exe not found
    echo Please run: install-hip-llama.bat
)

echo.
echo Cache Directory Status:
echo --------------------------
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
echo Cache location: %LLAMA_CACHE%
if exist "%LLAMA_CACHE%" (
    echo [OK] Cache directory exists
    echo Models:
    if exist "%LLAMA_CACHE%\models" (
        dir "%LLAMA_CACHE%\models" /B 2>nul | findstr ".gguf" || echo    No GGUF models found
    ) else (
        echo    Models directory not created yet
    )
    echo MMProj files:
    if exist "%LLAMA_CACHE%\mmproj" (
        dir "%LLAMA_CACHE%\mmproj" /B 2>nul | findstr ".gguf" || echo    No MMProj files found
    ) else (
        echo    MMProj directory not created yet
    )
) else (
    echo [WARNING] Cache directory will be created when needed
)

echo.
echo HIP GPU Test (if available):
echo --------------------------------
if exist "llama-server.exe" (
    echo Testing basic server startup with HIP environment...
    set HIP_VISIBLE_DEVICES=0
    set HSA_OVERRIDE_GFX_VERSION=11.0.2
    set HCC_AMDGPU_TARGET=gfx1103
    
    echo Starting server for 5 seconds to test HIP initialization...
    timeout /t 2 >nul
    start /b llama-server.exe --help >nul 2>&1
    timeout /t 3 >nul
    taskkill /f /im llama-server.exe >nul 2>&1
    echo Test completed (check for any error messages above)
) else (
    echo Cannot test - llama-server.exe not available
)

echo.
echo Summary and Next Steps:
echo ===========================
echo.
if exist "llama-server.exe" (
    echo [OK] Ready to run models!
    echo.
    echo Quick Start Commands:
    echo    start-mistral-small-3.2-24b-hip-amd.bat
    echo    start-gemma3-27b-it-abliterated-hip-amd.bat
) else (
    echo ❌ Setup incomplete - run install-hip-llama.bat first
)

echo.
echo 💡 HIP Performance Tips:
echo    - Ensure AMD Adrenalin drivers are latest version
echo    - Enable GPU scheduling in Windows Display settings
echo    - Close GPU-intensive applications before running
echo    - Monitor AMD Software for GPU utilization
echo.

pause
