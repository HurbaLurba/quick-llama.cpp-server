#!/bin/bash
# Vulkan Diagnostic Script for AMD GPU Detection
echo "🔍 Direct Vulkan API Test..."

# Test 1: Basic Vulkan instance creation
echo "🌋 Testing Vulkan instance creation..."
python3 -c "
import ctypes
import os
import sys

# Load Vulkan library
try:
    vulkan = ctypes.CDLL('/usr/lib/x86_64-linux-gnu/libvulkan.so.1')
    print('✅ Vulkan library loaded successfully')
except:
    print('❌ Failed to load Vulkan library')
    sys.exit(1)

# Test basic Vulkan function
try:
    vkEnumerateInstanceVersion = vulkan.vkEnumerateInstanceVersion
    vkEnumerateInstanceVersion.restype = ctypes.c_int
    vkEnumerateInstanceVersion.argtypes = [ctypes.POINTER(ctypes.c_uint32)]
    
    version = ctypes.c_uint32()
    result = vkEnumerateInstanceVersion(ctypes.byref(version))
    
    if result == 0:
        print(f'✅ Vulkan API version: {version.value >> 22}.{(version.value >> 12) & 0x3ff}.{version.value & 0xfff}')
    else:
        print(f'❌ vkEnumerateInstanceVersion failed: {result}')
except Exception as e:
    print(f'❌ Vulkan API test failed: {e}')
" 2>/dev/null

# Test 2: Check environment variables that might affect Vulkan
echo "🔧 Critical Vulkan Environment Variables:"
echo "   VK_ICD_FILENAMES: ${VK_ICD_FILENAMES:-NOT SET}"
echo "   VK_DRIVER_FILES: ${VK_DRIVER_FILES:-NOT SET}"
echo "   LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-NOT SET}"

# Test 3: Check if container has proper permissions
echo "🔐 Container Permission Check:"
echo "   Current user: $(whoami)"
echo "   Current groups: $(groups)"
echo "   DRI access test:"
ls -la /dev/dri/ | head -5

# Test 4: Try to manually load Vulkan drivers
echo "🔍 Manual Vulkan Driver Test:"
if [ -f "/usr/lib/x86_64-linux-gnu/libvulkan_radeon.so" ]; then
    echo "✅ AMD Vulkan driver exists"
    # Check if it can be loaded
    ldd /usr/lib/x86_64-linux-gnu/libvulkan_radeon.so 2>/dev/null | head -5 || echo "❌ Driver dependency check failed"
else
    echo "❌ AMD Vulkan driver not found"
fi

echo "🚀 Diagnostic complete!"
