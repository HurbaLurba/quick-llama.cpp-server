#!/bin/bash

# Gemma 3 27B Vision + Reasoning Model Startup Script
echo "🧠👁️ Starting Gemma 3 27B Abliterated with vision + reasoning capabilities..."

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
  "llama-server"
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
  "--jinja"
  "-n" "$MAX_TOKENS"
)

# Add CPU MoE if enabled
if [ "$CPU_MOE" == "true" ]; then
    ARGS+=("--cpu-moe")
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

echo "🚀 Starting Gemma 3 server with vision + reasoning capabilities..."
echo "📦 Model: $MODEL_REPO/$MODEL_FILE"
echo "💾 Context: $CONTEXT_SIZE tokens | Max Output: $MAX_TOKENS tokens"
echo "🧠 Reasoning Format: $REASONING_FORMAT"
echo "💰 Reasoning Budget: $REASONING_BUDGET"
echo "⚡ Batch Size: $BATCH_SIZE (ubatch: $UBATCH_SIZE)"
echo "🎮 GPU Layers: $N_GPU_LAYERS"
echo "✨ Flash Attention: $FLASH_ATTENTION"
echo "🗂️ Cache Types: K=$CACHE_TYPE_K, V=$CACHE_TYPE_V (f16 for quality)"
echo "🖥️ CPU MoE: $([ "$CPU_MOE" = "true" ] && echo "Enabled (FFN experts on CPU)" || echo "Disabled")"
echo "🔒 Memory Mapping: $([ "$NO_MMAP" = "true" ] && echo "Disabled" || echo "Enabled (optimal for stability)")"
echo "👁️ Vision Enabled: $([ -n "$MMPROJ_PATH" ] && echo "Yes" || echo "No")"
echo "🤔 Thinking Forced Open: $THINKING_FORCED_OPEN"
echo "🔧 Args: ${ARGS[@]}"

exec "${ARGS[@]}"