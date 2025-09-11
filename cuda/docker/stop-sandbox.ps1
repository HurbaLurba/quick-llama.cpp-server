# Stop LLaMA.cpp Sandbox Container (PowerShell)

Write-Host "🛑 Stopping LLaMA.cpp Sandbox Container..." -ForegroundColor Yellow

docker-compose -f docker-compose.sandbox.yml down

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Sandbox container stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to stop sandbox container" -ForegroundColor Red
    exit 1
}
