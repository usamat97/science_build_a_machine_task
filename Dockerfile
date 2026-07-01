FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    verilator \
    yosys \
    nextpnr-ecp5 \
    fpga-trellis \
    build-essential \
    python3 \
    zlib1g-dev \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain (candidate may use C, C++, Rust, or anything else).
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /workspace
