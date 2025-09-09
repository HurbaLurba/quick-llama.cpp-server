@echo off
REM Mistral Small 3.2 24B Vision Model - Windows Native Vulkan AMD GPU
REM Vulkan backend for better AMD GPU compatibility than HIP
echo.
echo Starting LLaMA.cpp server with Vulkan AMD GPU acceleration...
echo Backend: Vulkan (AMD Graphics) - 35 GPU layers
echo Model: %MODEL_REPO%:%MODEL_QUANT%
if defined MMPROJ_PATH (
    echo Vision: Enabled
) else (
    echo Vision: Disabled ^(MMProj not available^)
)
echo.
echo [INFO] Model loading will take 2-3 minutes for GPU memory transfer
echo [INFO] Server shows 'loading' page until tensors are transferred to Vulkan
echo [INFO] DO NOT interrupt the process - let it complete fully
echo.
echo Server will be available at: http://localhost:%PORT%
echo Press Ctrl+C to stop the server ONLY after it's fully loaded
echo.leDelayedExpansion

REM Activate the vulkan-llama-env virtual environment
if not exist "%~dp0vulkan-llama-env\Scripts\activate.bat" (
    echo [ERROR] Virtual environment not found! Please run install-vulkan-llama.bat first
    exit /b 1
)

call "%~dp0vulkan-llama-env\Scripts\activate.bat"

echo.
echo [INFO] Starting Mistral Small 3.2 24B - Windows Native Vulkan AMD GPU
echo [INFO] Backend: Vulkan (Better AMD compatibility than HIP)
echo [INFO] Target: AMD 8945HS with Radeon 780M integrated graphics

REM Model Configuration
set MODEL_REPO=unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF
set MODEL_QUANT=UD-Q4_K_XL
set MODEL_FILE=Mistral-Small-3.2-24B-Instruct-2506-UD-Q4_K_XL.gguf
set MMPROJ_REPO=unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF
set MMPROJ_FILE=mmproj-F32.gguf
set CONTEXT_SIZE=65536
set MODEL_ALIAS=mistral-small-3.2-24b-vulkan

REM Vulkan AMD GPU Environment Variables
set VULKAN_SDK=
set VK_LAYER_PATH=
set VK_INSTANCE_LAYERS=
set GGML_VULKAN_DEVICE=0

REM Performance settings optimized for AMD iGPU with Vulkan
set BATCH_SIZE=512
set UBATCH_SIZE=256
set N_GPU_LAYERS=35
set CACHE_TYPE_K=f16
set CACHE_TYPE_V=f16
set TEMPERATURE=0.15
set TOP_K=32
set TOP_P=1.00
set PARALLEL_SEQUENCES=1

REM Reasoning and advanced options
set REASONING_FORMAT=deepseek
set REASONING_BUDGET=-1
set MAX_TOKENS=8192
set CPU_MOE=true
set N_CPU_MOE=2
set CACHE_REUSE=128
set PREDICT=-1

REM Cache directory
set LLAMA_CACHE=%USERPROFILE%\.cache\llama
if not exist "%LLAMA_CACHE%\models" mkdir "%LLAMA_CACHE%\models"
if not exist "%LLAMA_CACHE%\mmproj" mkdir "%LLAMA_CACHE%\mmproj"
REM Make Hugging Face use the same cache directory
set HF_HOME=%LLAMA_CACHE%
set HF_HUB_CACHE=%LLAMA_CACHE%
REM Port
set PORT=8085

echo.
echo Model Configuration:
echo    Model: %MODEL_REPO%/%MODEL_FILE%
echo    Vision: %MMPROJ_REPO%/%MMPROJ_FILE%
echo    Context: %CONTEXT_SIZE% tokens
echo    GPU Layers: %N_GPU_LAYERS%
echo    Batch Size: %BATCH_SIZE%
echo    Backend: Vulkan (Windows Native AMD)
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
    hf download "%MODEL_REPO%" "%MODEL_FILE%" --cache-dir "%LLAMA_CACHE%"
    if errorlevel 1 (
        echo [WARNING] Could not pre-download model; server will attempt download on start
    ) else (
        for /f "delims=" %%p in ('powershell -command "$repoKey = '%MODEL_REPO%'.Replace('/', '--'); $base=Join-Path $env:LLAMA_CACHE \"models--$repoKey/snapshots\"; if(Test-Path $base){$snap=(Get-ChildItem $base | Sort-Object LastWriteTime -Descending | Select-Object -First 1); if($snap){ Join-Path $snap.FullName '%MODEL_FILE%' }}"') do set MODEL_PATH=%%p
        if exist "%MODEL_PATH%" echo [OK] Model cached: %MODEL_PATH%
    )
)

REM Download multimodal projection - ENABLE FOR VULKAN TEST
set MMPROJ_PATH=
for /f "delims=" %%p in ('powershell -command "$repoKey = '%MMPROJ_REPO%'.Replace('/', '--'); $base=Join-Path $env:LLAMA_CACHE \"models--$repoKey/snapshots\"; if(Test-Path $base){Get-ChildItem $base | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Join-Path $_.FullName '%MMPROJ_FILE%' }}"') do set MMPROJ_PATH=%%p
if not exist "%MMPROJ_PATH%" (
    echo.
    echo Downloading multimodal projection: %MMPROJ_REPO%/%MMPROJ_FILE%
    echo    Size: ~2GB - vision capabilities
    
    hf download "%MMPROJ_REPO%" "%MMPROJ_FILE%" --cache-dir "%LLAMA_CACHE%"
    if errorlevel 1 (
        echo [ERROR] MMProj download failed!
        echo Vision capabilities will not be available
        set MMPROJ_PATH=
    ) else (
        for /f "delims=" %%p in ('powershell -command "$repoKey = '%MMPROJ_REPO%'.Replace('/', '--'); $base=Join-Path $env:LLAMA_CACHE \"models--$repoKey/snapshots\"; if(Test-Path $base){Get-ChildItem $base | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Join-Path $_.FullName '%MMPROJ_FILE%' }}"') do set MMPROJ_PATH=%%p
        if exist "%MMPROJ_PATH%" (
            echo [OK] MMProj file cached: %MMPROJ_PATH%
        ) else (
            echo [WARNING] MMProj file not found in cache after download
        )
    )
) else (
    echo [OK] MMProj file already cached: %MMPROJ_PATH%
)

echo.
echo Starting LLaMA.cpp server with Vulkan AMD GPU acceleration...
echo Backend: Vulkan (Native Windows AMD)
echo Model: %MODEL_REPO%:%MODEL_QUANT%
if defined MMPROJ_PATH (
    echo Vision: Enabled
) else (
    echo Vision: Disabled ^(MMProj not available^)
)
echo.
echo Server will be available at: http://localhost:%PORT%
echo Press Ctrl+C to stop the server
echo.

REM Build dynamic extras
set DYN_EXTRAS=
if /i "%CPU_MOE%"=="true" (
    set DYN_EXTRAS=!DYN_EXTRAS! --cpu-moe
    if defined N_CPU_MOE set DYN_EXTRAS=!DYN_EXTRAS! --n-cpu-moe %N_CPU_MOE%
)
if defined CACHE_REUSE set DYN_EXTRAS=!DYN_EXTRAS! --cache-reuse %CACHE_REUSE%
if defined PREDICT set DYN_EXTRAS=!DYN_EXTRAS! --predict %PREDICT%

REM Detect feature support from llama-server --help
set REASONING_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "reasoning-format" >nul && set REASONING_FLAGS=--reasoning-format %REASONING_FORMAT% --reasoning-budget %REASONING_BUDGET%
set SWA_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "swa-full" >nul && set SWA_FLAGS=--swa-full
set JINJA_FLAGS=
"%LLAMA_SERVER%" --help | findstr /i "jinja" >nul && set JINJA_FLAGS=--jinja

REM Detect -hf support, fallback to --model if needed
set HF_ARG=
"%LLAMA_SERVER%" --help | findstr /r /c:"-hf" >nul && set HF_ARG=-hf "%HF_SPEC%"
if not defined HF_ARG if defined MODEL_PATH set HF_ARG=--model "%MODEL_PATH%"

REM Start the server with Vulkan optimizations
if defined MMPROJ_PATH (
    REM With vision support
    "%LLAMA_SERVER%" ^
        %HF_ARG% ^
        --mmproj "%MMPROJ_PATH%" ^
        --host 0.0.0.0 ^
        --port %PORT% ^
        --ctx-size %CONTEXT_SIZE% ^
        --batch-size %BATCH_SIZE% ^
        --ubatch-size %UBATCH_SIZE% ^
        --parallel %PARALLEL_SEQUENCES% ^
        --n-gpu-layers %N_GPU_LAYERS% ^
        --cache-type-k %CACHE_TYPE_K% ^
        --cache-type-v %CACHE_TYPE_V% ^
        --flash-attn 0 ^
        --no-warmup ^
        %REASONING_FLAGS% ^
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
        %DYN_EXTRAS%
) else (
    REM Without vision support
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
        --flash-attn 0 ^
        --no-warmup ^
        %REASONING_FLAGS% ^
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
        %DYN_EXTRAS%
)

echo.
echo Server stopped
