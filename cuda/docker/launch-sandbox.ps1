# LLaMA.cpp Sandbox Launch Script (PowerShell)
# This script launches the sandbox container and provides instructions

Write-Host "🚀 Launching LLaMA.cpp Sandbox Container..." -ForegroundColor Green

# Create the llama.cpp cache directory if it doesn't exist
$CacheDir = "$env:USERPROFILE\llama.cpp"
if (!(Test-Path $CacheDir)) {
    Write-Host "📁 Creating cache directory: $CacheDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

# Launch the container
Write-Host "🐳 Starting Docker container..." -ForegroundColor Blue
docker-compose -f docker-compose.sandbox.yml up -d

# Wait a moment for container to be ready
Start-Sleep -Seconds 2

# Check if container is running
$containerRunning = docker ps --filter "name=llama-sandbox" --format "table {{.Names}}" | Select-String "llama-sandbox"

if ($containerRunning) {
    Write-Host "✅ Sandbox container is running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Quick Commands:" -ForegroundColor Cyan
    Write-Host "   Connect:    docker exec -it llama-sandbox bash" -ForegroundColor White
    Write-Host "   Stop:       docker-compose -f docker-compose.sandbox.yml down" -ForegroundColor White
    Write-Host "   Logs:       docker-compose -f docker-compose.sandbox.yml logs -f" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Inside the container, you can run:" -ForegroundColor Cyan
    Write-Host "   /app/llama-server --help                  # Show server options" -ForegroundColor White
    Write-Host "   /app/llama-cli --help                     # Show CLI options" -ForegroundColor White
    Write-Host "   huggingface-cli --help                    # Show HF downloader help" -ForegroundColor White
    Write-Host "   nvidia-smi                                # Check GPU status" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Example: Download and run a model:" -ForegroundColor Cyan
    Write-Host "   huggingface-cli download microsoft/Phi-3.5-mini-instruct-gguf Phi-3.5-mini-instruct-q4_k_m.gguf" -ForegroundColor White
    Write-Host "   /app/llama-server -hf microsoft/Phi-3.5-mini-instruct-gguf:Q4_K_M --host 0.0.0.0 --port 8080" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Server will be accessible at: http://localhost:8085" -ForegroundColor Green
    Write-Host "📁 Models cached to: $CacheDir" -ForegroundColor Yellow
} else {
    Write-Host "❌ Failed to start sandbox container" -ForegroundColor Red
    docker-compose -f docker-compose.sandbox.yml logs
    exit 1
}
