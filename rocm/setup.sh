#!/bin/bash
# Setup script for AMD iGPU Docker - based on Toxantron/iGPU-Docker

echo "🗿 AMD iGPU ROCm Docker Setup"
echo "Based on: https://github.com/Toxantron/iGPU-Docker"

# Get group IDs for render and video groups
RENDER_GROUP_ID=$(getent group render | cut -d: -f3 2>/dev/null)
VIDEO_GROUP_ID=$(getent group video | cut -d: -f3 2>/dev/null)

echo "📋 System Information:"
echo "   Render Group ID: ${RENDER_GROUP_ID:-Not found}"
echo "   Video Group ID: ${VIDEO_GROUP_ID:-Not found}"

# Create .env file for docker-compose
cat > .env << EOF
RENDER_GROUP_ID=${RENDER_GROUP_ID:-102}
VIDEO_GROUP_ID=${VIDEO_GROUP_ID:-44}
EOF

echo "✅ Created .env file with group IDs"

echo "🔧 Device Status:"
if [ -e "/dev/kfd" ]; then
    ls -la /dev/kfd
    echo "✅ KFD device available"
else
    echo "❌ KFD device not found - ROCm may not work"
fi

if [ -d "/dev/dri" ]; then
    ls -la /dev/dri/
    echo "✅ DRI devices available"
else
    echo "❌ DRI devices not found"
fi

echo ""
echo "🚀 To build and run:"
echo "   1. Build ROCm base image:"
echo "      docker build -f Dockerfile.rocm-base -t rocm-igpu:latest ."
echo ""
echo "   2. Test ROCm functionality:"
echo "      docker run -it --rm --device=/dev/kfd --device=/dev/dri --group-add=\${RENDER_GROUP_ID} --group-add=\${VIDEO_GROUP_ID} rocm-igpu:latest"
echo ""
echo "   3. Build and run LLaMA server:"
echo "      docker-compose build && docker-compose up"
