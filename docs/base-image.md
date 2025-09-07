# Base Image Architecture

## Overview

The base image (`Dockerfile.base-llama-cpp`) provides a pre-compiled llama.cpp installation optimized for 32GB VRAM ADA/BLACKWELL GPUs, eliminating the need to recompile for each model container.

## Build Configuration

### CUDA Optimization
```cmake
-DGGML_CUDA=ON                    # Enable CUDA backend
-DGGML_FLASH_ATTN=ON             # Enable Flash Attention
-DGGML_CUDA_F16=ON               # Half precision support
-DCMAKE_CUDA_ARCHITECTURES="90"  # RTX 40/50 series
```

### Performance Features
- **Flash Attention**: Memory-efficient attention mechanism
- **Multi-GPU Support**: Ready for multi-card setups
- **Optimized Build**: Release mode with full optimizations
- **Architecture Targeting**: Native ADA/BLACKWELL compute support

## Build Process

### First Time Build
```powershell
# Build base image (~15 minutes)
docker build -f Dockerfile.base-llama-cpp -t llama-base:latest .

# Build model containers (~2 minutes each)
docker build -f Dockerfile.DavidAU-OpenAi-GPT-oss-20b-abliterated-uncensored -t gptoss-rtx5090 .
docker build -f Dockerfile.mlabonne-gemma-3-27b-it-abliterated-vision -t gemma3-vision .
```

### Automated Build
```powershell
.\build-all.ps1
```

## Benefits

| Aspect | Before | After |
|--------|--------|-------|
| **Build Time** | 15+ min per model | 2 min per model |
| **Consistency** | Per-model compilation | Shared optimized build |
| **Maintenance** | Multiple build configs | Single base config |
| **Storage** | Redundant layers | Shared base layer |

## Environment Variables

### CUDA Optimization
```env
CUBLAS_WORKSPACE_CONFIG=":0:0"
CUDA_DEVICE_MAX_CONNECTIONS="32"
CUDA_AUTO_BOOST="1"
```

### Performance Tuning
```env
LLAMA_CACHE=/root/.cache/llama
PATH=/workspace/llama.cpp/build/bin:$PATH
```

## Updating llama.cpp

To update to the latest llama.cpp:
1. Rebuild base image: `docker build -f Dockerfile.base-llama-cpp -t llama-base:latest .`
2. Rebuild model containers: `.\build-all.ps1`

All model containers automatically get the updated llama.cpp version.
