@echo off
REM Gemma 3 27B IT Abliterated Vision Model - Windows Native HIP AMD GPU
REM Direct Windows build with HIP backend for AMD GPU acceleration

echo 🔥👁️🗿 Starting Gemma 3 27B IT Abliterated - Windows Native HIP AMD GPU...
echo 🚀 Backend: HIP (AMD's CUDA equivalent)
echo 🎯 Target: AMD 8945HS with Radeon 780M integrated graphics

REM Model Configuration
set MODEL_REPO=mlabonne/gemma-3-27b-it-abliterated-GGUF
set MODEL_FILE=gemma-3-27b-it-abliterated-Q4_K_M.gguf
set MMPROJ_REPO=mlabonne/gemma-3-27b-it-abliterated-GGUF
set MMPROJ_FILE=mmproj-mlabonne_gemma-3-27b-it-abliterated-f16.gguf
set CONTEXT_SIZE=131072
set MODEL_ALIAS=gemma3-27b-it-abliterated-hip-amd

REM HIP AMD GPU Environment Variables for Windows
set HIP_VISIBLE_DEVICES=0
set AMD_LOG_LEVEL=1
set HSA_OVERRIDE_GFX_VERSION=11.0.2
set HCC_AMDGPU_TARGET=gfx1103
set GGML_HIP_DEVICE=0

REM Performance settings optimized for AMD iGPU with HIP
set BATCH_SIZE=2048
set UBATCH_SIZE=512
set N_GPU_LAYERS=-1
set CACHE_TYPE_K=q4_0
set CACHE_TYPE_V=q4_0
set TEMPERATURE=0.7
set TOP_K=40
set TOP_P=0.95
set PARALLEL_SEQUENCES=1

REM Cache directory
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
if not exist "%LLAMA_CACHE%\models" mkdir "%LLAMA_CACHE%\models"
if not exist "%LLAMA_CACHE%\mmproj" mkdir "%LLAMA_CACHE%\mmproj"

echo.
echo 🚀 Model Configuration:
echo    Model: %MODEL_REPO%/%MODEL_FILE%
echo    Vision: %MMPROJ_REPO%/%MMPROJ_FILE%
echo    Context: %CONTEXT_SIZE% tokens
echo    GPU Layers: %N_GPU_LAYERS% (all layers)
echo    Batch Size: %BATCH_SIZE%
echo    Backend: HIP (Windows Native AMD)
echo    Cache: %LLAMA_CACHE%

REM Check if llama-server.exe exists
if not exist "llama-server.exe" (
    echo ❌ llama-server.exe not found in current directory!
    echo Please run: install-hip-llama.bat first
    pause
    exit /b 1
)

echo ✅ Found llama-server.exe with HIP support

REM HIP System Detection
echo.
echo 🔥 HIP System Status:
echo    HIP_VISIBLE_DEVICES: %HIP_VISIBLE_DEVICES%
echo    HSA_OVERRIDE_GFX_VERSION: %HSA_OVERRIDE_GFX_VERSION%
echo    HCC_AMDGPU_TARGET: %HCC_AMDGPU_TARGET%
echo    GGML_HIP_DEVICE: %GGML_HIP_DEVICE%

REM Check AMD GPU using PowerShell (modern method)
echo.
echo 🎮 AMD Graphics Hardware:
powershell -Command "Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -match 'AMD|Radeon'} | ForEach-Object {Write-Host '   ' $_.Name}" || echo    No AMD graphics detected via PowerShell

REM Download model if not present
set MODEL_PATH=%LLAMA_CACHE%\models\%MODEL_FILE%
if not exist "%MODEL_PATH%" (
    echo.
    echo ⬇️ Downloading model: %MODEL_REPO%/%MODEL_FILE%
    echo    Size: ~17GB - this will take time depending on connection speed
    
    huggingface-cli download "%MODEL_REPO%" "%MODEL_FILE%" --local-dir "%LLAMA_CACHE%\models" --local-dir-use-symlinks False
    if errorlevel 1 (
        echo ❌ Model download failed!
        echo Please check internet connection and try again
        pause
        exit /b 1
    )
    echo ✅ Model download completed
) else (
    echo ✅ Model file already cached: %MODEL_PATH%
)

REM Download multimodal projection if not present  
set MMPROJ_PATH=%LLAMA_CACHE%\mmproj\%MMPROJ_FILE%
if not exist "%MMPROJ_PATH%" (
    echo.
    echo ⬇️ Downloading multimodal projection: %MMPROJ_REPO%/%MMPROJ_FILE%
    echo    Size: ~2GB - vision capabilities
    
    huggingface-cli download "%MMPROJ_REPO%" "%MMPROJ_FILE%" --local-dir "%LLAMA_CACHE%\mmproj" --local-dir-use-symlinks False
    if errorlevel 1 (
        echo ❌ MMProj download failed!
        echo Vision capabilities will not be available
        set MMPROJ_PATH=
    ) else (
        echo ✅ MMProj download completed
    )
) else (
    echo ✅ MMProj file already cached: %MMPROJ_PATH%
)

echo.
echo 🚀 Starting LLaMA.cpp server with HIP AMD GPU acceleration...
echo 🔥 Backend: HIP (Native Windows AMD)
echo 📦 Model: %MODEL_REPO%/%MODEL_FILE%
if defined MMPROJ_PATH (
    echo 👁️ Vision: Enabled
) else (
    echo 👁️ Vision: Disabled ^(MMProj not available^)
)
echo.
echo 💡 Server will be available at: http://localhost:8080
echo 🔧 Press Ctrl+C to stop the server
echo.

REM Start the server with HIP optimizations
if defined MMPROJ_PATH (
    REM With vision support
    llama-server.exe ^
        --model "%MODEL_PATH%" ^
        --mmproj "%MMPROJ_PATH%" ^
        --host 0.0.0.0 ^
        --port 8080 ^
        --ctx-size %CONTEXT_SIZE% ^
        --batch-size %BATCH_SIZE% ^
        --ubatch-size %UBATCH_SIZE% ^
        --parallel %PARALLEL_SEQUENCES% ^
        --n-gpu-layers %N_GPU_LAYERS% ^
        --cache-type-k %CACHE_TYPE_K% ^
        --cache-type-v %CACHE_TYPE_V% ^
        --flash-attn ^
        --no-mmap ^
        --mlock ^
        --defrag-thold 0.1 ^
        --temp %TEMPERATURE% ^
        --top-k %TOP_K% ^
        --top-p %TOP_P% ^
        --alias %MODEL_ALIAS% ^
        --log-format text ^
        --verbose
) else (
    REM Without vision support
    llama-server.exe ^
        --model "%MODEL_PATH%" ^
        --host 0.0.0.0 ^
        --port 8080 ^
        --ctx-size %CONTEXT_SIZE% ^
        --batch-size %BATCH_SIZE% ^
        --ubatch-size %UBATCH_SIZE% ^
        --parallel %PARALLEL_SEQUENCES% ^
        --n-gpu-layers %N_GPU_LAYERS% ^
        --cache-type-k %CACHE_TYPE_K% ^
        --cache-type-v %CACHE_TYPE_V% ^
        --flash-attn ^
        --no-mmap ^
        --mlock ^
        --defrag-thold 0.1 ^
        --temp %TEMPERATURE% ^
        --top-k %TOP_K% ^
        --top-p %TOP_P% ^
        --alias %MODEL_ALIAS% ^
        --log-format text ^
        --verbose
)

echo.
echo 🔚 Server stopped
pause
