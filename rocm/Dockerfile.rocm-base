# Use 22.04 for now, as 24.04 never got post missing und unmet dependencies
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Add missing dependencies to install AMD key
RUN apt update && apt install -y wget gpg

# Download the key, convert the signing-key to a full
# keyring required by apt and store in the keyring directory
RUN wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null

# Add the ROCm APT-Repository
# IMPORTANT: The version (here 6.4.1) is part of the URL
# Ubuntu 22.04 has the Codename "jammy".
ENV ROCM_VERSION=6.4.1
# Register ROCm packages
RUN echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/${ROCM_VERSION} jammy main" \
    | tee --append /etc/apt/sources.list.d/rocm.list
COPY rocm-pin.pref /etc/apt/preferences.d/rocm-pin-600

# Update and install ROCm, 
# AFTER clearing the cache to avoid any pre-pin resolutions
RUN rm -rf /var/lib/apt/lists/* \
    && apt clean \
    && apt update \
    && apt install -y \
    rocm \
    clinfo \
    && rm -rf /var/lib/apt/lists/*

# Configure the environment variable for the 780M (gfx1103 architecture)
# This is the crucial workaround for ROCm to recognize the 780M.
# The exact version (e.g., 11.0.0, 11.0.2) may vary depending on the ROCm version and firmware.
# Start with 11.0.2, as this often works for gfx1103.
ENV HSA_OVERRIDE_GFX_VERSION=11.0.2


WORKDIR /app

# Optional: Copy application using ROCm into the app dir
# Example: COPY . /app

# Replace with launching your app
CMD ["bash"]
