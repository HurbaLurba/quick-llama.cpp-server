#!/bin/bash

# Gemma 3 27B IT Abliterated Vision Model Environment Configuration (ROCm)
export MODEL_REPO="mlabonne/gemma-3-27b-it-abliterated-GGUF"
export MODEL_FILE="gemma-3-27b-it-abliterated-Q4_K_M.gguf"
export MODEL_QUANT="Q4_K_M"
export MMPROJ_REPO="mlabonne/gemma-3-27b-it-abliterated-GGUF"
export MMPROJ_FILE="mmproj-mlabonne_gemma-3-27b-it-abliterated-f16.gguf"
export MMPROJ_TYPE="F16"
export CONTEXT_SIZE="131072"
export MODEL_ALIAS="gemma3-27b-it-abliterated-rocm"

# Gemma 3 Configuration
export REASONING_FORMAT="none"
export REASONING_BUDGET="-1"
export THINKING_FORCED_OPEN="false"
export CHAT_TEMPLATE="gemma-v2"

# ROCm Performance Optimization for AMD iGPU
export BATCH_SIZE="2048"
export UBATCH_SIZE="512"  # Reduced for iGPU
export PARALLEL_SEQUENCES="1"
export FLASH_ATTENTION="on"
export N_GPU_LAYERS="-1"  # Offload all layers to GPU
export CACHE_TYPE_K="q4_0"
export CACHE_TYPE_V="q4_0"
export NO_MMAP="true"
export MLOCK="true"
export CACHE_REUSE="128"
export PREDICT="-1"
export MAX_TOKENS="8192"
export CPU_MOE="false"  # Disable for iGPU optimization
export N_CPU_MOE="1"

# Sampling parameters
export TEMPERATURE="0.7"
export TOP_K="40"
export TOP_P="0.95"

# Gemma 3 27B IT Abliterated Vision Model Startup Script (ROCm)
echo "🔥👁️🗿 Starting Gemma 3 27B IT Abliterated with vision capabilities via ROCm..."

# ROCm GPU Detection and Hardware Analysis (based on Toxantron setup)
echo "🗿 ROCm GPU Detection and Hardware Analysis:"

# ROCm environment verification
echo "🔧 ROCm Environment Variables:"
echo "   HSA_OVERRIDE_GFX_VERSION: ${HSA_OVERRIDE_GFX_VERSION:-NOT SET}"
echo "   HCC_AMDGPU_TARGET: ${HCC_AMDGPU_TARGET:-NOT SET}"
echo "   ROCM_VERSION: ${ROCM_VERSION:-NOT SET}"
echo "   HSA_ENABLE_SDMA: ${HSA_ENABLE_SDMA:-NOT SET}"
echo "   ROCR_VISIBLE_DEVICES: ${ROCR_VISIBLE_DEVICES:-NOT SET}"
echo "   HIP_VISIBLE_DEVICES: ${HIP_VISIBLE_DEVICES:-NOT SET}"

# Test ROCm OpenCL platform detection
echo "📊 ROCm OpenCL Platform Status:"
if command -v clinfo >/dev/null 2>&1; then
    clinfo -l 2>&1 | head -10
    echo "   Device count:"
    clinfo 2>&1 | grep -E "Number of devices|Device Name" || echo "   No devices detected (normal in Windows Docker)"
else
    echo "   ❌ clinfo not available"
fi

# Check for AMD GPU device files (Linux only)
echo "🔗 AMD GPU Device Access:"
if [ -e "/dev/kfd" ]; then
    echo "   ✅ /dev/kfd exists (AMD KFD driver)"
else
    echo "   ❌ /dev/kfd missing (expected in Windows Docker)"
fi

if [ -e "/dev/dri/card0" ]; then
    echo "   ✅ /dev/dri/card0 exists (DRM driver)"
else
    echo "   ❌ /dev/dri/card0 missing (expected in Windows Docker)"
fi

if [ -e "/dev/dri/renderD128" ]; then
    echo "   ✅ /dev/dri/renderD128 exists (Render node)"
else
    echo "   ❌ /dev/dri/renderD128 missing (expected in Windows Docker)"
fi

# ROCm-smi status (if available)
echo "🖥️ ROCm System Management Interface:"
if command -v rocm-smi >/dev/null 2>&1; then
    echo "   ROCm SMI available, checking GPU status..."
    rocm-smi --showid --showproduct 2>&1 || echo "   No GPUs detected via ROCm SMI (expected in Windows Docker)"
else
    echo "   ❌ rocm-smi not available"
fi

# HIP runtime check
echo "🏃‍♂️ HIP Runtime Check:"
if command -v hipconfig >/dev/null 2>&1; then
    echo "   HIP Platform: $(hipconfig --platform 2>/dev/null || echo 'Unknown')"
    echo "   HIP Version: $(hipconfig --version 2>/dev/null || echo 'Unknown')"
else
    echo "   ❌ hipconfig not available"
fi

echo ""
echo "🚀 Model Configuration:"
echo "   Model: ${MODEL_REPO}/${MODEL_FILE}"
echo "   Vision: ${MMPROJ_REPO}/${MMPROJ_FILE}"
echo "   Context: ${CONTEXT_SIZE} tokens"
echo "   GPU Layers: ${N_GPU_LAYERS} (all layers)"
echo "   Batch Size: ${BATCH_SIZE}"
echo "   Temperature: ${TEMPERATURE}"

# Create cache directory structure
mkdir -p "${LLAMA_CACHE}/models"
mkdir -p "${LLAMA_CACHE}/mmproj"

echo ""
echo "📁 Cache Configuration:"
echo "   Cache Directory: ${LLAMA_CACHE}"
echo "   Model Cache: ${LLAMA_CACHE}/models"
echo "   MMProj Cache: ${LLAMA_CACHE}/mmproj"

# Download model file if not present
MODEL_PATH="${LLAMA_CACHE}/models/${MODEL_FILE}"
if [ ! -f "${MODEL_PATH}" ]; then
    echo ""
    echo "⬇️ Downloading model: ${MODEL_REPO}/${MODEL_FILE}"
    huggingface-hub download "${MODEL_REPO}" "${MODEL_FILE}" --local-dir "${LLAMA_CACHE}/models" --local-dir-use-symlinks False
    if [ $? -ne 0 ]; then
        echo "❌ Model download failed!"
        exit 1
    fi
    echo "✅ Model download completed"
else
    echo "✅ Model file already cached: ${MODEL_PATH}"
fi

# Download multimodal projection file if not present
MMPROJ_PATH="${LLAMA_CACHE}/mmproj/${MMPROJ_FILE}"
if [ ! -f "${MMPROJ_PATH}" ]; then
    echo ""
    echo "⬇️ Downloading multimodal projection: ${MMPROJ_REPO}/${MMPROJ_FILE}"
    huggingface-hub download "${MMPROJ_REPO}" "${MMPROJ_FILE}" --local-dir "${LLAMA_CACHE}/mmproj" --local-dir-use-symlinks False
    if [ $? -ne 0 ]; then
        echo "❌ MMProj download failed!"
        exit 1
    fi
    echo "✅ MMProj download completed"
else
    echo "✅ MMProj file already cached: ${MMPROJ_PATH}"
fi

# Verify files exist and have reasonable sizes
echo ""
echo "🔍 File Verification:"
if [ -f "${MODEL_PATH}" ]; then
    MODEL_SIZE=$(du -h "${MODEL_PATH}" | cut -f1)
    echo "   Model file: ${MODEL_SIZE} (${MODEL_PATH})"
else
    echo "   ❌ Model file missing: ${MODEL_PATH}"
    exit 1
fi

if [ -f "${MMPROJ_PATH}" ]; then
    MMPROJ_SIZE=$(du -h "${MMPROJ_PATH}" | cut -f1)
    echo "   MMProj file: ${MMPROJ_SIZE} (${MMPROJ_PATH})"
else
    echo "   ❌ MMProj file missing: ${MMPROJ_PATH}"
    exit 1
fi

echo ""
echo "🚀 Starting LLaMA.cpp server with ROCm backend..."

# Start the server with ROCm optimizations
exec llama-server \
    --model "${MODEL_PATH}" \
    --mmproj "${MMPROJ_PATH}" \
    --host 0.0.0.0 \
    --port 8080 \
    --ctx-size "${CONTEXT_SIZE}" \
    --batch-size "${BATCH_SIZE}" \
    --ubatch-size "${UBATCH_SIZE}" \
    --parallel "${PARALLEL_SEQUENCES}" \
    --n-gpu-layers "${N_GPU_LAYERS}" \
    --cache-type-k "${CACHE_TYPE_K}" \
    --cache-type-v "${CACHE_TYPE_V}" \
    --flash-attn \
    --no-mmap \
    --mlock \
    --cache-reuse "${CACHE_REUSE}" \
    --defrag-thold 0.1 \
    --predict "${PREDICT}" \
    --temp "${TEMPERATURE}" \
    --top-k "${TOP_K}" \
    --top-p "${TOP_P}" \
    --chat-template "${CHAT_TEMPLATE}" \
    --alias "${MODEL_ALIAS}" \
    --log-format text \
    --log-file /app/server.log \
    --verbose
