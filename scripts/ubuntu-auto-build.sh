#!/bin/bash

# LLaMA.cpp CUDA 13.0.1 Automated Build Script for Ubuntu
# This script automatically updates llama.cpp, builds Docker image, and pushes to Docker Hub
# Designed to run on cron every other day at 2AM ET

set -e  # Exit on any error

# Configuration
DOCKER_HUB_USERNAME="philglod"
IMAGE_NAME="llamacpp-cuda13-modern-full"
DOCKERFILE_PATH="docker/cuda-13.0.1-custom.Dockerfile"
BUILD_TARGET="full"
LOG_DIR="/var/log/llamacpp-auto-build"
LOG_FILE="${LOG_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
error_exit() {
    log "ERROR: $1"
    exit 1
}

log "Starting automated LLaMA.cpp build process"

# Check if we're in the right directory
if [ ! -f "$DOCKERFILE_PATH" ]; then
    error_exit "Dockerfile not found at $DOCKERFILE_PATH. Please run from repository root."
fi

# Update the main repository
log "Updating main repository..."
git fetch origin || error_exit "Failed to fetch from origin"
git pull origin main || error_exit "Failed to pull latest changes"

# Update llama.cpp submodule
log "Updating llama.cpp submodule..."
cd llama.cpp || error_exit "llama.cpp directory not found"

# Get current commit hash before update
OLD_COMMIT=$(git rev-parse HEAD)
log "Current llama.cpp commit: $OLD_COMMIT"

# Update to latest llama.cpp
git fetch origin || error_exit "Failed to fetch llama.cpp updates"
git checkout main || error_exit "Failed to checkout main branch"
git pull origin main || error_exit "Failed to pull llama.cpp updates"

# Get new commit hash after update
NEW_COMMIT=$(git rev-parse HEAD)
log "New llama.cpp commit: $NEW_COMMIT"

# Go back to repository root
cd ..

# Check if there's actually an update
if [ "$OLD_COMMIT" = "$NEW_COMMIT" ]; then
    log "No new llama.cpp updates. Current commit: $NEW_COMMIT"
    
    # Check if our image already exists on Docker Hub for this commit
    if docker manifest inspect "$DOCKER_HUB_USERNAME/$IMAGE_NAME:$NEW_COMMIT" >/dev/null 2>&1; then
        log "Image already exists on Docker Hub for commit $NEW_COMMIT. Skipping build."
        exit 0
    else
        log "Image doesn't exist on Docker Hub for commit $NEW_COMMIT. Building anyway."
    fi
else
    log "New llama.cpp update detected! Building new image..."
fi

# Build the Docker image
log "Building Docker image..."
docker build \
    -t "$IMAGE_NAME:latest" \
    -t "$IMAGE_NAME:$NEW_COMMIT" \
    --target "$BUILD_TARGET" \
    -f "$DOCKERFILE_PATH" \
    . || error_exit "Docker build failed"

log "Docker build completed successfully"

# Tag for Docker Hub
log "Tagging images for Docker Hub..."
docker tag "$IMAGE_NAME:latest" "$DOCKER_HUB_USERNAME/$IMAGE_NAME:latest" || error_exit "Failed to tag latest"
docker tag "$IMAGE_NAME:$NEW_COMMIT" "$DOCKER_HUB_USERNAME/$IMAGE_NAME:$NEW_COMMIT" || error_exit "Failed to tag commit"

# Test the image quickly
log "Testing image functionality..."
docker run --rm --gpus all "$DOCKER_HUB_USERNAME/$IMAGE_NAME:latest" --help >/dev/null || error_exit "Image test failed"

log "Image test passed"

# Push to Docker Hub
log "Pushing images to Docker Hub..."
docker push "$DOCKER_HUB_USERNAME/$IMAGE_NAME:latest" || error_exit "Failed to push latest tag"
docker push "$DOCKER_HUB_USERNAME/$IMAGE_NAME:$NEW_COMMIT" || error_exit "Failed to push commit tag"

log "Successfully pushed to Docker Hub:"
log "  - $DOCKER_HUB_USERNAME/$IMAGE_NAME:latest"
log "  - $DOCKER_HUB_USERNAME/$IMAGE_NAME:$NEW_COMMIT"

# Clean up old images (keep last 3 builds)
log "Cleaning up old Docker images..."
OLD_IMAGES=$(docker images "$DOCKER_HUB_USERNAME/$IMAGE_NAME" --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | grep -v "latest" | tail -n +4 | awk '{print $1}')
if [ ! -z "$OLD_IMAGES" ]; then
    echo "$OLD_IMAGES" | xargs -r docker rmi || log "Warning: Failed to clean up some old images"
    log "Cleaned up old images"
else
    log "No old images to clean up"
fi

# Update build status file
echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully for commit $NEW_COMMIT" > "$LOG_DIR/last-successful-build.txt"

log "Automated build process completed successfully!"
log "Build log saved to: $LOG_FILE"

exit 0