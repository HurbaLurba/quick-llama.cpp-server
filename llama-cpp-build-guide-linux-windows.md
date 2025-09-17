# llama.cpp Multi-Backend Build Guide (Ubuntu)

## Overview

This guide walks you through compiling llama.cpp with multiple backend configurations (CUDA 13.0, Vulkan, Multi-backend, and CPU-only), placing builds in timestamped folders. Assumes a fresh Ubuntu system (WSL2 compatible).

---

## 1. Prerequisites

```bash
sudo apt update && sudo apt upgrade -y
```

### Install Build Tools & Libraries

```bash
sudo apt install -y build-essential cmake python3 python3-pip git libcurl4-openssl-dev libgomp1 curl

# Install BLAS libraries for CPU acceleration
sudo apt install -y libopenblas-dev liblapack-dev pkg-config

# Install additional dependencies for llama.cpp
sudo apt install -y ccache
```

### Update NVIDIA Drivers (Headless System)

```bash
# Check if Secure Boot is enabled
echo "Checking Secure Boot status..."
mokutil --sb-state 2>/dev/null || echo "mokutil not installed, assuming Secure Boot may be enabled"

# Download and install latest NVIDIA drivers
cd ~/cuda
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/580.82.09/NVIDIA-Linux-x86_64-580.82.09.run

# Kill all NVIDIA processes aggressively
sudo pkill -f nvidia
sudo pkill -f cuda
sudo fuser -k /dev/nvidia* 2>/dev/null || true

# Stop all NVIDIA services
sudo systemctl stop nvidia-persistenced 2>/dev/null || true
sudo systemctl disable nvidia-persistenced 2>/dev/null || true

# Force unload all NVIDIA modules (multiple attempts)
for i in {1..3}; do
    sudo rmmod nvidia-uvm 2>/dev/null || true
    sudo rmmod nvidia-drm 2>/dev/null || true  
    sudo rmmod nvidia-modeset 2>/dev/null || true
    sudo rmmod nvidia 2>/dev/null || true
    sleep 1
done

# Check if modules are still loaded and force if needed
if lsmod | grep -q nvidia; then
    echo "Warning: NVIDIA modules still loaded. Attempting forced removal..."
    sudo rmmod -f nvidia-uvm 2>/dev/null || true
    sudo rmmod -f nvidia-drm 2>/dev/null || true
    sudo rmmod -f nvidia-modeset 2>/dev/null || true
    sudo rmmod -f nvidia 2>/dev/null || true
fi

# Make executable and install (headless/no GUI) with module signing
chmod +x NVIDIA-Linux-x86_64-580.82.09.run

# First attempt: Try with module signing for Secure Boot
echo "Attempting installation with module signing for Secure Boot..."
sudo ./NVIDIA-Linux-x86_64-580.82.09.run \
    --silent \
    --no-questions \
    --accept-license \
    --disable-nouveau \
    --no-cc-version-check \
    --install-libglvnd \
    --module-signing-secret-key=/var/lib/shim-signed/mok/MOK.priv \
    --module-signing-public-key=/var/lib/shim-signed/mok/MOK.der

# If that fails, try without secure boot keys
if [ $? -ne 0 ]; then
    echo "First attempt failed. Trying without module signing..."
    sudo ./NVIDIA-Linux-x86_64-580.82.09.run \
        --silent \
        --no-questions \
        --accept-license \
        --disable-nouveau \
        --no-cc-version-check \
        --install-libglvnd \
        --no-kernel-module-source
    
    # If still failing, try with DKMS (handles signing automatically)
    if [ $? -ne 0 ]; then
        echo "Second attempt failed. Trying with DKMS..."
        sudo ./NVIDIA-Linux-x86_64-580.82.09.run \
            --silent \
            --no-questions \
            --accept-license \
            --disable-nouveau \
            --no-cc-version-check \
            --install-libglvnd \
            --dkms
    fi
fi

# Cleanup driver installer
rm NVIDIA-Linux-x86_64-580.82.09.run

# Load new modules and verify installation
sudo modprobe nvidia 2>/dev/null || echo "Module loading may require reboot due to Secure Boot"
nvidia-smi 2>/dev/null || echo "nvidia-smi failed - reboot may be required"

# Instructions for manual Secure Boot handling if needed
echo ""
echo "If installation failed due to Secure Boot:"
echo "1. Reboot and disable Secure Boot in BIOS/UEFI"
echo "2. Or run: sudo mokutil --disable-validation (requires reboot)"
echo "3. Or manually enroll the NVIDIA module signing key"
```

### Install CUDA 13.0 SDK

#### Step 1: Download CUDA 13.0

```bash
# Create cuda directory and navigate to it
mkdir -p ~/cuda && cd ~/cuda

# Download CUDA 13.0 for Ubuntu (adjust URL based on your Ubuntu version)
# For Ubuntu 22.04:
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
# For Ubuntu 20.04:
# wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb

# Install the keyring
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
```

#### Step 2: Install CUDA Toolkit 13.0

```bash
# Install specific CUDA 13.0 version
sudo apt-get install -y cuda-toolkit-13-0

# Alternative method if above doesn't work:
# Download the local installer directly
# wget https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda_13.0.0_515.43.04_linux.run
# sudo sh cuda_13.0.0_515.43.04_linux.run --toolkit --silent --override
```

- Add CUDA to your PATH:

    ```bash
    echo 'export PATH=/usr/local/cuda-13.0/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    source ~/.bashrc
    ```

- Reboot if required.

### Install Vulkan SDK

#### Step 1: Install Vulkan Drivers

```bash
# Install Vulkan drivers and tools
sudo apt update
sudo apt install -y vulkan-tools spirv-tools

# Install Mesa Vulkan drivers (for additional GPU support)
sudo apt install -y mesa-vulkan-drivers

# Install validation layers (package name updated in Ubuntu 24.04)
sudo apt install -y vulkan-utility-libraries-dev

# Clean up any APT repository warnings (optional)
sudo rm -f /etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list 2>/dev/null || true

# Verify Vulkan installation (headless compatible)
# Note: NVIDIA Vulkan support comes with the existing NVIDIA 580.82.07 drivers
vulkaninfo --summary || echo "Vulkan installed but may need display for full functionality"
```

#### Step 2: Install Vulkan SDK

```bash
# Clean up any problematic Vulkan repositories first
sudo rm -f /etc/apt/sources.list.d/lunarg-vulkan-jammy.list
sudo apt update

# Install Vulkan SDK from Ubuntu repositories (more reliable)
sudo apt install -y libvulkan-dev vulkan-validationlayers

# Install additional Vulkan development tools
sudo apt install -y glslang-tools libshaderc-dev

# Set Vulkan environment variables (Ubuntu package locations)
echo 'export VULKAN_SDK=/usr' >> ~/.bashrc
echo 'export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d' >> ~/.bashrc
source ~/.bashrc

# Verify Vulkan SDK installation
pkg-config --modversion vulkan || echo "Vulkan SDK installed via system packages"
```

---

## 2. Clone llama.cpp

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
```

---

## 3. Set Environment Variables

```bash
# Set explicit CUDA environment variables
export CUDA_ROOT=/usr/local/cuda-13.0
export CUDA_HOME=/usr/local/cuda-13.0
export PATH=/usr/local/cuda-13.0/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH

# Set CUDA visible devices
export CUDA_VISIBLE_DEVICES=0,1,2

# Verify environment
nvcc --version
vulkaninfo --summary
```

---

## 4. Build Configurations

### A. CUDA13 Build (Strict CUDA + Minimal CPU)

```bash
# Create timestamped CUDA build folder
BUILD_DIR="CUDA13_$(date +%Y_%m_%d_%H_%M)"
mkdir "$BUILD_DIR" && cd "$BUILD_DIR"

# Clear any cached configuration
rm -rf CMakeCache.txt CMakeFiles/

# Configure for CUDA only with minimal CPU features
cmake .. \
  -DGGML_CUDA=ON \
  -DGGML_CUBLAS=ON \
  -DGGML_FORCE_CUBLAS=ON \
  -DGGML_RPC=ON \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=ON \
  -DGGML_CPU_ALL_VARIANTS=ON \
  -DGGML_CCACHE=OFF \
  -DCMAKE_CUDA_ARCHITECTURES="86;89;90" \
  -DLLAMA_CURL=ON \
  -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release -j$(nproc)

# Test
./bin/llama-server --help
cd ..
```

### B. VULKAN Build (Strict Vulkan + Minimal CPU)

```bash
# Create timestamped Vulkan build folder
BUILD_DIR="VULKAN_$(date +%Y_%m_%d_%H_%M)"
mkdir "$BUILD_DIR" && cd "$BUILD_DIR"

# Clear any cached configuration
rm -rf CMakeCache.txt CMakeFiles/

# Configure for Vulkan only with minimal CPU features
cmake .. \
  -DGGML_VULKAN=ON \
  -DGGML_CUDA=OFF \
  -DGGML_RPC=ON \
  -DGGML_CURL=ON \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=ON \
  -DGGML_CPU_ALL_VARIANTS=ON \
  -DGGML_CCACHE=OFF \
  -DLLAMA_CURL=ON \
  -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release -j$(nproc)

# Test
./bin/llama-server --help
cd ..
```

### C. MULTI Build (CUDA + Vulkan + All Features + Minimal CPU)

```bash
# Create timestamped Multi build folder
BUILD_DIR="MULTI_$(date +%Y_%m_%d_%H_%M)"
mkdir "$BUILD_DIR" && cd "$BUILD_DIR"

# Clear any cached configuration
rm -rf CMakeCache.txt CMakeFiles/

# Configure with all backends except maximal CPU (GPU-optimized)
cmake .. \
  -DGGML_VULKAN=ON \
  -DGGML_CUDA=ON \
  -DGGML_CUBLAS=ON \
  -DGGML_FORCE_CUBLAS=ON \
  -DGGML_RPC=ON \
  -DGGML_CURL=ON \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=ON \
  -DGGML_CPU_ALL_VARIANTS=ON \
  -DGGML_CCACHE=OFF \
  -DCMAKE_CUDA_ARCHITECTURES="86;89;90" \
  -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release -j$(nproc)

# Test
./bin/llama-server --help
cd ..
```

### D. CPU Build (No CUDA/Vulkan + All CPU Features)

```bash
# Create timestamped CPU build folder
BUILD_DIR="CPU_$(date +%Y_%m_%d_%H_%M)"
mkdir "$BUILD_DIR" && cd "$BUILD_DIR"

# Clear any cached configuration
rm -rf CMakeCache.txt CMakeFiles/

# Configure for CPU only with all CPU optimizations
cmake .. \
  -DGGML_CUDA=OFF \
  -DGGML_VULKAN=OFF \
  -DGGML_OPENGL=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=ON \
  -DGGML_CPU_ALL_VARIANTS=ON \
  -DGGML_CCACHE=OFF \
  -DLLAMA_RPC=ON \
  -DLLAMA_CURL=ON \
  -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release -j$(nproc)

# Test
./bin/llama-server --help
cd ..
```

---

## 5. Verify All Builds

```bash
# List all build directories
ls -la */bin/llama-server

# Test each build
for build_dir in CUDA13_* VULKAN_* MULTI_* CPU_* CUDA13_CPU_* VULKAN_CPU_* MULTI_CPU_*; do
    echo "Testing $build_dir:"
    ./$build_dir/bin/llama-server --help | head -5
    echo ""
done
```

---

## 6. (Optional) Clean Up

```bash
# Clean specific build directories
make clean -C CUDA13_*/
make clean -C VULKAN_*/  
make clean -C MULTI_*/
make clean -C CPU_*/
make clean -C CUDA13_CPU_*/
make clean -C VULKAN_CPU_*/
make clean -C MULTI_CPU_*/

# Or clean all builds
for build_dir in CUDA13_* VULKAN_* MULTI_* CPU_* CUDA13_CPU_* VULKAN_CPU_* MULTI_CPU_*; do
    make clean -C "$build_dir/"
done
```

---

## 7. Troubleshooting

### Linux CUDA Issues

**"ggml_cuda_init: failed to initialize CUDA"**:

  unknown error

  ```bash
  # Check GPU status and permissions
  nvidia-smi
  ls -la /dev/nvidia*
  
  # Fix GPU device permissions (common issue)
  sudo chmod 666 /dev/nvidia*
  sudo chmod 666 /dev/nvidiactl
  sudo chmod 666 /dev/nvidia-modeset
  
  # Set NVIDIA persistence daemon
  sudo nvidia-smi -pm 1
  
  # Test CUDA context creation directly
  cd /usr/local/cuda-13.0/samples/1_Utilities/deviceQuery
  sudo make
  ./deviceQuery
  
  # If deviceQuery fails, try reloading drivers
  sudo rmmod nvidia_uvm nvidia_drm nvidia_modeset nvidia
  sudo modprobe nvidia nvidia_modeset nvidia_drm nvidia_uvm
  
  # Set CUDA environment and test again
  export CUDA_VISIBLE_DEVICES=0,1,2
  export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH
  ./bin/llama-server --help
  ```

**"no usable GPU found" (after successful CUDA linking)**:

  ```bash
  # Check driver version compatibility
  cat /proc/driver/nvidia/version
  nvcc --version
  
  # Verify CUDA context can be created
  python3 -c "import ctypes; libcuda = ctypes.CDLL('libcuda.so.1'); print('CUDA library loaded:', libcuda)"
  
  # Add user to render group (additional permission)
  sudo usermod -a -G render $USER
  newgrp render
  
  # If still failing, try forcing GPU initialization
  export CUDA_FORCE_PTX_JIT=1
  export CUDA_CACHE_DISABLE=1
  ./bin/llama-server --help
  ```

**If CUDA libraries not found in ldd output**:

  Build system not finding CUDA

  ```bash
  # Check if CMake detected CUDA properly
  cd ~/llama.cpp/build-$(date +%Y-%m-%d)
  grep -i cuda CMakeCache.txt
  
  # If CUDA not detected, force CMake to find it
  rm -rf CMakeCache.txt CMakeFiles/
  export CUDA_ROOT=/usr/local/cuda-13.0
  export CUDA_HOME=/usr/local/cuda-13.0
  export PATH=/usr/local/cuda-13.0/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH
  
  # Configure with explicit CUDA paths
  cmake .. \
    -DGGML_CUDA=ON \
    -DGGML_CUBLAS=ON \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-13.0 \
    -DCUDAToolkit_ROOT=/usr/local/cuda-13.0 \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_SERVER=ON
  
  # Build with verbose output to see CUDA linking
  make VERBOSE=1 -j$(nproc) | tee build.log
  
  # Verify CUDA is actually linked this time
  ldd ./bin/llama-server | grep -i cuda
  objdump -T ./bin/llama-server | grep -i cuda | head -10
  ```

**If CUDA version mismatch**:

  ```bash
  # Verify CUDA 13.0 installation
  ls -la /usr/local/cuda-13.0/
  export PATH=/usr/local/cuda-13.0/bin:$PATH
  export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:$LD_LIBRARY_PATH
  ```

### Linux Vulkan Issues

**"Vulkan not found" or "Failed to initialize Vulkan"**:

  ```bash
  # Check Vulkan installation
  vulkaninfo --summary
  
  # Verify Vulkan drivers
  ls -la /usr/lib/x86_64-linux-gnu/libvulkan.so*
  
  # Check Vulkan layers
  vulkaninfo | grep -i layer
  
  # Set Vulkan environment variables
  export VULKAN_SDK=/usr
  export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d
  
  # Test Vulkan functionality
  vkcube # Should open a spinning cube window
  ```

**"No Vulkan-compatible GPU found"**:

  ```bash
  # Check GPU Vulkan support
  vulkaninfo | grep -A5 "GPU id"
  
  # Verify GPU drivers support Vulkan
  nvidia-smi # For NVIDIA GPUs
  glxinfo | grep -i renderer # For general GPU info
  
  # Note: Your existing NVIDIA 580.82.07 drivers should support Vulkan
  # Only install Mesa drivers for additional compatibility
  sudo apt install -y mesa-vulkan-drivers # Mesa/AMD/Intel
  
  # Ensure NVIDIA driver is loaded
  sudo modprobe nvidia
  ```

**"Build fails with Vulkan errors"**:

  ```bash
  # Install Vulkan development packages (updated package names)
  sudo apt install -y libvulkan-dev vulkan-utility-libraries-dev
  
  # Check Vulkan SDK components
  pkg-config --modversion vulkan
  
  # Rebuild with verbose output
  make VERBOSE=1 -j$(nproc) 2>&1 | grep -i vulkan
  ```

### Build Issues

- If CUDA is not detected during build, check your PATH and LD_LIBRARY_PATH.
- For missing libraries, rerun the install commands above.
- Use `make VERBOSE=1 -j$(nproc)` to see detailed compilation output.

---

## References

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [NVIDIA CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)
- [Vulkan SDK Download](https://vulkan.lunarg.com/sdk/home)
- [Vulkan Ubuntu Installation Guide](https://packages.lunarg.com/)

---

## Windows Build Instructions

### Prerequisites

### Assumptions

- **Visual Studio 2022** with MSVC v143 compiler (msvc64) is installed
- **CUDA 13.0** is installed and available in PATH
- **Vulkan SDK** is installed
- **vcpkg** is installed but **curl is NOT installed** in VCPKG_ROOT
- **Git** is available
- **PowerShell** or **Command Prompt** access

### Required Environment Variables

```powershell
# Verify these are set (adjust paths as needed)
$env:CUDA_PATH          # Should point to CUDA installation
$env:VULKAN_SDK         # Should point to Vulkan SDK
$env:VCPKG_ROOT         # Should point to vcpkg installation
```

## 1. Install curl via vcpkg

```powershell
# Install curl with static linking
& "$env:VCPKG_ROOT\vcpkg.exe" install curl:x64-windows-static-md

# Verify installation
& "$env:VCPKG_ROOT\vcpkg.exe" list | Select-String "curl"
```

## 2. Clone and Prepare llama.cpp

```powershell
# Clone the repository
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Create build directory
mkdir builds
cd builds
```

## 3. Build Configurations

### A. CUDA13 Build (CUDA + Minimal CPU)

```powershell
# initialize visual studio environment (allows the use of cl, cmake, etc.)
msvc64

# Create timestamped CUDA build folder
$BUILD_DIR = "CUDA13_$(Get-Date -Format 'yyyy_MM_dd_HH_mm')"
mkdir $BUILD_DIR
cd $BUILD_DIR

# Clear any cached configuration
Remove-Item -Force -Recurse -Path CMakeCache.txt, CMakeFiles -ErrorAction SilentlyContinue

# Configure for CUDA with minimal CPU features (GPU-optimized)
cmake .. `
  -DGGML_CUDA=ON `
  -DGGML_CUBLAS=ON `
  -DGGML_FORCE_CUBLAS=ON `
  -DGGML_NATIVE=OFF `
  -DGGML_BACKEND_DL=ON `
  -DGGML_CPU_ALL_VARIANTS=ON `
  -DGGML_CCACHE=OFF `
  -DCMAKE_CUDA_ARCHITECTURES="86;89;90" `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_CURL=ON `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-md `
  -DCMAKE_PREFIX_PATH="$env:VCPKG_ROOT\installed\x64-windows-static-md" `
  -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release --parallel

# Test
.\bin\Release\llama-server.exe --help
cd ..
```

### B. VULKAN Build (Vulkan + Minimal CPU)

```powershell
# initialize visual studio environment (allows the use of cl, cmake, etc.)
msvc64

# Create timestamped Vulkan build folder
$BUILD_DIR = "VULKAN_$(Get-Date -Format 'yyyy_MM_dd_HH_mm')"
mkdir $BUILD_DIR
cd $BUILD_DIR

# Clear any cached configuration
Remove-Item -Force -Recurse -Path CMakeCache.txt, CMakeFiles -ErrorAction SilentlyContinue

# Configure for Vulkan only with minimal CPU features
cmake .. `
  -DGGML_VULKAN=ON `
  -DGGML_CUDA=OFF `
  -DGGML_NATIVE=OFF `
  -DGGML_BACKEND_DL=ON `
  -DGGML_CPU_ALL_VARIANTS=ON `
  -DGGML_CCACHE=OFF `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_RPC=ON `
  -DLLAMA_CURL=ON `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-md `
  -DCMAKE_PREFIX_PATH="$env:VCPKG_ROOT\installed\x64-windows-static-md" `
  -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release --parallel

# Test
.\bin\Release\llama-server.exe --help
cd ..
```

### C. MULTI Build (CUDA + Vulkan + All Features + Minimal CPU)

```powershell
# Create timestamped Multi build folder
$BUILD_DIR = "MULTI_$(Get-Date -Format 'yyyy_MM_dd_HH_mm')"
mkdir $BUILD_DIR
cd $BUILD_DIR

# Clear any cached configuration
Remove-Item -Force -Recurse -Path CMakeCache.txt, CMakeFiles -ErrorAction SilentlyContinue

# Configure with all backends except maximal CPU (GPU-optimized)
cmake .. `
  -DGGML_VULKAN=ON `
  -DGGML_CUDA=ON `
  -DGGML_CUBLAS=ON `
  -DGGML_FORCE_CUBLAS=ON `
  -DGGML_NATIVE=OFF `
  -DGGML_BACKEND_DL=ON `
  -DGGML_CPU_ALL_VARIANTS=ON `
  -DGGML_CCACHE=OFF `
  -DCMAKE_CUDA_ARCHITECTURES="86;89;90" `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_RPC=ON `
  -DLLAMA_CURL=ON `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-md `
  -DCMAKE_PREFIX_PATH="$env:VCPKG_ROOT\installed\x64-windows-static-md" `
  -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release --parallel

# Test
.\bin\Release\llama-server.exe --help
cd ..
```

### D. CPU Build (No CUDA/Vulkan + All CPU Features)

```powershell
# initialize visual studio environment (allows the use of cl, cmake, etc.)
msvc64

# Create timestamped CPU build folder
$BUILD_DIR = "CPU_$(Get-Date -Format 'yyyy_MM_dd_HH_mm')"
mkdir $BUILD_DIR
cd $BUILD_DIR

# Clear any cached configuration
Remove-Item -Force -Recurse -Path CMakeCache.txt, CMakeFiles -ErrorAction SilentlyContinue

# Configure for CPU only with all CPU optimizations (BF16 disabled for MSVC compatibility)
cmake .. `
  -DGGML_VULKAN=OFF `
  -DGGML_CUDA=OFF `
  -DGGML_CUBLAS=OFF `
  -DGGML_FORCE_CUBLAS=OFF `
  -DGGML_NATIVE=OFF `
  -DGGML_BACKEND_DL=ON `
  -DGGML_CPU_ALL_VARIANTS=ON `
  -DGGML_CCACHE=OFF `
  -DCMAKE_BUILD_TYPE=Release `
  -DLLAMA_RPC=ON `
  -DLLAMA_CURL=ON `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
  -DVCPKG_TARGET_TRIPLET=x64-windows-static-md `
  -DCMAKE_PREFIX_PATH="$env:VCPKG_ROOT\installed\x64-windows-static-md" `
  -G "Visual Studio 17 2022" -A x64

# Build
cmake --build . --config Release --parallel

# Test
.\bin\Release\llama-server.exe --help
cd ..
```

## 4. Verify All Builds

```powershell
# List all build directories
Get-ChildItem -Directory | Where-Object { $_.Name -match "CUDA13|VULKAN|MULTI|CPU" }

# Test each build
$buildDirs = Get-ChildItem -Directory | Where-Object { 
    $_.Name -match "^(CUDA13|VULKAN|MULTI|CPU)" 
}

foreach ($buildDir in $buildDirs) {
    Write-Host "Testing $($buildDir.Name):" -ForegroundColor Green
    & ".\$($buildDir.Name)\bin\Release\llama-server.exe" --help | Select-Object -First 5
    Write-Host ""
}
```

## 5. (Optional) Clean Up

```powershell
# Clean specific build directories
$buildTypes = @("CUDA13_*", "VULKAN_*", "MULTI_*", "CPU_*")

foreach ($buildType in $buildTypes) {
    Get-ChildItem -Directory -Name $buildType | ForEach-Object {
        cmake --build $_ --target clean --config Release
    }
}

# Or remove all build directories
Remove-Item -Recurse -Force CUDA13_*, VULKAN_*, MULTI_*, CPU_*
```

## 6. Windows-Specific Troubleshooting

### Windows CUDA Issues

- **CUDA not found**: Verify `$env:CUDA_PATH` points to CUDA 13.0 installation
- **CUDA libraries not linking**: Check that CUDA 13.0 is in your system PATH

### Windows Vulkan Issues  

- **Vulkan SDK not found**: Verify `$env:VULKAN_SDK` is set correctly
- **Vulkan validation layers**: Ensure Vulkan SDK is properly installed

### vcpkg Issues

- **curl not found**: Install curl with `vcpkg install curl:x64-windows-static-md`
- **Toolchain not found**: Verify `$env:VCPKG_ROOT` points to your vcpkg installation
- **Static linking issues**: Ensure you're using `x64-windows-static-md` triplet consistently

#### vcpkg Manifest Mode Issues

If you encounter vcpkg manifest mode errors, follow these steps:

1. **"Could not locate a manifest (vcpkg.json)" error**:

   ```powershell
   # Create vcpkg.json in your llama.cpp directory
   @'
   {
     "name": "llama-cpp",
     "version-string": "1.0.0",
     "builtin-baseline": "4f8fe05871555c1798dbcb1957d0d595e94f7b57",
     "dependencies": [
       {
         "name": "curl",
         "features": ["ssl"]
       }
     ]
   }
   '@ | Out-File -FilePath "vcpkg.json" -Encoding UTF8
   ```

2. **"builtin-baseline was not a valid commit sha" error**:
   - Use the commit SHA that vcpkg suggests in the error message
   - Update the `builtin-baseline` field in vcpkg.json with the suggested SHA

3. **Enable vcpkg integration** (if not already done):

   ```powershell
   cd "$env:VCPKG_ROOT"
   .\vcpkg.exe integrate install
   ```

4. **Install dependencies**:

   ```powershell
   cd C:\path\to\llama.cpp
   & "$env:VCPKG_ROOT\vcpkg.exe" install --triplet x64-windows-static-md
   ```

5. **Verify curl installation**:

   ```powershell
   & "$env:VCPKG_ROOT\vcpkg.exe" list | Select-String "curl"
   ```

### Visual Studio Issues

- **Generator not found**: Ensure Visual Studio 2022 with C++ workload is installed
- **MSVC not found**: Verify MSVC v143 compiler toolset is installed
- **Build failures**: Try building from Visual Studio Developer Command Prompt

### Performance Notes

- Windows builds may be slower than Linux equivalents
- Consider using `/MP` flag for parallel compilation if needed
- Release builds provide significantly better performance than Debug builds
