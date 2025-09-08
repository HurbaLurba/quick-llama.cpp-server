# ROCm iGPU Docker Setup

Simple ROCm iGPU setup using official pre-compiled LLaMA.cpp with Toxantron device access methodology.

**Base Image**: `ghcr.io/ggml-org/llama.cpp:server-rocm`

**Status**: ✅ Simple and Clean ROCm Setup

## Quick Setup

### 1. Windows/WSL2 Environment Setup
```bash
.\setup.bat
```

### 2. Build Custom ROCm Server
```bash
docker-compose build gemma3-27b-it-abliterated-vision-rocm
```

### 3. Test Installation (Windows - CPU only)
```bash
docker-compose -f docker-compose.windows.yml up gemma3-27b-it-abliterated-vision-rocm-windows
```

### 4. Run with GPU Access (Linux)
```bash
docker-compose up gemma3-27b-it-abliterated-vision-rocm
```

## Run Models (ROCm Backend)

All models run on **port 8085** externally.

### Gemma 3 27B IT Abliterated Vision (ROCm)
```bash
# Linux with GPU access
docker-compose up gemma3-27b-it-abliterated-vision-rocm

# Windows testing (CPU only)
docker-compose -f docker-compose.windows.yml up gemma3-27b-it-abliterated-vision-rocm-windows
```

### Mistral Small 3.2 24B Vision (ROCm)
```bash
# Linux with GPU access
docker-compose up mistral-small-3.2-24b-vision-rocm

# Windows testing (CPU only)
docker-compose -f docker-compose.windows.yml up mistral-small-3.2-24b-vision-rocm-windows
```

## API Access

Once running, the OpenAI-compatible API is available at:
- `http://localhost:8085/v1/chat/completions`
- `http://localhost:8085/v1/models`

## Target Hardware

- **Primary**: AMD 8945HS (Radeon 780M - gfx1103)
- **Future**: AMD Ryzen AI MAX+ 395 (96GB unified GPU memory)

## Implementation Notes

- **Based on**: [Toxantron/iGPU-Docker](https://github.com/Toxantron/iGPU-Docker) device access methodology
- **Base Image**: Official `ghcr.io/ggml-org/llama.cpp:server-rocm` (pre-compiled)
- **Architecture**: gfx1103 optimized with HSA override
- **Simple**: No custom compilation, just proper device access
