@echo off
REM Google Gemma 3 12B IT Model - Windows Native Vulkan AMD GPU
REM Optimized for AMD Radeon 780M with newer b6432 Vulkan build
setlocal EnableDelayedExpansion

REM Activate the vulkan-llama-env virtual environment
if not exist "%~dp0vulkan-llama-env\Scripts\activate.bat" (
    echo [ERROR] Virtual environment not found! Please run install-vulkan-llama.bat first
    exit /b 1
)

call "%~dp0vulkan-llama-env\Scripts\activate.bat"

echo.
echo [INFO] Starting Google Gemma 3 12B IT - Windows Native Vulkan AMD GPU
echo [INFO] Backend: Vulkan (Optimized for AMD Radeon 780M)
echo [INFO] Build: b6432 (Latest with AMD optimizations)

REM Model Configuration - Google Gemma 3 12B IT Quantized
set MODEL_REPO=google/gemma-3-12b-it-qat-q4_0-gguf
set MODEL_QUANT=gemma-3-12b-it-qat.q4_0
set MODEL_FILE=gemma-3-12b-it-qat.q4_0.gguf
set CONTEXT_SIZE=32768
set MODEL_ALIAS=gemma-3-12b-it-vulkan

REM Vulkan AMD GPU Environment Variables
set GGML_VULKAN_DEVICE=0
set VULKAN_MEMORY_BUDGET=0.8
set VK_LAYER_ENABLES=

REM Performance settings optimized for Gemma 3 12B + AMD iGPU Vulkan
REM 12B model is much lighter than 24B - can be more aggressive
set BATCH_SIZE=512
set UBATCH_SIZE=256
set N_GPU_LAYERS=28
set CACHE_TYPE_K=f16
set CACHE_TYPE_V=f16
set TEMPERATURE=0.7
set TOP_K=40
set TOP_P=0.9
set PARALLEL_SEQUENCES=1

REM Gemma-optimized settings
set MAX_TOKENS=4096
set CPU_MOE=false
set N_CPU_MOE=
set CACHE_REUSE=256
set PREDICT=-1

REM Cache directory
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
if not exist "%LLAMA_CACHE%\models" mkdir "%LLAMA_CACHE%\models"
REM Make Hugging Face use the same cache directory
set HF_HOME=%LLAMA_CACHE%
set HF_HUB_CACHE=%LLAMA_CACHE%
REM Port
set PORT=8085

echo.
echo Model Configuration:
echo    Model: %MODEL_REPO%
echo    File: %MODEL_FILE%
echo    Context: %CONTEXT_SIZE% tokens (optimized for Gemma)
echo    GPU Layers: %N_GPU_LAYERS%/40 (aggressive for 12B model)
echo    Batch Size: %BATCH_SIZE% (high throughput)
echo    Backend: Vulkan b6432 (Latest AMD optimizations)
echo    Cache: %LLAMA_CACHE%

REM Resolve llama-server path in bin directory
set BIN_DIR=%~dp0bin
set LLAMA_SERVER=%BIN_DIR%\llama-server.exe
if not exist "%LLAMA_SERVER%" (
    echo [ERROR] llama-server.exe not found at: %LLAMA_SERVER%
    echo Please run: install-vulkan-llama.bat first
    exit /b 1
)

echo [OK] Found llama-server.exe: %LLAMA_SERVER%

REM Vulkan System Detection
echo.
echo Vulkan System Status:
echo    GGML_VULKAN_DEVICE: %GGML_VULKAN_DEVICE%
echo    VULKAN_MEMORY_BUDGET: %VULKAN_MEMORY_BUDGET%

REM Check GPU detection
for /f "delims=" %%a in ('powershell -command "try { $gpu = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.Name -like '*AMD*' -or $_.Name -like '*Radeon*' } | Select-Object -First 1; if ($gpu) { $gpu.Name } else { 'No AMD GPU detected' } } catch { 'GPU detection failed' }"') do set GPU_NAME=%%a

echo.
echo AMD Graphics Hardware:
if "%GPU_NAME%"=="GPU detection failed" (
    echo    [WARNING] GPU detection failed - may still work with Vulkan
) else if "%GPU_NAME%"=="No AMD GPU detected" (
    echo    [WARNING] No AMD GPU detected - will fall back to CPU
) else (
    echo    [OK] %GPU_NAME%
)

REM Use llama-server built-in Hugging Face loading for the model (-hf)
set HF_SPEC=%MODEL_REPO%:%MODEL_QUANT%

REM Seed HF cache with model file if missing
set MODEL_PATH=
for /f "delims=" %%p in ('powershell -command "$repoKey = '%MODEL_REPO%'.Replace('/', '--'); $base=Join-Path $env:LLAMA_CACHE \"models--$repoKey/snapshots\"; if(Test-Path $base){$snap=(Get-ChildItem $base | Sort-Object LastWriteTime -Descending | Select-Object -First 1); if($snap){ Join-Path $snap.FullName '%MODEL_FILE%' }}"') do set MODEL_PATH=%%p
if not exist "%MODEL_PATH%" (
    echo.
    echo Priming model cache: %MODEL_REPO%/%MODEL_FILE%
    echo [INFO] Downloading Gemma 3 12B model (~6.8GB) - this may take several minutes
    hf download "%MODEL_REPO%" "%MODEL_FILE%" --cache-dir "%LLAMA_CACHE%"
    if errorlevel 1 (
        echo [WARNING] Could not pre-download model; server will attempt download on start
    ) else (
        for /f "delims=" %%p in ('powershell -command "$repoKey = '%MODEL_REPO%'.Replace('/', '--'); $base=Join-Path $env:LLAMA_CACHE \"models--$repoKey/snapshots\"; if(Test-Path $base){$snap=(Get-ChildItem $base | Sort-Object LastWriteTime -Descending | Select-Object -First 1); if($snap){ Join-Path $snap.FullName '%MODEL_FILE%' }}"') do set MODEL_PATH=%%p
        if exist "%MODEL_PATH%" echo [OK] Model cached: %MODEL_PATH%
    )
)

echo.
echo [INFO] Starting LLaMA.cpp server with Vulkan AMD GPU acceleration...
echo [INFO] Backend: Vulkan b6432 (Latest AMD optimizations)
echo [INFO] Model: Google Gemma 3 12B IT (Much lighter than Mistral 24B!)
echo [INFO] GPU Layers: %N_GPU_LAYERS%/40 (aggressive - 12B model has headroom)
echo [INFO] Vision: Not applicable (text-only model)
echo.
echo [SUCCESS INDICATORS] Watch for these messages:
echo   1. "ggml_vulkan: Found 1 Vulkan devices" - Vulkan detection
echo   2. "load_tensors: layer XX assigned to device Vulkan0" - GPU assignment 
echo   3. "HTTP server listening" - SERVER READY!
echo.
echo Server will be available at: http://localhost:%PORT%
echo Press Ctrl+C to stop the server ONLY after startup completes
echo.

REM Build dynamic extras - simplified for Gemma (no MOE)
set "DYN_EXTRAS="
if defined CACHE_REUSE set "DYN_EXTRAS=!DYN_EXTRAS! --cache-reuse %CACHE_REUSE%"
if defined PREDICT set "DYN_EXTRAS=!DYN_EXTRAS! --predict %PREDICT%"

REM Detect feature support from llama-server --help
set REASONING_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "reasoning-format" >nul 2>nul || set REASONING_FLAGS=
set SWA_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "swa-full" >nul 2>nul && set SWA_FLAGS=--swa-full
set JINJA_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "jinja" >nul 2>nul && set JINJA_FLAGS=--jinja

REM Detect -hf support, fallback to --model if needed
set HF_ARG=
"%LLAMA_SERVER%" --help | findstr /r /c:"-hf" >nul 2>nul && set HF_ARG=-hf "%HF_SPEC%"
if not defined HF_ARG if defined MODEL_PATH set HF_ARG=--model "%MODEL_PATH%"

REM Start the server with Vulkan optimizations for Gemma 3 12B
echo [LAUNCHING] Gemma 3 12B IT with Vulkan AMD GPU acceleration...
"%LLAMA_SERVER%" ^
    %HF_ARG% ^
    --host 0.0.0.0 ^
    --port %PORT% ^
    --ctx-size %CONTEXT_SIZE% ^
    --batch-size %BATCH_SIZE% ^
    --ubatch-size %UBATCH_SIZE% ^
    --parallel %PARALLEL_SEQUENCES% ^
    --n-gpu-layers %N_GPU_LAYERS% ^
    --cache-type-k %CACHE_TYPE_K% ^
    --cache-type-v %CACHE_TYPE_V% ^
    --flash-attn 1 ^
    --cont-batching ^
    %SWA_FLAGS% ^
    %JINJA_FLAGS% ^
    -n %MAX_TOKENS% ^
    --no-mmap ^
    --mlock ^
    --temp %TEMPERATURE% ^
    --top-k %TOP_K% ^
    --top-p %TOP_P% ^
    --alias %MODEL_ALIAS% ^
    --verbose ^
    !DYN_EXTRAS!

echo.
echo Server stopped
