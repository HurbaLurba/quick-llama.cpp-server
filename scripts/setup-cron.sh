#!/bin/bash

# Cron Job Setup Script for LLaMA.cpp Auto-Build
# Sets up automated building every other day at 2AM ET

set -e

REPO_DIR="/home/du/quick-llama.cpp-server"
BUILD_SCRIPT="$REPO_DIR/scripts/ubuntu-auto-build.sh"
CRON_USER="du"

echo "Setting up automated LLaMA.cpp build cron job..."

# Verify build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "ERROR: Build script not found at $BUILD_SCRIPT"
    exit 1
fi

# Make build script executable
chmod +x "$BUILD_SCRIPT"
echo "Made build script executable"

# Create log directory
sudo mkdir -p /var/log/llamacpp-auto-build
sudo chown $CRON_USER:$CRON_USER /var/log/llamacpp-auto-build
echo "Created log directory"

# Backup existing crontab
crontab -l > /tmp/crontab-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || echo "No existing crontab to backup"

# Create new cron entry (every other day at 2AM ET)
# 0 2 */2 * * means: minute 0, hour 2, every 2nd day, any month, any day of week
CRON_ENTRY="0 2 */2 * * cd $REPO_DIR && $BUILD_SCRIPT >> /var/log/llamacpp-auto-build/cron.log 2>&1"

# Add cron job
(crontab -l 2>/dev/null | grep -v "$BUILD_SCRIPT"; echo "$CRON_ENTRY") | crontab -

echo "Cron job installed successfully!"
echo "Schedule: Every other day at 2:00 AM ET"
echo "Command: $CRON_ENTRY"
echo ""
echo "Current crontab:"
crontab -l | grep -E "(llamacpp|ubuntu-auto-build)" || echo "No LLaMA.cpp cron jobs found"

echo ""
echo "Log files will be written to:"
echo "  - /var/log/llamacpp-auto-build/cron.log (cron output)"
echo "  - /var/log/llamacpp-auto-build/build-YYYYMMDD-HHMMSS.log (detailed build logs)"

echo ""
echo "To manually test the build script:"
echo "  cd $REPO_DIR && $BUILD_SCRIPT"

echo ""
echo "To view recent logs:"
echo "  tail -f /var/log/llamacpp-auto-build/cron.log"

echo ""
echo "Setup complete!"