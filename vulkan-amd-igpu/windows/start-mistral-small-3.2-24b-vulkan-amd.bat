@echo off
REM Mistral Small 3.2 24B Vision Model - Windows Native Vulkan AMD GPU
REM Direct Windows build with enhanced AMD iGPU support

echo 🌋👁️🗿 Starting Mistral Small 3.2 24B - Windows Native Vulkan AMD iGPU...
echo 🔧 Methodology: Native Windows build with AMD GPU optimization

REM Model Configuration
set MODEL_REPO=bartowski/mistral-small-3.2-24b-instruct-2501-GGUF
set MODEL_FILE=mistral-small-3.2-24b-instruct-2501-Q4_K_M.gguf
set MMPROJ_REPO=bartowski/mistral-small-3.2-24b-instruct-2501-GGUF
set MMPROJ_FILE=mmproj-mistral-small-3.2-24b-instruct-2501-f16.gguf
set CONTEXT_SIZE=131072
set MODEL_ALIAS=mistral-small-3.2-24b-vulkan-amd

REM AMD GPU Environment Variables for Windows
set VK_ICD_FILENAMES=%VULKAN_SDK%\Bin\MoltenVK_icd.json
set GGML_VULKAN=1
set GGML_VULKAN_DEVICE=0
set AMD_VULKAN_ICD=RADV

REM Performance settings for AMD iGPU
set BATCH_SIZE=2048
set UBATCH_SIZE=512
set N_GPU_LAYERS=-1
set CACHE_TYPE_K=q4_0
set CACHE_TYPE_V=q4_0
set TEMPERATURE=0.7
set TOP_K=40
set TOP_P=0.95

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
echo    Backend: Vulkan (Windows Native)
echo    Cache: %LLAMA_CACHE%

REM Check if llama-server.exe exists
if not exist "llama-server.exe" (
    echo ❌ llama-server.exe not found in current directory!
    echo Please download the Windows Vulkan build of llama.cpp
    echo From: https://github.com/ggerganov/llama.cpp/releases
    pause
    exit /b 1
)

echo ✅ Found llama-server.exe

REM Download model if not present
set MODEL_PATH=%LLAMA_CACHE%\models\%MODEL_FILE%
if not exist "%MODEL_PATH%" (
    echo.
    echo ⬇️ Downloading model: %MODEL_REPO%/%MODEL_FILE%
    if not exist "%USERPROFILE%\.local\bin\huggingface-cli.exe" (
        echo Installing huggingface-hub...
        pip install huggingface-hub
    )
    huggingface-cli download "%MODEL_REPO%" "%MODEL_FILE%" --local-dir "%LLAMA_CACHE%\models" --local-dir-use-symlinks False
    if errorlevel 1 (
        echo ❌ Model download failed!
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
    huggingface-cli download "%MMPROJ_REPO%" "%MMPROJ_FILE%" --local-dir "%LLAMA_CACHE%\mmproj" --local-dir-use-symlinks False
    if errorlevel 1 (
        echo ❌ MMProj download failed!
        pause
        exit /b 1
    )
    echo ✅ MMProj download completed
) else (
    echo ✅ MMProj file already cached: %MMPROJ_PATH%
)

echo.
echo 🚀 Starting LLaMA.cpp server with Windows Native Vulkan AMD iGPU support...
echo 🌋 Backend: Vulkan (Windows Native)
echo 📦 Model: %MODEL_REPO%/%MODEL_FILE%
echo 👁️ Vision: Enabled
echo.

REM Start the server
llama-server.exe ^
    --model "%MODEL_PATH%" ^
    --mmproj "%MMPROJ_PATH%" ^
    --host 0.0.0.0 ^
    --port 8080 ^
    --ctx-size %CONTEXT_SIZE% ^
    --batch-size %BATCH_SIZE% ^
    --ubatch-size %UBATCH_SIZE% ^
    --parallel 1 ^
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

pause
