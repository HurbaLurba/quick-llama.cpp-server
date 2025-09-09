@echo off
REM Vulkan AMD iGPU Docker Setup - Windows/WSL2 compatible
REM Based on: https://github.com/Toxantron/iGPU-Docker device access + official Vulkan

echo 🗿🌋 Vulkan AMD iGPU Docker Setup (Windows/WSL2)
echo Base Image: ghcr.io/ggml-org/llama.cpp:server-vulkan
echo Enhanced with: Toxantron/iGPU-Docker methodology

REM Create .env file with default group IDs for WSL2/Docker Desktop
echo RENDER_GROUP_ID=102> .env
echo VIDEO_GROUP_ID=44>> .env

echo ✅ Created .env file with default group IDs:
echo    Render Group ID: 102
echo    Video Group ID: 44

echo.
echo 🚀 Next Steps:
echo    1. Build Vulkan AMD iGPU image:
echo       docker-compose build gemma3-27b-it-abliterated-vulkan-amd
echo.
echo    2. Test on Windows (Vulkan software):
echo       docker-compose -f docker-compose.windows.yml up gemma3-27b-it-abliterated-vulkan-amd-windows
echo.
echo    3. Run on Linux with GPU:
echo       docker-compose up gemma3-27b-it-abliterated-vulkan-amd

pause
