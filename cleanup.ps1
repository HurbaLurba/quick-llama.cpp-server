#!/usr/bin/env pwsh
# Project Maintenance and Cleanup Script

Write-Host "🧹 llama.cpp RTX 5090 Server - Project Cleanup" -ForegroundColor Cyan

# Clean up old containers and images
Write-Host "`n🗑️ Cleaning up old containers..." -ForegroundColor Yellow
docker container prune -f
docker image prune -f

# Remove old/unused images (keep base and current models)
Write-Host "`n🔄 Removing old model images..." -ForegroundColor Yellow
$oldImages = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { 
    $_ -match "quick-llamacpp-server" -or $_ -match "emx-llama" 
}
if ($oldImages) {
    $oldImages | ForEach-Object { docker image rm $_ -f }
}

# Organize files
Write-Host "`n📁 Organizing project files..." -ForegroundColor Yellow

# Move old documentation files
if (Test-Path "README-specialized.md") {
    Move-Item "README-specialized.md" "archive/README-specialized.md" -Force
    Write-Host "✅ Moved old documentation to archive/" -ForegroundColor Green
}

if (Test-Path "README_NEW.md") {
    Remove-Item "README_NEW.md" -Force
    Write-Host "✅ Removed old README_NEW.md" -ForegroundColor Green
}

if (Test-Path "README-base-image.md") {
    Remove-Item "README-base-image.md" -Force
    Write-Host "✅ Removed old base image README (moved to docs/)" -ForegroundColor Green
}

# Create archive directory if needed
if (-not (Test-Path "archive")) {
    New-Item -ItemType Directory -Path "archive" | Out-Null
}

# Verify project structure
Write-Host "`n📋 Project Structure:" -ForegroundColor Cyan
Write-Host "├── 📄 README.md (main documentation)" -ForegroundColor White
Write-Host "├── 📄 docker-compose.yml (orchestration)" -ForegroundColor White
Write-Host "├── 📄 build-all.ps1 (build automation)" -ForegroundColor White
Write-Host "├──  Dockerfile.base-llama-cpp (base image)" -ForegroundColor White
Write-Host "├── 🐳 Dockerfile.DavidAU-OpenAi-GPT-oss-20b-abliterated-uncensored" -ForegroundColor White
Write-Host "├── 🐳 Dockerfile.gemma3-27b-abliterated-vision" -ForegroundColor White
Write-Host "└── 📁 docs/" -ForegroundColor White
Write-Host "    ├── 📄 base-image.md (architecture guide)" -ForegroundColor Gray
Write-Host "    ├── 📄 models.md (model specifications)" -ForegroundColor Gray
Write-Host "    ├── 📄 api.md (usage examples)" -ForegroundColor Gray
Write-Host "    └── 📄 development.md (adding models)" -ForegroundColor Gray

# Display current images
Write-Host "`n🖼️ Current Docker Images:" -ForegroundColor Cyan
docker images | Where-Object { $_ -match "llama-base|gptoss|gemma3" }

# Display available containers
Write-Host "`n🚀 Available Commands:" -ForegroundColor Green
Write-Host "Build:     .\build-all.ps1" -ForegroundColor Gray
Write-Host "Run GPT:   docker-compose up gptoss" -ForegroundColor Gray  
Write-Host "Run Gem:   docker-compose up gemma3-vision" -ForegroundColor Gray
Write-Host "Run Both:  docker-compose up" -ForegroundColor Gray

Write-Host "`n✨ Project cleanup complete!" -ForegroundColor Green
