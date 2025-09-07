# Development Guide

## Adding New Models

This guide explains how to add new models to the llama.cpp RTX 5090 server system.

## Quick Setup for New Model

### 1. Create Model Dockerfile
```dockerfile
# New Model Container using pre-compiled base
FROM llama-base:latest

# Model Configuration
ENV MODEL_REPO="publisher/model-repo-name"
ENV MODEL_FILE="model-file.gguf"
ENV MODEL_ALIAS="model-alias-name"
ENV CONTEXT_SIZE="65536"

# Optional: Multimodal projection file
# ENV MMPROJ_REPO="publisher/model-repo-name"
# ENV MMPROJ_FILE="mmproj-file.gguf"

# Model-specific performance settings
ENV BATCH_SIZE="4096"
ENV UBATCH_SIZE="2048"
ENV FLASH_ATTENTION="on"
ENV N_GPU_LAYERS="-1"

# Model-specific sampling parameters
ENV TEMPERATURE="0.8"
ENV TOP_P="0.95"
ENV TOP_K="40"

# Create model startup script
RUN echo '#!/bin/bash\n\
echo "Starting New Model Server..."\n\
ARGS=(\n\
  "llama-server"\n\
  "--hf-repo" "$MODEL_REPO"\n\
  "--hf-file" "$MODEL_FILE"\n\
  "--alias" "$MODEL_ALIAS"\n\
  "--host" "0.0.0.0"\n\
  "--port" "8080"\n\
  "-c" "$CONTEXT_SIZE"\n\
  "-b" "$BATCH_SIZE"\n\
  "-ub" "$UBATCH_SIZE"\n\
  "-ngl" "$N_GPU_LAYERS"\n\
  "--flash-attn" "$FLASH_ATTENTION"\n\
  "--temp" "$TEMPERATURE"\n\
  "--top-p" "$TOP_P"\n\
  "--top-k" "$TOP_K"\n\
)\n\
exec "${ARGS[@]}"' > /workspace/start-model.sh && \
chmod +x /workspace/start-model.sh

CMD ["/workspace/start-model.sh"]
```

### 2. Update Docker Compose
```yaml
services:
  # Existing services...
  
  new-model:
    image: new-model-name
    build:
      context: .
      dockerfile: Dockerfile.publisher-model-name-variant
    container_name: new-model-container
    ports:
      - "8086:8080"  # Use next available port
    volumes:
      - ${USERPROFILE:-~}/.cache/llama:/root/.cache/llama
    environment:
      # Model-specific environment variables
      - BATCH_SIZE=4096
      - TEMPERATURE=0.8
      - FLASH_ATTENTION=on
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped
```

### 3. Update Build Script
Add to `build-all.ps1`:
```powershell
# Build New Model container
Write-Host "`n🔮 Building New Model container..." -ForegroundColor Yellow  
docker build -f Dockerfile.publisher-model-name-variant -t new-model-name .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build New Model container" -ForegroundColor Red
    exit 1
}

Write-Host "✅ New Model container built successfully!" -ForegroundColor Green
```

## Model Configuration Options

### Performance Tuning Variables
```env
# Batch Processing
BATCH_SIZE=4096              # Physical batch size (RTX 5090 optimal: 4096)
UBATCH_SIZE=2048             # Processing batch size
PARALLEL_SEQUENCES=2         # Concurrent request handling

# Memory Management
N_GPU_LAYERS=-1              # -1 = all layers on GPU
CACHE_TYPE_K=f16             # Key cache precision
CACHE_TYPE_V=f16             # Value cache precision
CONTEXT_SIZE=65536           # Context window size

# Performance Features
FLASH_ATTENTION=on           # Enable flash attention
NO_MMAP=false               # Memory mapping
```

### Sampling Parameters
```env
# Creative Models (0.7-0.9)
TEMPERATURE=0.8
TOP_P=0.95
TOP_K=40

# Reasoning Models (1.0)
TEMPERATURE=1.0
TOP_P=1.0
TOP_K=0

# Precise Models (0.1-0.3)
TEMPERATURE=0.1
TOP_P=0.5
TOP_K=10
```

### Reasoning Configuration
```env
# GPT-OSS Style Reasoning
REASONING_FORMAT=deepseek    # Extract thinking to reasoning_content
REASONING_BUDGET=-1          # Unlimited thinking tokens
THINKING_FORCED_OPEN=false   # Let model decide when to show reasoning

# Basic Reasoning
REASONING_FORMAT=auto        # Let model decide format
REASONING_BUDGET=4096        # Limit thinking tokens
```

## Model Categories and Ports

### Port Allocation
- **8084**: GPT-OSS 20B (Reasoning)
- **8085**: Gemma 3 27B (Vision)
- **8086**: Next model
- **8087**: Next model
- **8088**: Next model

### Naming Convention
```
Dockerfile.[publisher]-[model-name]-[variant]
```

Examples:
- `Dockerfile.DavidAU-OpenAi-GPT-oss-20b-abliterated-uncensored`
- `Dockerfile.mlabonne-gemma-3-27b-it-abliterated-vision`
- `Dockerfile.microsoft-Phi-3-vision-128k-instruct`

## Testing New Models

### 1. Build and Test
```powershell
# Build specific model
docker build -f Dockerfile.publisher-model-name -t model-name .

# Test run
docker run --rm --gpus all -p 8086:8080 model-name

# Test API
curl http://localhost:8086/v1/models
```

## 🧠 Model Configuration Best Practices

### RTX 5090 Optimization
- **Small Models (7B-13B)**: Use batch size 8192, multiple parallel sequences
- **Medium Models (20B-30B)**: Use batch size 4096, 2 parallel sequences  
- **Large Models (70B+)**: Use batch size 2048, 1 parallel sequence
- **Vision Models**: Add 2-3GB VRAM overhead for vision processing

### Memory Usage Estimation
```
VRAM Usage ≈ Model Size × 1.2 + Context × Batch Size × 0.001 + 2GB base
```

Example for 20B model with 4096 batch, 128k context:
```
~12GB (model) + ~0.5GB (context/batch) + 2GB (base) = ~14.5GB total
```

## Integration with Existing System

New models automatically benefit from:
- Pre-compiled llama.cpp with RTX 5090 optimizations
- Flash Attention support
- CUDA environment optimization
- Shared caching directory
- Docker Compose orchestration
- Automated health checks

All models use the same base image for consistency and fast builds.
