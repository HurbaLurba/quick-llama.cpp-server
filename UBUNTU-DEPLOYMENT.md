# Ubuntu Server Deployment Guide

This directory contains scripts and configurations for automated Docker Hub builds on Ubuntu servers.

## Files in this Setup

### Scripts
- `scripts/ubuntu-auto-build.sh` - Main automated build script
- `scripts/setup-cron.sh` - Cron job installation script

### Docker
- `docker/docker-compose.ubuntu.yml` - Production Docker Compose for Ubuntu
- `docker/cuda-13.0.1-custom.Dockerfile` - Custom CUDA 13.0.1 Dockerfile

## Quick Setup on Ubuntu Server

### 1. Prerequisites
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### 2. Clone Repository
```bash
cd /home/du
git clone https://github.com/ergonomech/quick-llama.cpp-server.git
cd quick-llama.cpp-server
git submodule update --init --recursive
```

### 3. Test Build Manually
```bash
# Make script executable
chmod +x scripts/ubuntu-auto-build.sh

# Run manual test
./scripts/ubuntu-auto-build.sh
```

### 4. Set Up Automation
```bash
# Install cron job (runs every other day at 2AM ET)
chmod +x scripts/setup-cron.sh
./scripts/setup-cron.sh
```

## Monitoring

### Check Build Logs
```bash
# View latest build log
ls -la /var/log/llamacpp-auto-build/
tail -f /var/log/llamacpp-auto-build/cron.log

# View detailed build logs
tail -f /var/log/llamacpp-auto-build/build-*.log
```

### Check Last Successful Build
```bash
cat /var/log/llamacpp-auto-build/last-successful-build.txt
```

### Manual Build Test
```bash
cd /home/du/quick-llama.cpp-server
./scripts/ubuntu-auto-build.sh
```

## Production Deployment

### Start Production Server
```bash
# Create models directory
mkdir -p models logs

# Start server with Docker Compose
docker-compose -f docker/docker-compose.ubuntu.yml up -d

# Check status
docker-compose -f docker/docker-compose.ubuntu.yml ps
```

### Download Models
```bash
# Use the downloader service
docker-compose -f docker/docker-compose.ubuntu.yml --profile tools run --rm model-downloader \
  --convert --hf-repo microsoft/Phi-3-mini-4k-instruct --outtype f16
```

## Troubleshooting

### Check Docker Hub Authentication
```bash
docker login
# Should show: Login Succeeded
```

### Test GPU Access
```bash
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu20.04 nvidia-smi
```

### Check Cron Job
```bash
crontab -l | grep llamacpp
```

### Remove Cron Job (if needed)
```bash
crontab -e
# Delete the llamacpp line and save
```