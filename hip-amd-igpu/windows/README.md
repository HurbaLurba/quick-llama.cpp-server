# Windows Native HIP AMD iGPU - LLaMA.cpp Server

Native Windows implementation for AMD GPU acceleration using HIP backend with llama.cpp server.

## 🔥 HIP AMD GPU Support

- **Target Hardware**: AMD 8945HS with Radeon 780M integrated graphics (gfx1103)
- **Backend**: HIP (AMD's CUDA equivalent for Windows)
- **Future Support**: AMD Ryzen AI MAX+ 395 with 96GB unified memory
- **Performance**: Significantly better than Vulkan for AMD GPUs

## 🚀 Quick Start

### 1. Install and Setup

```batch
# Download and setup llama.cpp with HIP support
install-hip-llama.bat

# This automatically:
# - Downloads the HIP-enabled llama.cpp build
# - Extracts llama-server.exe
# - Checks AMD drivers and dependencies
# - Installs Python packages if needed
```

### 2. Test Your System

```batch
# Run comprehensive system check
test-hip-gpu-detection.bat

# Verifies:
# - AMD GPU detection
# - HIP environment setup
# - Python and huggingface-hub
# - llama-server.exe functionality
```

### 3. Run Models

**Mistral Small 3.2 24B Vision:**
```batch
start-mistral-small-3.2-24b-hip-amd.bat
```

**Gemma 3 27B IT Abliterated Vision:**
```batch
start-gemma3-27b-it-abliterated-hip-amd.bat
```

## 🔥 HIP Performance Advantages

### Why HIP > Vulkan for AMD
- **Native AMD**: HIP is AMD's own compute platform
- **Better Memory Management**: Direct GPU memory access
- **Optimized Kernels**: AMD-specific optimizations
- **Lower Overhead**: Less abstraction than Vulkan
- **Windows Support**: Native Windows HIP runtime

### Performance Settings
- **Batch Size**: 2048 (optimized for iGPU memory)
- **Ubatch Size**: 512 (efficient processing chunks)
- **GPU Layers**: -1 (all layers on GPU)
- **Cache Types**: Q4_0 for memory efficiency
- **Context**: 131K tokens (full model capability)

## 🔧 HIP Environment Variables

The launchers automatically configure:

```batch
# GPU Selection and Targeting
HIP_VISIBLE_DEVICES=0              # Use first AMD GPU
HSA_OVERRIDE_GFX_VERSION=11.0.2    # Target gfx1103 architecture
HCC_AMDGPU_TARGET=gfx1103          # AMD 8945HS specific
GGML_HIP_DEVICE=0                  # GGML HIP device selection
AMD_LOG_LEVEL=1                    # Enable AMD logging
```

## 💻 System Requirements

### Required
- **OS**: Windows 10/11 x64
- **GPU**: AMD Radeon graphics with HIP support
- **Drivers**: Latest AMD Adrenalin drivers
- **RAM**: 16GB+ recommended (models are 15-17GB)
- **Storage**: 50GB+ free space for models
- **Python**: 3.8+ for model downloads

### Recommended
- **GPU**: AMD 8945HS with Radeon 780M or better
- **RAM**: 32GB+ for optimal performance
- **Storage**: NVMe SSD for faster model loading
- **Network**: High-speed internet for model downloads

## 📁 Directory Structure

```
hip-amd-igpu/windows/
├── install-hip-llama.bat                        # Installer/unpacker
├── test-hip-gpu-detection.bat                   # System diagnostics
├── start-mistral-small-3.2-24b-hip-amd.bat     # Mistral launcher
├── start-gemma3-27b-it-abliterated-hip-amd.bat # Gemma launcher
├── llama-server.exe                             # (Downloaded by installer)
├── temp/                                        # (Temporary download files)
└── README.md                                    # This file
```

## 📥 Automatic Downloads

The installer handles:
- **llama.cpp**: Latest HIP build (b6423+)
- **Source**: `llama-b6423-bin-win-hip-radeon-x64.zip`
- **Size**: ~50MB compressed
- **Extraction**: Automatic with cleanup

Model launchers download:
- **Models**: Q4_K_M quantization (~15-17GB each)
- **Vision**: MMProj files for multimodal (~2GB each)
- **Cache**: `%USERPROFILE%\.cache\llama\`

## 🐛 Troubleshooting

### HIP Not Working
1. **Update AMD Drivers**: Latest Adrenalin software
2. **Check GPU**: Device Manager should show AMD GPU
3. **Environment**: Run `test-hip-gpu-detection.bat`
4. **Restart**: Reboot after driver updates

### Performance Issues
1. **Memory**: Monitor system RAM usage
2. **GPU Scheduling**: Enable in Windows Display settings
3. **Background Apps**: Close GPU-intensive programs
4. **Power**: Set to High Performance mode
5. **Thermal**: Ensure adequate cooling

### Download Failures
1. **Internet**: Check connection stability
2. **Space**: Ensure adequate disk space
3. **Firewall**: Allow Python/PowerShell through firewall
4. **Manual**: Download directly from Hugging Face if needed

### Server Won't Start
1. **Port**: Check if 8080 is already in use
2. **Files**: Verify model files downloaded completely
3. **Permissions**: Run as administrator if needed
4. **Logs**: Check console output for error messages

## 🎯 Expected Performance

### AMD 8945HS + Radeon 780M
- **Inference Speed**: 8-20 tokens/second (model dependent)
- **Memory Usage**: 15-20GB system RAM
- **GPU Utilization**: 60-90% on integrated graphics
- **Power Draw**: 45-65W total system

### Future AMD Ryzen AI MAX+ 395
- **Unified Memory**: 96GB available to GPU
- **Expected Speed**: 3-5x faster than 8945HS
- **Larger Models**: Support for Q8 or even F16 quantization
- **Multi-Model**: Potential for concurrent model serving

## 🔮 Advanced Usage

### Custom Configuration
Edit the `.bat` files to modify:
- **Context Size**: Adjust `CONTEXT_SIZE` variable
- **Sampling**: Modify temperature, top-k, top-p
- **Performance**: Change batch sizes and GPU layers
- **Network**: Bind to different host/port

### Multiple Models
- Run different models on different ports
- Modify port numbers in launcher scripts
- Use process management for model switching

### Monitoring
- **AMD Software**: Built-in GPU monitoring
- **Task Manager**: GPU utilization graphs  
- **Process Monitor**: File system activity
- **Network**: Monitor API usage

## 💡 Pro Tips

1. **First Time**: Run installer and detection script before models
2. **Large Models**: Ensure adequate RAM before starting
3. **Downloads**: Use stable internet connection for model downloads
4. **Updates**: Check for newer llama.cpp HIP builds periodically
5. **Backup**: Keep model cache when updating llama-server.exe

## 🆘 Getting Help

If you encounter issues:
1. Run `test-hip-gpu-detection.bat` and share output
2. Check AMD Software for GPU recognition
3. Verify Windows Device Manager shows AMD GPU
4. Try restarting after driver updates
5. Monitor system resources during operation

---

**🔥 HIP > Vulkan for AMD GPUs on Windows! 🚀**
