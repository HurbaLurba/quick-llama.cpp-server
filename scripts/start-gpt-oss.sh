#!/bin/bash

# GPT-OSS 20B Reasoning Model Startup Script
echo "🧠 Starting GPT-OSS 20B Abliterated Uncensored with reasoning capabilities..."

# Check if model file already exists in cache
MODEL_CACHE_PATH="/root/.cache/llama/$MODEL_FILE"
if [ -f "$MODEL_CACHE_PATH" ]; then
  echo "✅ Found cached model: $MODEL_CACHE_PATH"
  MODEL_PATH="$MODEL_CACHE_PATH"
else
  echo "📥 Model not in cache, will download: $MODEL_FILE from $MODEL_REPO..."
  MODEL_PATH=""
fi

# Build arguments for llama-server with GPT-OSS optimization + reasoning
if [ -n "$MODEL_PATH" ] && [ -f "$MODEL_PATH" ]; then
  ARGS=(
    "llama-server"
    "-m" "$MODEL_PATH"
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
    "--temp" "$TEMPERATURE"
    "--top-p" "$TOP_P"
    "--top-k" "$TOP_K"
    "--min-p" "$MIN_P"
    "--repeat-penalty" "$REPEAT_PENALTY"
    "-n" "$MAX_TOKENS"
  )
else
  ARGS=(
    "llama-server"
    "-hf" "$MODEL_REPO"
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
    "--temp" "$TEMPERATURE"
    "--top-p" "$TOP_P"
    "--top-k" "$TOP_K"
    "--min-p" "$MIN_P"
    "--repeat-penalty" "$REPEAT_PENALTY"
    "-n" "$MAX_TOKENS"
  )
fi

# Source multi-GPU detection utility
source /workspace/scripts/multi-gpu-detect.sh
SPLIT_FLAGS=($(detect_multi_gpu))

if [ ${#SPLIT_FLAGS[@]} -gt 0 ]; then
  ARGS+=("${SPLIT_FLAGS[@]}")
fi

# Add no-mmap if enabled
if [ "$NO_MMAP" = "true" ]; then
  ARGS+=("--no-mmap")
fi

echo "🚀 Starting GPT-OSS server with reasoning capabilities..."
echo "📦 Model: $MODEL_REPO/$MODEL_FILE"
echo "💾 Context: $CONTEXT_SIZE tokens | Max Output: $MAX_TOKENS tokens"
echo "🌡️ Temperature: $TEMPERATURE | Top-P: $TOP_P | Top-K: $TOP_K | Min-P: $MIN_P"
echo "🔁 Repeat Penalty: $REPEAT_PENALTY"
echo "🧠 Reasoning Format: $REASONING_FORMAT"
echo "💰 Reasoning Budget: $REASONING_BUDGET"
echo "⚡ Batch Size: $BATCH_SIZE (ubatch: $UBATCH_SIZE)"
echo "🎮 GPU Layers: $N_GPU_LAYERS"
echo "✨ Flash Attention: $FLASH_ATTENTION"
echo "🔒 Memory Mapping: $([ "$NO_MMAP" = "true" ] && echo "Disabled (optimal for 32GB VRAM ADA/BLACKWELL)" || echo "Enabled")"
echo "🤔 Thinking Forced Open: $THINKING_FORCED_OPEN"
echo "🔧 Args: ${ARGS[@]}"

exec "${ARGS[@]}"
