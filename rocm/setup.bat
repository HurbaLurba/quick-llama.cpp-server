@echo off
REM Setup script for AMD iGPU Docker - Windows/WSL2 compatible
REM Based on: https://github.com/Toxantron/iGPU-Docker

echo 🗿 AMD iGPU ROCm Docker Setup (Windows/WSL2)
echo Based on: https://github.com/Toxantron/iGPU-Docker

REM Create .env file with default group IDs for WSL2/Docker Desktop
REM These are common defaults that work in most WSL2 environments
echo RENDER_GROUP_ID=102> .env
echo VIDEO_GROUP_ID=44>> .env

echo ✅ Created .env file with default group IDs for WSL2:
echo    Render Group ID: 102
echo    Video Group ID: 44

echo.
echo 🚀 To build and test:
echo    1. Build ROCm base image:
echo       docker build -f Dockerfile.rocm-base -t rocm-igpu:latest .
echo.
echo    2. Test ROCm functionality (basic):
echo       docker run -it --rm --device=/dev/kfd --device=/dev/dri rocm-igpu:latest
echo.
echo    3. Run docker-compose:
echo       docker-compose up rocm-igpu-base

pause
