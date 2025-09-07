# Available Models

## GPT-OSS 20B - Advanced Reasoning

### Model Details
- **Repository**: `DavidAU/OpenAi-GPT-oss-20b-abliterated-uncensored-NEO-Imatrix-gguf`
- **File**: `OpenAI-20B-NEO-HRR-CODE-TRI-Uncensored-IQ4_NL.gguf`
- **Size**: 10.99 GiB (4.51 BPW)
- **Context**: 131,072 tokens
- **Architecture**: GPT-OSS with MoE (32 experts, 4 active)

### Key Features
- **Advanced Reasoning**: Deep thinking process extraction
- **Uncensored**: Abliterated for open responses
- **High Context**: 128k token window
- **Optimized**: RTX 5090 performance tuned

### Configuration
```env
REASONING_FORMAT=deepseek      # Extracts thinking to reasoning_content
REASONING_BUDGET=-1           # Unlimited thinking tokens
TEMPERATURE=1.0               # Full temperature for reasoning
TOP_P=1.0                     # No nucleus sampling restriction
BATCH_SIZE=4096              # RTX 5090 optimized
```

### Performance (RTX 5090)
- **Prompt Processing**: ~8,000 tokens/sec
- **Generation**: 180-200 tokens/sec
- **VRAM Usage**: ~12GB
- **Reasoning Overhead**: 10-15%

## Gemma 3 27B - Vision & Multimodal

### Model Details
- **Repository**: `mlabonne/gemma-3-27b-it-abliterated-GGUF`
- **File**: `gemma-3-27b-it-abliterated.q4_k_m.gguf`
- **Vision**: `mmproj-mlabonne_gemma-3-27b-it-abliterated-f16.gguf`
- **Context**: 65,536 tokens (expandable to 128k)
- **Architecture**: Gemma 3 with multimodal projection

### Key Features
- **Vision Processing**: Image understanding and analysis
- **Creative Tasks**: Optimized for creative generation
- **Abliterated**: Uncensored responses
- **Multimodal**: Text + image capabilities

### Configuration
```env
REASONING_FORMAT=auto         # Automatic reasoning format
TEMPERATURE=0.8               # Balanced creativity
TOP_P=0.95                    # Nucleus sampling
TOP_K=40                      # Top-k filtering
BATCH_SIZE=3072              # Optimized for 27B model
```

### Performance (RTX 5090)
- **Prompt Processing**: ~6,000 tokens/sec
- **Generation**: 120-150 tokens/sec
- **VRAM Usage**: ~16GB (+2-3GB for vision)
- **Vision Processing**: Real-time image analysis

## Model Comparison

| Feature | GPT-OSS 20B | Gemma 3 27B |
|---------|-------------|-------------|
| **Focus** | Reasoning | Vision + Creative |
| **Context** | 128k tokens | 64k tokens |
| **VRAM** | ~12GB | ~16GB |
| **Speed** | 180-200 tok/s | 120-150 tok/s |
| **Vision** | ❌ | ✅ |
| **Reasoning** | Advanced | Basic |
| **Uncensored** | ✅ | ✅ |

## Usage Recommendations

### Choose GPT-OSS for:
- Complex reasoning tasks
- Mathematical problem solving
- Code analysis and debugging
- Research and analysis
- Chain-of-thought reasoning

### Choose Gemma 3 for:
- Image analysis and description
- Creative writing and storytelling
- Multimodal conversations
- Visual question answering
- Content creation with images

## Adding New Models

See [development.md](development.md) for instructions on adding additional models to the system.
