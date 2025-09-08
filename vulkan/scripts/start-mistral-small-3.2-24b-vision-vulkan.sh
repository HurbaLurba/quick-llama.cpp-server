#!/bin/bash

# Mistral Small 3.2 24B Vision Model Environment Configuration (Vulkan)
export MODEL_REPO="unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF"
export MODEL_FILE="Mistral-Small-3.2-24B-Instruct-2506-UD-Q4_K_XL.gguf"
export MODEL_QUANT="UD-Q4_K_XL"
export MMPROJ_REPO="unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF"
export MMPROJ_FILE="mmproj-F32.gguf"
export MMPROJ_TYPE="F32"
export CONTEXT_SIZE="131072"
export MODEL_ALIAS="mistral-small-3.2-24b-vision-vulkan"

# Mistral Reasoning Configuration
export REASONING_FORMAT="deepseek"
export REASONING_BUDGET="-1"
export THINKING_FORCED_OPEN="false"
export CHAT_TEMPLATE="mistral-v7-tekken"

# Vulkan Cross-Platform Performance Optimization
export BATCH_SIZE="2048"
export UBATCH_SIZE="1024"
export PARALLEL_SEQUENCES="1"
export FLASH_ATTENTION="on"
export N_GPU_LAYERS="-1"
export CACHE_TYPE_K="q4_0"
export CACHE_TYPE_V="q4_0"
export NO_MMAP="true"
export MLOCK="true"
export CACHE_REUSE="128"
export PREDICT="-1"
export MAX_TOKENS="8192"
export CPU_MOE="true"
export N_CPU_MOE="2"

# Sampling parameters
export TEMPERATURE="0.15"
export TOP_K="32"
export TOP_P="1.00"

# Mistral Small 3.2 24B Vision + Reasoning Model Startup Script (Vulkan)
echo "🔥👁️🌋 Starting Mistral Small 3.2 24B with vision + reasoning capabilities via Vulkan..."

# Download model if not present
if [ ! -f "/root/.cache/llama/models--${MODEL_REPO/\//-}/snapshots/*/$(basename $MODEL_FILE)" ]; then
    echo "📥 Model not in cache, will download: $(basename $MODEL_FILE) from $MODEL_REPO..."
else
    echo "✅ Model found in cache"
fi

# Download multimodal projection file if not present  
if [ ! -z "$MMPROJ_REPO" ] && [ ! -z "$MMPROJ_FILE" ]; then
    echo "📥 Downloading multimodal projection file: $MMPROJ_FILE from $MMPROJ_REPO..."
    
    # Try huggingface-cli first, fallback to python -m huggingface_hub if not available
    if command -v huggingface-cli >/dev/null 2>&1; then
        huggingface-cli download "$MMPROJ_REPO" "$MMPROJ_FILE" --cache-dir /root/.cache/llama --local-dir-use-symlinks False
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
from huggingface_hub import hf_hub_download
import os
os.makedirs('/root/.cache/llama', exist_ok=True)
file_path = hf_hub_download(repo_id='$MMPROJ_REPO', filename='$MMPROJ_FILE', cache_dir='/root/.cache/llama')
print(f'Downloaded to: {file_path}')
"
    else
        echo "⚠️ No download method available, attempting to continue without mmproj..."
    fi
    
    # Use the actual cache path structure that huggingface creates
    MMPROJ_PATH="/root/.cache/llama/models--${MMPROJ_REPO/\//-}/snapshots/$(ls -t /root/.cache/llama/models--${MMPROJ_REPO/\//-}/snapshots/ 2>/dev/null | head -1)/$MMPROJ_FILE"
    # Check if file exists, if not try direct path
    if [ ! -f "$MMPROJ_PATH" ]; then
        # Try finding it in any snapshot directory
        MMPROJ_PATH=$(find /root/.cache/llama -name "$MMPROJ_FILE" 2>/dev/null | head -1)
    fi
    echo "✅ Downloaded mmproj to: $MMPROJ_PATH"
fi

# Enhanced Vulkan GPU detection and reporting with AMD focus
echo "🌋 Vulkan GPU Detection and Hardware Analysis:"

# Set up headless display environment BEFORE any Vulkan testing
echo "🖥️ Setting up headless display environment..."
export DISPLAY=:99
export XDG_RUNTIME_DIR=/tmp/xdg_runtime
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start Xvfb in background for proper headless Vulkan support
if command -v Xvfb >/dev/null 2>&1; then
    echo "🚀 Starting virtual display server..."
    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
    XVFB_PID=$!
    sleep 2  # Give Xvfb time to start
    echo "✅ Virtual display started (PID: $XVFB_PID)"
fi

# Detailed AMD GPU detection
echo "🔍 Hardware Detection:"
if command -v lspci >/dev/null 2>&1; then
    echo "   PCI Devices:"
    lspci | grep -i -E "(amd|ati|radeon)" | head -3 && echo "🔴 AMD GPU(s) detected via lspci"
    lspci | grep -i intel | grep -i vga && echo "🔵 Intel iGPU detected via lspci"
    lspci | grep -i nvidia && echo "🎮 NVIDIA GPU detected via lspci"
else
    echo "❌ lspci command not available - installing..."
fi

# Check DRI devices (crucial for AMD GPU access)
echo "🖥️ DRI Device Status:"
if [ -d "/dev/dri" ]; then
    ls -la /dev/dri/ 2>/dev/null && echo "✅ DRI devices available for GPU access"
    echo "🔍 Checking DRI device permissions:"
    ls -l /dev/dri/card* /dev/dri/render* 2>/dev/null
else
    echo "❌ No DRI devices found - GPU acceleration may not work"
fi

# Vulkan info with better error handling
echo "🌋 Vulkan Driver Status:"
if command -v vulkaninfo >/dev/null 2>&1; then
    echo "🔍 Available Vulkan devices:"
    vulkaninfo --summary 2>/dev/null | head -20 || echo "⚠️ Vulkan detected but info failed"
    echo "🔍 Vulkan instance extensions:"
    vulkaninfo | grep -A 10 "Instance Extensions" 2>/dev/null || true
else
    echo "❌ vulkaninfo command not available"
    echo "🔍 Attempting basic Vulkan library check:"
    ls -la /usr/lib/x86_64-linux-gnu/libvulkan* 2>/dev/null || echo "❌ Vulkan libraries not found"
fi

# Check specific AMD Vulkan driver
echo "🔴 AMD Vulkan Status:"
if [ -f "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json" ]; then
    echo "✅ AMD Radeon Vulkan ICD found"
    cat /usr/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null | head -5
    echo "🔍 Testing ICD library:"
    ls -la /usr/lib/x86_64-linux-gnu/libvulkan_radeon.so* 2>/dev/null || echo "❌ Radeon Vulkan driver library not found"
else
    echo "❌ AMD Radeon Vulkan ICD not found"
fi

# GGML/llama.cpp backend detection
echo "🧠 GGML Backend Status:"
ls -la /app/libggml*.so 2>/dev/null | grep -E "(vulkan|cuda)" || echo "⚠️ No GPU backends found"

# Environment variable summary
echo "🔧 Vulkan Environment Variables:"
echo "   VK_ICD_FILENAMES: $VK_ICD_FILENAMES"
echo "   GGML_VULKAN_DEVICE: $GGML_VULKAN_DEVICE"
echo "   VK_DRIVER_FILES: $VK_DRIVER_FILES"

# Final acceleration summary and Vulkan backend forcing
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "🎮 Primary: NVIDIA GPU acceleration"
elif lspci | grep -i -E "(amd|ati|radeon)" >/dev/null 2>&1; then
    echo "🔴 Primary: AMD GPU acceleration (Vulkan)"
elif lspci | grep -i intel | grep -i vga >/dev/null 2>&1; then
    echo "🔵 Primary: Intel iGPU acceleration (Vulkan)"  
else
    echo "🖥️ Primary: CPU acceleration (no GPU detected)"
fi

# CRITICAL: Test Vulkan directly before proceeding
echo "🧪 Running direct Vulkan diagnostic..."
if [ -f "/app/scripts/vulkan-diagnostic.sh" ]; then
    bash /app/scripts/vulkan-diagnostic.sh
fi

# Force Vulkan backend if we have the library
if [ -f "/app/libggml-vulkan.so" ] && [ -f "/usr/lib/x86_64-linux-gnu/libvulkan_radeon.so" ]; then
    echo "🔧 FORCING Vulkan backend activation..."
    export GGML_VULKAN=1
    export GGML_FORCE_VULKAN=1
    export VK_LOADER_DEBUG=error  # Less verbose but still informative
    export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
    
    # FIX: Unset problematic empty layer variable
    unset VK_INSTANCE_LAYERS
    
    # Ensure proper Vulkan ICD loading - AMD only for better detection
    export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
    
    # AMD-specific optimizations
    export RADV_PERFTEST="aco"
    export AMD_DEBUG="nohyperz,nogfx"
    
    # Try different device numbers
    for device in 0 1 2; do
        export GGML_VULKAN_DEVICE=$device
        echo "   🔍 Configured for Vulkan device $device..."
        # This will be used by llama-server later
        if [ $device -eq 0 ]; then
            break  # Use device 0 for now
        fi
    done
    
    echo "🔧 Final Vulkan environment:"
    echo "   GGML_VULKAN: $GGML_VULKAN"
    echo "   GGML_VULKAN_DEVICE: $GGML_VULKAN_DEVICE"
    echo "   VK_ICD_FILENAMES: $VK_ICD_FILENAMES"
    echo "   VK_INSTANCE_LAYERS: ${VK_INSTANCE_LAYERS:-UNSET}"
    echo "   DISPLAY: ${DISPLAY:-UNSET}"
    echo "   XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-UNSET}"
fi

# Base arguments for llama-server with Vulkan
ARGS=(
  "/app/llama-server"
  "-hf" "${MODEL_REPO}:${MODEL_QUANT}"
  "--alias" "$MODEL_ALIAS"
  "--host" "0.0.0.0"
  "--port" "8080"
  "-c" "$CONTEXT_SIZE"
  "-b" "$BATCH_SIZE"
  "-ub" "$UBATCH_SIZE"
  "-np" "$PARALLEL_SEQUENCES"
  "-ngl" "$N_GPU_LAYERS"
  "--cache-type-k" "$CACHE_TYPE_K"
  "--cache-type-v" "$CACHE_TYPE_V"
  "--reasoning-format" "$REASONING_FORMAT"
  "--reasoning-budget" "$REASONING_BUDGET"
  "--flash-attn" "$FLASH_ATTENTION"
  "--swa-full"
  "--jinja"
  "-n" "$MAX_TOKENS"
)

# Add CPU MoE if enabled
if [ "$CPU_MOE" == "true" ]; then
    ARGS+=("--cpu-moe")
    if [ -n "$N_CPU_MOE" ]; then
        ARGS+=("--n-cpu-moe" "$N_CPU_MOE")
    fi
fi

# Add sampling parameters if set
if [ -n "$TEMPERATURE" ]; then
    ARGS+=("--temp" "$TEMPERATURE")
fi
if [ -n "$TOP_K" ]; then
    ARGS+=("--top-k" "$TOP_K")
fi
if [ -n "$TOP_P" ]; then
    ARGS+=("--top-p" "$TOP_P")
fi

# Add multimodal projection if available
if [ -n "$MMPROJ_PATH" ] && [ -f "$MMPROJ_PATH" ]; then
  ARGS+=("--mmproj" "$MMPROJ_PATH")
  echo "👁️ Vision capabilities enabled with mmproj: $MMPROJ_PATH"
else
  echo "❌ Vision capabilities disabled - no valid mmproj file"
fi

# Add no-mmap if enabled
if [ "$NO_MMAP" = "true" ]; then
  ARGS+=("--no-mmap")
fi

# Add mlock if enabled
if [ "$MLOCK" = "true" ]; then
  ARGS+=("--mlock")
fi

# Add cache reuse if set
if [ -n "$CACHE_REUSE" ]; then
    ARGS+=("--cache-reuse" "$CACHE_REUSE")
fi

# Add predict limit if set
if [ -n "$PREDICT" ]; then
    ARGS+=("--predict" "$PREDICT")
fi

echo "🚀 Starting Mistral Small 3.2 server with vision + reasoning capabilities via Vulkan..."
echo "🌋 Backend: Vulkan (AMD/CPU/Intel/NVIDIA cross-platform)"
echo "📦 Model: $MODEL_REPO/$MODEL_FILE"
echo "💾 Context: $CONTEXT_SIZE tokens | Max Output: $MAX_TOKENS tokens"
echo "🧠 Reasoning Format: $REASONING_FORMAT"
echo "💰 Reasoning Budget: $REASONING_BUDGET"
echo "⚡ Batch Size: $BATCH_SIZE (ubatch: $UBATCH_SIZE)"
echo "🎮 GPU Layers: $N_GPU_LAYERS"
echo "✨ Flash Attention: $FLASH_ATTENTION"
echo "🗂️ Cache Types: K=$CACHE_TYPE_K, V=$CACHE_TYPE_V"
echo "🖥️ CPU MoE: $([ "$CPU_MOE" = "true" ] && echo "Enabled ($N_CPU_MOE experts on CPU)" || echo "Disabled")"
echo "🔒 Memory Mapping: $([ "$NO_MMAP" = "true" ] && echo "Disabled" || echo "Enabled")"
echo "👁️ Vision Enabled: $([ -n "$MMPROJ_PATH" ] && echo "Yes" || echo "No")"
echo "🤔 Thinking Forced Open: $THINKING_FORCED_OPEN"
echo "🌡️ Temperature: $TEMPERATURE"
echo "🎯 Top-K: $TOP_K"
echo "📊 Top-P: $TOP_P"
echo "🔧 Args: ${ARGS[@]}"

# Cleanup function for Xvfb
cleanup() {
    if [ ! -z "$XVFB_PID" ]; then
        echo "🛑 Stopping virtual display server..."
        kill $XVFB_PID 2>/dev/null
    fi
}
trap cleanup EXIT

exec "${ARGS[@]}"
