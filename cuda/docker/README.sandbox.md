# LLaMA.cpp Sandbox Container 🚀

This is a sandbox environment for manually running and experimenting with the llama.cpp server using the official CUDA image.

## Quick Start

1. **Launch the sandbox container:**

   ```powershell
   docker-compose -f docker-compose.sandbox.yml up -d
   ```

2. **Connect to the running container:**

   ```powershell
   docker exec -it llama-sandbox bash
   ```

## Available Commands in Container

Once inside the container (`docker exec -it llama-sandbox bash`), you have access to:

### Core LLaMA.cpp Tools

- `/app/llama-server` - Main OpenAI-compatible server
- `/app/llama-cli` - Command-line interface for inference
- `/app/llama-quantize` - Model quantization tool
- `/app/llama-perplexity` - Perplexity calculation
- `/app/llama-embedding` - Text embeddings
- `/app/llama-bench` - Benchmarking tool

### HuggingFace Integration

- `huggingface-cli` - Download models from HuggingFace Hub

## Example Usage

### 1. Download a Model

```bash
# Download a model (cached to ~/llama.cpp on host)
huggingface-cli download microsoft/Phi-3.5-mini-instruct-gguf Phi-3.5-mini-instruct-q4_k_m.gguf

# Or download from any HF repo
huggingface-cli download mlabonne/gemma-3-27b-it-abliterated-GGUF gemma-3-27b-it-abliterated.q4_k_m.gguf
```

### 2. Start LLaMA Server Manually

```bash
# Basic server start
/app/llama-server \
  -hf microsoft/Phi-3.5-mini-instruct-gguf:Q4_K_M \
  --host 0.0.0.0 \
  --port 8080 \
  -c 32768 \
  -ngl -1

# Advanced server with custom parameters
/app/llama-server \
  -hf mlabonne/gemma-3-27b-it-abliterated-GGUF:Q4_K_M \
  --host 0.0.0.0 \
  --port 8080 \
  -c 131072 \
  -b 512 \
  -ub 128 \
  -ngl -1 \
  --flash-attn \
  --reasoning-format deepseek \
  --cache-type-k q4_0 \
  --cache-type-v q4_0
```

### 3. CLI Inference

```bash
# Simple CLI inference
echo "Hello, how are you?" | /app/llama-cli -hf microsoft/Phi-3.5-mini-instruct-gguf:Q4_K_M -p "You are a helpful assistant.\n\nUser: " -n 100

# Interactive mode
/app/llama-cli -hf microsoft/Phi-3.5-mini-instruct-gguf:Q4_K_M -i
```

### 4. Vision Models (with multimodal projection)

```bash
# Download vision projection file
huggingface-cli download mlabonne/gemma-3-27b-it-abliterated-GGUF mmproj-mlabonne_gemma-3-27b-it-abliterated-f16.gguf

# Start server with vision capabilities
/app/llama-server \
  -hf mlabonne/gemma-3-27b-it-abliterated-GGUF:Q4_K_M \
  --mmproj /root/.cache/llama/models--mlabonne--gemma-3-27b-it-abliterated-GGUF/snapshots/*/mmproj-mlabonne_gemma-3-27b-it-abliterated-f16.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 131072 \
  -ngl -1
```

## Volume Mounts

- **Model Cache**: `~/llama.cpp` on host → `/root/.cache/llama` in container
- **Scripts**: `./scripts` → `/workspace/scripts` (read-only access to your existing scripts)

## Container Management

### Stop the sandbox

```powershell
docker-compose -f docker-compose.sandbox.yml down
```

### View logs

```powershell
docker-compose -f docker-compose.sandbox.yml logs -f
```

### Restart container

```powershell
docker-compose -f docker-compose.sandbox.yml restart
```

## Useful One-Liners

```powershell
# Quick connection to sandbox
docker exec -it llama-sandbox bash

# Run a command without entering the container
docker exec llama-sandbox /app/llama-server --help

# Copy files to/from container
docker cp ./myfile.txt llama-sandbox:/app/
docker cp llama-sandbox:/app/output.txt ./

# Monitor GPU usage while running
docker exec llama-sandbox nvidia-smi -l 1
```

## Environment Variables Available

- `CUDA_VISIBLE_DEVICES` - GPU selection
- `NVIDIA_VISIBLE_DEVICES` - NVIDIA GPU visibility
- All your existing script variables are available in `/workspace/scripts/`

## Notes

- The container runs with `tail -f /dev/null` to keep it alive without starting the server
- Port 8080 is exposed and ready for when you manually start the server
- All models downloaded are cached to your local `~/llama.cpp` directory
- Scripts from your existing setup are available in `/workspace/scripts/` for reference
