# Windows Native Vulkan AMD iGPU - LLaMA.cpp Server

Native Windows implementation for AMD GPU acceleration using Vulkan backend with llama.cpp server.

## 🌋 AMD GPU Support
- **Target Hardware**: AMD 8945HS with Radeon 780M integrated graphics
- **Backend**: Vulkan (native Windows)
- **Future Support**: AMD Ryzen AI MAX+ 395 with 96GB unified memory

## 🚀 Quick Start

### 1. Prerequisites
- **AMD Drivers**: Latest AMD Adrenalin drivers with Vulkan support
- **Vulkan SDK**: Download from [LunarG](https://vulkan.lunarg.com/)
- **Python 3.8+**: For model downloads
- **llama.cpp**: Windows Vulkan build (see setup instructions)

### 2. Setup
```batch
# Run the setup script
setup.bat

# This will:
# - Check for Vulkan SDK and AMD drivers
# - Install huggingface-hub for model downloads  
# - Guide you through llama.cpp download
```

### 3. Download llama.cpp Server
1. Go to [llama.cpp releases](https://github.com/ggerganov/llama.cpp/releases)
2. Download: `llama-*-bin-win-vulkan-x64.zip`
3. Extract `llama-server.exe` to this directory

### 4. Run Models

**Mistral Small 3.2 24B Vision:**
```batch
start-mistral-small-3.2-24b-vulkan-amd.bat
```

**Gemma 3 27B IT Abliterated Vision:**
```batch
start-gemma3-27b-it-abliterated-vulkan-amd.bat
```

## 📊 Performance Optimization

### AMD GPU Settings
- **Batch Size**: 2048 (optimized for iGPU)
- **Ubatch Size**: 512 (memory efficient)
- **GPU Layers**: -1 (all layers offloaded)
- **Cache Types**: Q4_0 for both K and V caches

### Windows Optimization Tips
1. **GPU Scheduling**: Enable in Windows Settings > System > Display > Graphics settings
2. **AMD Adrenalin**: Update to latest version with Vulkan 1.3 support
3. **Power Management**: Set to High Performance mode
4. **Close Background Apps**: Minimize GPU usage from other applications

## 🔧 Environment Variables

The batch files automatically set:
- `GGML_VULKAN=1`: Enable Vulkan backend
- `GGML_VULKAN_DEVICE=0`: Use first Vulkan device
- `AMD_VULKAN_ICD=RADV`: AMD Vulkan driver preference

## 📁 Directory Structure
```
vulkan-amd-igpu/windows/
├── setup.bat                                    # Setup and dependency check
├── start-mistral-small-3.2-24b-vulkan-amd.bat # Mistral launcher
├── start-gemma3-27b-it-abliterated-vulkan-amd.bat # Gemma launcher
├── llama-server.exe                             # (Download from releases)
└── README.md                                    # This file
```

## 🐛 Troubleshooting

### Vulkan Not Detected
- Install latest AMD Adrenalin drivers
- Verify Vulkan SDK installation
- Run `vulkaninfo --summary` to check device detection

### GPU Acceleration Not Working
- Check Windows Device Manager for AMD GPU
- Ensure GPU scheduling is enabled
- Monitor GPU usage with AMD Software or Task Manager

### Model Download Issues
- Verify internet connection
- Check huggingface-hub installation: `pip show huggingface-hub`
- Try manual download from Hugging Face Hub

### Performance Issues
- Reduce batch size to 1024 if memory limited
- Lower context size if needed
- Monitor system memory usage

## 🎯 Expected Performance
- **AMD 8945HS + Radeon 780M**: ~5-15 tokens/second depending on model size
- **Future AMD Ryzen AI MAX+ 395**: Significantly higher with 96GB unified memory

## 💡 Advanced Configuration

Edit the batch files to customize:
- Context size (`CONTEXT_SIZE`)
- Sampling parameters (`TEMPERATURE`, `TOP_K`, `TOP_P`)
- Cache types and sizes
- Network binding (`--host`, `--port`)

## 🔮 Future Enhancements
- PowerShell scripts with better error handling
- Automatic driver/SDK verification
- Performance monitoring integration
- Multi-model switching interface
