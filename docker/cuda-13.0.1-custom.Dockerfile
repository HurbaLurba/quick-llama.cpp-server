ARG UBUNTU_VERSION=24.04
# Using CUDA 13.0.1 instead of default 12.4.0
ARG CUDA_VERSION=13.0.1
# Target the CUDA build image  
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} AS build

# Custom CUDA architecture targeting RTX 5090 and similar (86;89;90)
ARG CUDA_DOCKER_ARCH=86;89;90

RUN apt-get update && \
    apt-get install -y build-essential cmake python3 python3-pip git libcurl4-openssl-dev libgomp1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY llama.cpp/ .

# Build with your specific cmake configuration
RUN cmake -B build \
    -DGGML_CUDA=ON \
    -DGGML_CUBLAS=ON \
    -DGGML_FORCE_CUBLAS=ON \
    -DGGML_RPC=ON \
    -DGGML_NATIVE=OFF \
    -DGGML_BACKEND_DL=ON \
    -DGGML_CPU_ALL_VARIANTS=ON \
    -DGGML_CCACHE=OFF \
    -DCMAKE_CUDA_ARCHITECTURES="${CUDA_DOCKER_ARCH}" \
    -DLLAMA_CURL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_TESTS=OFF \
    -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
    . && \
    cmake --build build --config Release -j$(nproc)

RUN mkdir -p /app/lib && \
    find build -name "*.so" -exec cp {} /app/lib \;

RUN mkdir -p /app/full \
    && cp build/bin/* /app/full \
    && cp *.py /app/full 2>/dev/null || true \
    && cp -r gguf-py /app/full 2>/dev/null || true \
    && cp -r requirements /app/full 2>/dev/null || true \
    && cp requirements.txt /app/full 2>/dev/null || true \
    && cp .devops/tools.sh /app/full/tools.sh 2>/dev/null || true

## Base image  
FROM ${BASE_CUDA_RUN_CONTAINER} AS base

RUN apt-get update \
    && apt-get install -y libgomp1 curl \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete

COPY --from=build /app/lib/ /app

### Full
FROM base AS full

COPY --from=build /app/full /app

WORKDIR /app

RUN apt-get update \
    && apt-get install -y \
    git \
    python3 \
    python3-pip \
    dos2unix \
    && pip install --break-system-packages -r requirements.txt \
    && dos2unix /app/tools.sh \
    && chmod +x /app/tools.sh \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /tmp/* /var/tmp/* \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete \
    && find /var/cache -type f -delete

ENV LC_ALL=C.utf8

ENTRYPOINT ["/app/tools.sh"]

### Light, CLI only  
FROM base AS light

COPY --from=build /app/full/llama-cli /app

WORKDIR /app

ENTRYPOINT [ "/app/llama-cli" ]

### Server, Server only
FROM base AS server

ENV LLAMA_ARG_HOST=0.0.0.0

COPY --from=build /app/full/llama-server /app

WORKDIR /app  

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

ENTRYPOINT [ "/app/llama-server" ]