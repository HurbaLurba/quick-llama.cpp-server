# LLaMA.cpp Enhanced Docker Image for Modern GPUs

**🎯 What is this?**  
This is an enhanced version of the official llama.cpp Docker image, specifically optimized for modern NVIDIA GPUs (RTX 30/40/50 series). It upgrades CUDA from 12.4.0 to 13.0.1 and adds RPC backend support for distributed processing.

**🚀 Why use this instead of the official image?**  
- **Better RTX 40/50 series support** with CUDA 13.0.1
- **RPC backend** for distributed inference across multiple machines
- **Smaller, faster** - only targets modern GPU architectures (no legacy bloat)
- **Same functionality** as official `ghcr.io/ggml-org/llama.cpp:full-cuda` but enhanced

**📦 Ready to use - No building required!**  
Available on Docker Hub: [`philglod/llamacpp-cuda13-modern-full:latest`](https://hub.docker.com/r/philglod/llamacpp-cuda13-modern-full)

## 🚀 Quick Start (Most Users Start Here!)

### What You Need
- NVIDIA RTX 30/40/50 series GPU (older GPUs won't work with this optimized build)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with GPU support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

### Get Started in 2 Minutes

**1. Pull the image:**
```bash
docker pull philglod/llamacpp-cuda13-modern-full:latest
```

**2. Test it works:**
```bash
docker run --rm --gpus all philglod/llamacpp-cuda13-modern-full:latest --server --help | grep -i cuda
```
You should see your GPU detected like: `Device 0: NVIDIA GeForce RTX 4090, compute capability 8.9`

**3. Start using it!** Choose what you want to do:

#### 🌐 Run a Web Server
```bash
docker run --rm --gpus all -p 8080:8080 \
  philglod/llamacpp-cuda13-modern-full:latest \
  --server --host 0.0.0.0 --port 8080
```
Then visit `http://localhost:8080` for the web interface!

#### 📥 Download & Convert a Model from HuggingFace
```bash
mkdir ./models
docker run --rm --gpus all -v $(pwd)/models:/models \
  philglod/llamacpp-cuda13-modern-full:latest \
  --convert --hf-repo microsoft/Phi-3-mini-4k-instruct --outtype f16
```

#### 🚀 Run a Complete AI Server
```bash
# After converting a model (like above), run a full server:
docker run -d --name my-ai-server --gpus all -p 8080:8080 -v $(pwd)/models:/models \
  philglod/llamacpp-cuda13-modern-full:latest \
  --server --host 0.0.0.0 --port 8080 \
  --model /models/Phi-3-mini-4k-instruct-f16.gguf \
  --ctx-size 4096 --n-gpu-layers 999
```
Access web UI at `http://localhost:8080` or API at `http://localhost:8080/v1/chat/completions`

## 💡 What Can This Do?

This image includes everything you need for AI model work:

- **🌐 Web Server** - Run models with a web interface
- **🔄 Model Conversion** - Convert HuggingFace models to llama.cpp format  
- **📊 Benchmarking** - Test your GPU performance
- **💬 Interactive Chat** - Talk to models directly
- **🔧 All Tools** - Complete llama.cpp toolkit included

## 🎯 Who Should Use This?

### ✅ **Perfect for you if:**
- You have RTX 30/40/50 series GPU
- You want the latest CUDA performance improvements  
- You need RPC support for distributed setups
- You want a ready-to-use solution (no building required)

### ❌ **Not for you if:**
- You have older GPUs (GTX 10/20 series, Tesla K80, etc.)
- You need to customize the build extensively
- You're fine with the official CUDA 12.4.0 images

### 🔄 **Alternative: Use Official Images**
For older GPUs or standard setups: `ghcr.io/ggml-org/llama.cpp:full-cuda`

## 📋 More Usage Examples

### Interactive Chat with a Model
```bash
docker run --rm -it --gpus all -v $(pwd)/models:/models \
  philglod/llamacpp-cuda13-modern-full:latest \
  --run -m /models/your-model.gguf -p "Hello, how are you?"
```

### Benchmark Your GPU
```bash
docker run --rm --gpus all -v $(pwd)/models:/models \
  philglod/llamacpp-cuda13-modern-full:latest \
  --bench -m /models/your-model.gguf
```

### Convert Your Own Model
```bash
docker run --rm --gpus all -v $(pwd)/my-model:/input -v $(pwd)/converted:/output \
  philglod/llamacpp-cuda13-modern-full:latest \
  --convert --outtype f16 /input/ --output-dir /output/
```

## 🔧 GPU Compatibility

### ✅ Supported (Modern GPUs Only)
| Series | Examples | CUDA Compute |
|--------|----------|--------------|
| **RTX 30** | 3060, 3070, 3080, 3090 | 8.6 |
| **RTX 40** | 4060, 4070, 4080, 4090 | 8.9 |
| **RTX 50** | 5090, etc. | 9.0 |

### ❌ Not Supported (Use Official Images Instead)
- GTX 10/20 series (Pascal, Turing)
- Tesla K80, P100, V100 (older data center GPUs)  
- Any GPU with compute capability below 8.6

## 🏗️ For Developers: Building from Source

**Most users don't need this section!** Only if you want to customize the build.

### Prerequisites
- Docker with GPU support
- Git
- This repository cloned locally

### Build Process
```bash
# Clone llama.cpp source
git submodule update --init --recursive

# Build the image
docker build -t my-custom-llamacpp:latest --target full -f docker/cuda-13.0.1-custom.Dockerfile .

# Test it
docker run --rm --gpus all my-custom-llamacpp:latest --help
```

### Publishing Your Own Version
```bash
# Tag for Docker Hub
docker tag my-custom-llamacpp:latest YOUR_USERNAME/llamacpp-custom:latest

# Push to Docker Hub
docker login
docker push YOUR_USERNAME/llamacpp-custom:latest
```

## 🔍 Technical Details

### Custom CMake Configuration
Built with optimized flags for modern GPUs:
```cmake
-DGGML_CUDA=ON                    # CUDA support
-DGGML_FORCE_CUBLAS=ON            # Force cuBLAS usage
-DGGML_RPC=ON                     # RPC backend support
-DCMAKE_CUDA_ARCHITECTURES="86;89;90"  # Modern GPUs only
```

### Docker Hub Information
- **Repository**: [`philglod/llamacpp-cuda13-modern-full`](https://hub.docker.com/r/philglod/llamacpp-cuda13-modern-full)
- **Tags**: `latest`, `4067f07` (specific commit)
- **Base Images**: `nvidia/cuda:13.0.1-devel-ubuntu24.04`

### System Requirements
- NVIDIA GPU with compute capability 8.6+
- NVIDIA Container Toolkit installed
- Docker with GPU support enabled
- Sufficient VRAM for your target models

## 🆘 Troubleshooting

### GPU Not Detected?
```bash
# Check if NVIDIA Container Toolkit is working:
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi
```

### Image Won't Start?
Make sure you're using `--gpus all` flag and have a compatible GPU (RTX 30/40/50 series)

### Performance Issues?
This image is optimized for modern GPUs. For older GPUs, use the official images instead.

## 📜 License & Credits

Based on the official llama.cpp project. See the [llama.cpp repository](https://github.com/ggerganov/llama.cpp) for licensing terms.

Special thanks to the llama.cpp team for the excellent foundation this build enhances.