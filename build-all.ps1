#!/usr/bin/env pwsh
# Build script for llama.cpp RTX 5090 Server - Production Ready

param(
    [switch]$Clean,
    [switch]$BaseOnly,
    [switch]$Quiet
)

if (-not $Quiet) {
    Write-Host "🚀 llama.cpp RTX 40/50 series Server - Build System" -ForegroundColor Cyan
    Write-Host "   High-performance containers with reasoning support" -ForegroundColor Gray
}

# Clean old images if requested
if ($Clean) {
    Write-Host "`n🧹 Cleaning old images..." -ForegroundColor Yellow
    docker image prune -f | Out-Null
    docker container prune -f | Out-Null
}

# Build the base image first (this takes the longest but only needs to be done once)
if (-not $Quiet) { Write-Host "`n📦 Building base llama.cpp image..." -ForegroundColor Yellow }
Write-Host "   ⏱️  This may take 10-15 minutes on first build" -ForegroundColor Gray
Write-Host "   🔧 Compiling with RTX 40/50 series optimizations (CUDA 9.0)" -ForegroundColor Gray
Write-Host "   ⚡ Flash Attention enabled for memory efficiency" -ForegroundColor Gray

$startTime = Get-Date
docker build -f Dockerfile.base-llama-cpp -t llama-base:latest . $(if ($Quiet) { "--quiet" })

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build base image" -ForegroundColor Red
    exit 1
}

$buildTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
Write-Host "✅ Base image built successfully! ($buildTime min)" -ForegroundColor Green

if ($BaseOnly) {
    Write-Host "`n🎯 Base-only build complete!" -ForegroundColor Cyan
    exit 0
}

# Build GPT-OSS container (fast since it uses the base)
if (-not $Quiet) { Write-Host "`n🧠 Building GPT-OSS reasoning container..." -ForegroundColor Yellow }
Write-Host "   📋 Model: DavidAU OpenAI GPT-OSS 20B Abliterated" -ForegroundColor Gray
Write-Host "   🤔 Features: Deep reasoning, thinking extraction" -ForegroundColor Gray

docker build -f Dockerfile.DavidAU-OpenAi-GPT-oss-20b-abliterated-uncensored -t gptoss . $(if ($Quiet) { "--quiet" })

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build GPT-OSS container" -ForegroundColor Red
    exit 1
}

Write-Host "✅ GPT-OSS container built successfully!" -ForegroundColor Green

# Build Gemma 3 container (fast since it uses the base)
if (-not $Quiet) { Write-Host "`n👁️ Building Gemma 3 DPO vision + reasoning container..." -ForegroundColor Yellow }
Write-Host "   📋 Model: Gemma 3 27B Abliterated with Vision" -ForegroundColor Gray
Write-Host "   🧠 Features: Deep reasoning, vision understanding, thinking extraction" -ForegroundColor Gray

docker build -f Dockerfile.gemma3-27b-abliterated-vision -t gemma3-vision . $(if ($Quiet) { "--quiet" })

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build Gemma 3 Vision container" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Gemma 3 Vision container built successfully!" -ForegroundColor Green

# Show build information
Write-Host "`n📊 Build Summary:" -ForegroundColor Cyan
Write-Host "Base Image:  llama-base:latest" -ForegroundColor White
Write-Host "GPT-OSS:     gptoss" -ForegroundColor White
Write-Host "Gemma 3: gemma3-vision" -ForegroundColor White

Write-Host "`n🔥 Ready to run!" -ForegroundColor Green
Write-Host "Use: docker-compose up gptoss" -ForegroundColor Gray
Write-Host "  or: docker-compose up gemma3-vision" -ForegroundColor Gray
Write-Host "  or: docker-compose up" -ForegroundColor Gray

# Show image sizes
Write-Host "`n💾 Image sizes:" -ForegroundColor Yellow
docker images | Where-Object { $_ -match "llama-base|gptoss|gemma3" }
