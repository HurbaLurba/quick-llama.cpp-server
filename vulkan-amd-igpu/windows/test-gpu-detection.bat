@echo off
REM GPU Detection and Vulkan Test Script for AMD Windows
REM Helps diagnose AMD GPU and Vulkan setup issues

echo 🔍 AMD GPU and Vulkan Detection Tool
echo =====================================

echo.
echo 🖥️ System Information:
systeminfo | findstr /C:"System Model" /C:"Processor"

echo.
echo 🎮 Graphics Hardware Detection:
wmic path win32_VideoController get name,adapterram /format:list | findstr /V "^$"

echo.
echo 🌋 Vulkan SDK Check:
if defined VULKAN_SDK (
    echo ✅ Vulkan SDK found: %VULKAN_SDK%
) else (
    echo ❌ VULKAN_SDK environment variable not set
    echo Please install Vulkan SDK from: https://vulkan.lunarg.com/
)

echo.
echo 🔧 Vulkan Tools Check:
where vulkaninfo >nul 2>&1
if errorlevel 1 (
    echo ❌ vulkaninfo not found in PATH
) else (
    echo ✅ vulkaninfo found - running device detection...
    echo.
    vulkaninfo --summary | findstr /C:"deviceName" /C:"deviceType" /C:"apiVersion" /C:"driverVersion"
)

echo.
echo 🐍 Python and Dependencies:
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found
) else (
    echo ✅ Python found:
    python --version
)

pip show huggingface-hub >nul 2>&1
if errorlevel 1 (
    echo ❌ huggingface-hub not installed
) else (
    echo ✅ huggingface-hub installed:
    pip show huggingface-hub | findstr /C:"Version"
)

echo.
echo 📁 Directory Check:
if exist "llama-server.exe" (
    echo ✅ llama-server.exe found
    llama-server.exe --help | findstr /C:"vulkan"
) else (
    echo ❌ llama-server.exe not found
    echo Please download from: https://github.com/ggerganov/llama.cpp/releases
)

echo.
echo 💾 Cache Directory:
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
echo Cache location: %LLAMA_CACHE%
if exist "%LLAMA_CACHE%" (
    echo ✅ Cache directory exists
    dir "%LLAMA_CACHE%" /AD 2>nul | findstr models mmproj
) else (
    echo ⚠️ Cache directory will be created when needed
)

echo.
echo 🚀 Ready to run models? Check above for any ❌ errors.
echo If everything looks good, run:
echo   start-mistral-small-3.2-24b-vulkan-amd.bat
pause
