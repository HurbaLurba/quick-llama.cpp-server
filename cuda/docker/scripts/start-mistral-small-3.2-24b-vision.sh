#!/bin/bash

# Mistral Small 3.2 24B Vision Model Environment Configuration
export MODEL_REPO="unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF"
export MODEL_FILE="Mistral-Small-3.2-24B-Instruct-2506-UD-Q4_K_XL.gguf"
export MODEL_QUANT="UD-Q4_K_XL"
export MMPROJ_REPO="unsloth/Mistral-Small-3.2-24B-Instruct-2506-GGUF"
export MMPROJ_FILE="mmproj-F32.gguf"
export MMPROJ_TYPE="F32"
export CONTEXT_SIZE="131072"
export MODEL_ALIAS="mistral-small-3.2-24b-vision"

# Mistral Reasoning Configuration
export REASONING_FORMAT="deepseek"
export REASONING_BUDGET="-1"
export THINKING_FORCED_OPEN="false"
export CHAT_TEMPLATE="mistral-v7-tekken"

# Performance Optimization
export BATCH_SIZE="512"
export UBATCH_SIZE="128"
export PARALLEL_SEQUENCES="1"
export FLASH_ATTENTION="on"
export N_GPU_LAYERS="-1"
export CACHE_TYPE_K="q4_0"
export CACHE_TYPE_V="q4_0"
export NO_MMAP="false"
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

# Mistral Small 3.2 24B Vision + Reasoning Model Startup Script
echo "🔥👁️ Starting Mistral Small 3.2 24B with vision + reasoning capabilities..."

# Download model if not present
if [ ! -f "/root/.cache/llama/models--${MODEL_REPO/\//-}/snapshots/*/$(basename $MODEL_FILE)" ]; then
    echo "📥 Model not in cache, will download: $(basename $MODEL_FILE) from $MODEL_REPO..."
else
    echo "✅ Model found in cache"
fi

# Download multimodal projection file if not present  
if [ ! -z "$MMPROJ_REPO" ] && [ ! -z "$MMPROJ_FILE" ]; then
    echo "📥 Downloading multimodal projection file: $MMPROJ_FILE from $MMPROJ_REPO..."
    huggingface-cli download "$MMPROJ_REPO" "$MMPROJ_FILE" --cache-dir /root/.cache/llama --local-dir-use-symlinks False
    # Use the actual cache path structure that huggingface-cli creates
    MMPROJ_PATH="/root/.cache/llama/models--${MMPROJ_REPO/\//-}/snapshots/$(ls -t /root/.cache/llama/models--${MMPROJ_REPO/\//-}/snapshots/ 2>/dev/null | head -1)/$MMPROJ_FILE"
    # Check if file exists, if not try direct path
    if [ ! -f "$MMPROJ_PATH" ]; then
        # Try finding it in any snapshot directory
        MMPROJ_PATH=$(find /root/.cache/llama -name "$MMPROJ_FILE" 2>/dev/null | head -1)
    fi
    echo "✅ Downloaded mmproj to: $MMPROJ_PATH"
fi

# GPU detection and reporting
if [ -n "$CUDA_VISIBLE_DEVICES" ] && [ "$CUDA_VISIBLE_DEVICES" != "0,1,2,3,4,5,6,7" ]; then
    echo "🎮 Using GPU(s): $CUDA_VISIBLE_DEVICES"
else
    echo "ℹ️ Single GPU detected."
fi

# Base arguments for llama-server
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

# Source multi-GPU detection utility
source /workspace/scripts/multi-gpu-detect.sh
SPLIT_FLAGS=($(detect_multi_gpu))

if [ ${#SPLIT_FLAGS[@]} -gt 0 ]; then
  ARGS+=("${SPLIT_FLAGS[@]}")
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

echo "🚀 Starting Mistral Small 3.2 server with vision + reasoning capabilities..."
echo "📦 Model: $MODEL_REPO/$MODEL_FILE"
echo "💾 Context: $CONTEXT_SIZE tokens | Max Output: $MAX_TOKENS tokens"
echo "🧠 Reasoning Format: $REASONING_FORMAT"
echo "💰 Reasoning Budget: $REASONING_BUDGET"
echo "⚡ Batch Size: $BATCH_SIZE (ubatch: $UBATCH_SIZE)"
echo "🎮 GPU Layers: $N_GPU_LAYERS"
echo "✨ Flash Attention: $FLASH_ATTENTION"
echo "🗂️ Cache Types: K=$CACHE_TYPE_K, V=$CACHE_TYPE_V (Q4_1 for stability)"
echo "🖥️ CPU MoE: $([ "$CPU_MOE" = "true" ] && echo "Enabled ($N_CPU_MOE experts on CPU)" || echo "Disabled")"
echo "🔒 Memory Mapping: $([ "$NO_MMAP" = "true" ] && echo "Disabled" || echo "Enabled (optimal for stability)")"
echo "👁️ Vision Enabled: $([ -n "$MMPROJ_PATH" ] && echo "Yes" || echo "No")"
echo "🤔 Thinking Forced Open: $THINKING_FORCED_OPEN"
echo "🌡️ Temperature: $TEMPERATURE"
echo "🎯 Top-K: $TOP_K"
echo "📊 Top-P: $TOP_P"

exec "${ARGS[@]}"
