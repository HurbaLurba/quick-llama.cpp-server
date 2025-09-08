#!/bin/bash

# Mistral Small 3.2 24B Vision Model - Enhanced Vulkan AMD iGPU
# Combines Toxantron OpenCL methodology with Vulkan optimization

# Model Configuration
export MODEL_REPO="bartowski/mistral-small-3.2-24b-instruct-2501-GGUF"
export MODEL_FILE="mistral-small-3.2-24b-instruct-2501-Q4_K_M.gguf"
export MODEL_QUANT="Q4_K_M"
export MMPROJ_REPO="bartowski/mistral-small-3.2-24b-instruct-2501-GGUF"
export MMPROJ_FILE="mmproj-mistral-small-3.2-24b-instruct-2501-f16.gguf"
export CONTEXT_SIZE="131072"
export MODEL_ALIAS="mistral-small-3.2-24b-vulkan-amd"

# Vulkan Performance Optimization for AMD iGPU
export BATCH_SIZE="2048"
export UBATCH_SIZE="512"  # Reduced for iGPU
export PARALLEL_SEQUENCES="1"
export FLASH_ATTENTION="on"
export N_GPU_LAYERS="-1"  # Offload all layers to GPU
export CACHE_TYPE_K="q4_0"
export CACHE_TYPE_V="q4_0"
export NO_MMAP="true"
export MLOCK="true"
export MAX_TOKENS="8192"

# Sampling parameters
export TEMPERATURE="0.7"
export TOP_K="40"
export TOP_P="0.95"

echo "🌋👁️🗿 Starting Mistral Small 3.2 24B with Enhanced Vulkan AMD iGPU Support..."
echo "🔧 Methodology: Toxantron Device Access + Official Vulkan Image"

# ROCm GPU Detection (we know this works from before!)
echo ""
echo "🗿 ROCm OpenCL Detection (Toxantron Methodology):"
echo "🔧 ROCm Environment Variables:"
echo "   HSA_OVERRIDE_GFX_VERSION: ${HSA_OVERRIDE_GFX_VERSION:-NOT SET}"
echo "   HCC_AMDGPU_TARGET: ${HCC_AMDGPU_TARGET:-NOT SET}"
echo "   ROCM_VERSION: ${ROCM_VERSION:-NOT SET}"

# Test OpenCL (we know this works!)
echo ""
echo "📊 OpenCL Platform Status (Known Working):"
if command -v clinfo >/dev/null 2>&1; then
    clinfo -l 2>&1 | head -10
    echo "   Device count:"
    clinfo 2>&1 | grep -E "Number of devices|Device Name" || echo "   No devices detected (expected in Windows Docker)"
else
    echo "   ❌ clinfo not available"
fi

# Enhanced Vulkan Detection
echo ""
echo "🌋 Vulkan Detection (Enhanced with ROCm base):"
echo "🔧 Vulkan Environment Variables:"
echo "   VK_ICD_FILENAMES: ${VK_ICD_FILENAMES:-NOT SET}"
echo "   AMD_VULKAN_ICD: ${AMD_VULKAN_ICD:-NOT SET}"
echo "   RADV_PERFTEST: ${RADV_PERFTEST:-NOT SET}"
echo "   GGML_VULKAN_DEVICE: ${GGML_VULKAN_DEVICE:-NOT SET}"
echo "   GGML_VULKAN: ${GGML_VULKAN:-NOT SET}"

# Test Vulkan with enhanced diagnostics
echo ""
echo "🔍 Vulkan Instance and Device Detection:"
if command -v vulkaninfo >/dev/null 2>&1; then
    echo "   Running vulkaninfo..."
    vulkaninfo --summary 2>&1 | head -30 || echo "   vulkaninfo failed"
else
    echo "   ❌ vulkaninfo not available"
fi

# Check for AMD GPU device files (crucial for both OpenCL and Vulkan)
echo ""
echo "🔗 AMD GPU Device Access:"
if [ -e "/dev/kfd" ]; then
    echo "   ✅ /dev/kfd exists (AMD KFD driver)"
else
    echo "   ❌ /dev/kfd missing (expected in Windows Docker)"
fi

if [ -e "/dev/dri/card0" ]; then
    echo "   ✅ /dev/dri/card0 exists (DRM driver)"
    ls -la /dev/dri/ 2>/dev/null | head -5
else
    echo "   ❌ /dev/dri/card0 missing (expected in Windows Docker)"
fi

if [ -e "/dev/dri/renderD128" ]; then
    echo "   ✅ /dev/dri/renderD128 exists (Render node)"
else
    echo "   ❌ /dev/dri/renderD128 missing (expected in Windows Docker)"
fi

# Hardware PCI detection
echo ""
echo "🔍 Hardware Detection:"
if command -v lspci >/dev/null 2>&1; then
    echo "   PCI Devices:"
    lspci | grep -i -E "(amd|ati|radeon)" | head -3 && echo "   🔴 AMD GPU(s) detected via lspci"
    lspci | grep -i intel | grep -i vga && echo "   🔵 Intel iGPU detected via lspci"
    lspci | grep -i nvidia && echo "   🎮 NVIDIA GPU detected via lspci"
else
    echo "   ❌ lspci command not available"
fi

echo ""
echo "🚀 Model Configuration:"
echo "   Model: ${MODEL_REPO}/${MODEL_FILE}"
echo "   Vision: ${MMPROJ_REPO}/${MMPROJ_FILE}"
echo "   Context: ${CONTEXT_SIZE} tokens"
echo "   GPU Layers: ${N_GPU_LAYERS} (all layers)"
echo "   Batch Size: ${BATCH_SIZE}"
echo "   Backend: Vulkan (Enhanced with ROCm OpenCL base)"

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

# Verify files exist
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
echo "🚀 Starting LLaMA.cpp server with Enhanced Vulkan AMD iGPU support..."
echo "🌋 Backend: Vulkan (with ROCm OpenCL base)"
echo "🗿 Device Access: Toxantron methodology"
echo "📦 Model: ${MODEL_REPO}/${MODEL_FILE}"
echo "👁️ Vision: Enabled"

# Start the server with Vulkan optimizations
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
    --defrag-thold 0.1 \
    --temp "${TEMPERATURE}" \
    --top-k "${TOP_K}" \
    --top-p "${TOP_P}" \
    --alias "${MODEL_ALIAS}" \
    --log-format text \
    --verbose
