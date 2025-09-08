#!/bin/bash
# Setup script for AMD iGPU Vulkan Docker - based on Toxantron/iGPU-Docker methodology

echo "🌋 AMD iGPU Vulkan Docker Setup"
echo "Based on: https://github.com/Toxantron/iGPU-Docker methodology"

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
if [ -d "/dev/dri" ]; then
    ls -la /dev/dri/
    echo "✅ DRI devices available"
else
    echo "❌ DRI devices not found"
fi

echo ""
echo "🚀 To build and run:"
echo "   docker-compose build && docker-compose up"
