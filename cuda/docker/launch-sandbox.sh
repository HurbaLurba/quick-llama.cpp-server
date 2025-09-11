#!/bin/bash

# LLaMA.cpp Sandbox Launch Script
# This script launches the sandbox container and provides instructions

echo "🚀 Launching LLaMA.cpp Sandbox Container..."

# Create the llama.cpp cache directory if it doesn't exist
CACHE_DIR="$HOME/llama.cpp"
if [ ! -d "$CACHE_DIR" ]; then
    echo "📁 Creating cache directory: $CACHE_DIR"
    mkdir -p "$CACHE_DIR"
fi

# Launch the container
echo "🐳 Starting Docker container..."
docker-compose -f docker-compose.sandbox.yml up -d

# Wait a moment for container to be ready
sleep 2

# Check if container is running
if docker ps | grep -q "llama-sandbox"; then
    echo "✅ Sandbox container is running!"
    echo ""
    echo "🎯 Quick Commands:"
    echo "   Connect:    docker exec -it llama-sandbox bash"
    echo "   Stop:       docker-compose -f docker-compose.sandbox.yml down"
    echo "   Logs:       docker-compose -f docker-compose.sandbox.yml logs -f"
    echo ""
    echo "📝 Inside the container, you can run:"
    echo "   /app/llama-server --help                  # Show server options"
    echo "   /app/llama-cli --help                     # Show CLI options"
    echo "   huggingface-cli --help                    # Show HF downloader help"
    echo "   nvidia-smi                                # Check GPU status"
    echo ""
    echo "💡 Example: Download and run a model:"
    echo "   huggingface-cli download microsoft/Phi-3.5-mini-instruct-gguf Phi-3.5-mini-instruct-q4_k_m.gguf"
    echo "   /app/llama-server -hf microsoft/Phi-3.5-mini-instruct-gguf:Q4_K_M --host 0.0.0.0 --port 8080"
    echo ""
    echo "🌐 Server will be accessible at: http://localhost:8085"
    echo "📁 Models cached to: $CACHE_DIR"
else
    echo "❌ Failed to start sandbox container"
    docker-compose -f docker-compose.sandbox.yml logs
    exit 1
fi
