# CUDA LLaMA.cpp Server

Multi-model LLaMA.cpp server with CUDA support for NVIDIA GPUs.

## Build Instructions

### 1. Build Base Image
```bash
docker-compose --profile build-base build llama-base
```

### 2. Build Custom Server (no cache)
```bash
docker-compose build --no-cache custom-llama-cpp-server
```

## Run Models (One at a Time)

All models run on **port 8085** externally.

### Gemma 3 27B IT Abliterated Vision
```bash
docker-compose up gemma3-27b-it-abliterated-vision
```

### Mistral Small 3.2 24B Vision
```bash
docker-compose up mistral-small-3.2-24b-vision
```

### Tiger Gemma 3 12B Vision
```bash
docker-compose up tiger-gemma3-12b-vision
```

## API Access

Once running, the OpenAI-compatible API is available at:
- `http://localhost:8085/v1/chat/completions`
- `http://localhost:8085/v1/models`

## Notes

- Only run one model at a time (they all use port 8085)
- Models support vision capabilities via image uploads
- CUDA optimization for NVIDIA GPUs with 32GB+ VRAM
