# CUDA LLaMA.cpp Server

Multi-model LLaMA.cpp server with CUDA support for NVIDIA GPUs.

## Build Instructions

All models run on **port 8085** externally.

### Gemma 3 27B IT Abliterated Vision

```bash
docker-compose up gemma3-27b-it-abliterated-vision
```

### Mistral Small 3.2 24B Vision

```bash
docker-compose up mistral-small-3.2-24b-vision
```

## Sandbox Environment

For manual experimentation and development, use the sandbox container:

### Launch Sandbox

```powershell
# PowerShell (Windows)
.\launch-sandbox.ps1

# Or manually
docker-compose -f docker-compose.sandbox.yml up -d
docker exec -it llama-sandbox bash
```

### Stop Sandbox

```powershell
# PowerShell (Windows)
.\stop-sandbox.ps1

# Or manually
docker-compose -f docker-compose.sandbox.yml down
```

The sandbox provides:

- Direct access to `/app/llama-server` and other llama.cpp tools
- HuggingFace model downloading with `huggingface-cli`
- Models cached to `~/llama.cpp` on your host system
- Port 8080 exposed for manual server instances

See [README.sandbox.md](./README.sandbox.md) for detailed usage instructions.

## API Access

Once running, the OpenAI-compatible API is available at:

- `http://localhost:8085/v1/chat/completions` (production containers)
- `http://localhost:8080/v1/chat/completions` (sandbox)
- `http://localhost:8085/v1/models` (production containers)
- `http://localhost:8080/v1/models` (sandbox)
