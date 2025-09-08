#!/usr/bin/env python3
"""
Simple ROCm GPU Test - Uses only basic ROCm tools
Based on: https://github.com/Toxantron/iGPU-Docker
"""

import subprocess
import sys
import os

def run_command(cmd, description):
    """Run a command and capture output"""
    print(f"\n🔍 {description}")
    print(f"Command: {cmd}")
    print("-" * 50)
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        if result.stdout:
            print("STDOUT:")
            print(result.stdout)
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        print(f"Return code: {result.returncode}")
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print("❌ Command timed out!")
        return False
    except Exception as e:
        print(f"❌ Error running command: {e}")
        return False

def main():
    print("🗿 AMD iGPU ROCm Docker Test")
    print("=" * 50)
    
    # Test 1: Check ROCm installation
    success1 = run_command("which rocm-smi", "Checking ROCm SMI availability")
    
    # Test 2: Check clinfo (OpenCL)
    success2 = run_command("clinfo", "Checking OpenCL devices")
    
    # Test 3: Try rocm-smi if available
    if success1:
        success3 = run_command("rocm-smi", "Checking ROCm System Management Interface")
    else:
        print("\n⚠️  rocm-smi not found, skipping GPU detection")
        success3 = False
    
    # Test 4: Check environment variables
    print("\n🌐 Environment Variables:")
    print("-" * 50)
    env_vars = [
        'HIP_VISIBLE_DEVICES', 
        'CUDA_VISIBLE_DEVICES', 
        'HSA_OVERRIDE_GFX_VERSION',
        'HCC_AMDGPU_TARGET',
        'ROCM_PATH',
        'HIP_PLATFORM'
    ]
    
    for var in env_vars:
        value = os.environ.get(var, 'Not set')
        print(f"{var}: {value}")
    
    # Test 5: Check if we're in a container with device access
    print("\n📁 Device Access Check:")
    print("-" * 50)
    
    devices = ['/dev/kfd', '/dev/dri/card0', '/dev/dri/renderD128']
    for device in devices:
        if os.path.exists(device):
            print(f"✅ {device} exists")
        else:
            print(f"❌ {device} not found (expected in Windows Docker)")
    
    # Summary
    print("\n📊 Summary:")
    print("=" * 50)
    
    if success2:  # clinfo worked
        print("✅ ROCm base installation appears functional")
        print("✅ OpenCL detection working")
        if success3:
            print("✅ ROCm SMI working")
        else:
            print("⚠️  ROCm SMI issues (might be due to no GPU access in Windows Docker)")
    else:
        print("❌ ROCm installation has issues")
    
    if not any(os.path.exists(d) for d in ['/dev/kfd', '/dev/dri']):
        print("ℹ️  No GPU devices found - this is expected in Windows Docker Desktop")
        print("ℹ️  Deploy to Linux with proper device access for full functionality")
    
    print("\n🎯 Next Steps:")
    if success2:
        print("- ROCm software stack is ready!")
        print("- For GPU acceleration, deploy to Linux with /dev/kfd and /dev/dri access")
        print("- Test with: docker run -it --rm --device=/dev/kfd --device=/dev/dri rocm-igpu:latest")
    else:
        print("- Check ROCm installation logs")
        print("- Verify container build completed successfully")

if __name__ == "__main__":
    main()
