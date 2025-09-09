@echo off
REM Setup script for Windows Native Vulkan AMD GPU llama.cpp server
REM Downloads and configures llama.cpp for AMD Vulkan support on Windows

echo 🌋🗿 Windows Native Vulkan AMD GPU Setup
echo 🔧 Setting up llama.cpp server for AMD iGPU acceleration...

REM Check if we already have llama-server.exe
if exist "llama-server.exe" (
    echo ✅ llama-server.exe already exists
    goto :check_vulkan
)

echo.
echo ⬇️ Downloading latest llama.cpp Windows release with Vulkan support...

REM Create temp directory
if not exist "temp" mkdir temp

REM Download the latest release (you'll need to update this URL manually)
echo 📥 Please download the latest Windows release from:
echo https://github.com/ggerganov/llama.cpp/releases
echo.
echo Look for: llama-*-bin-win-vulkan-x64.zip
echo.
echo Extract llama-server.exe to this directory, then run this script again.
echo.
pause
goto :eof

:check_vulkan
echo.
echo 🔍 Checking Vulkan installation...

REM Check for Vulkan SDK
if defined VULKAN_SDK (
    echo ✅ Vulkan SDK found: %VULKAN_SDK%
) else (
    echo ⚠️ Vulkan SDK not found in environment
    echo Please install Vulkan SDK from: https://vulkan.lunarg.com/
)

REM Check for AMD drivers
echo.
echo 🔍 Checking for AMD Vulkan drivers...
where vulkaninfo >nul 2>&1
if errorlevel 1 (
    echo ⚠️ vulkaninfo not found - please install AMD Vulkan drivers
) else (
    echo ✅ vulkaninfo found - running Vulkan detection...
    vulkaninfo --summary
)

echo.
echo 🐍 Checking Python and huggingface-hub...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found! Please install Python 3.8+
    pause
    exit /b 1
) else (
    echo ✅ Python found
)

pip show huggingface-hub >nul 2>&1
if errorlevel 1 (
    echo 📦 Installing huggingface-hub...
    pip install huggingface-hub
    if errorlevel 1 (
        echo ❌ Failed to install huggingface-hub
        pause
        exit /b 1
    )
) else (
    echo ✅ huggingface-hub already installed
)

echo.
echo 🚀 Setup complete! You can now run:
echo    start-mistral-small-3.2-24b-vulkan-amd.bat
echo.
echo 💡 Tips for AMD GPU optimization:
echo    - Make sure AMD Adrenalin drivers are updated
echo    - Enable GPU scheduling in Windows (Settings > System > Display > Graphics settings)
echo    - Close other GPU-intensive applications
echo.
pause
