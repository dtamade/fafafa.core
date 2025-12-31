# Use Ubuntu as base; arm64 uses apt packages, riscv64 downloads snapshot.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH

# For riscv64: freepascal.org can be slow (~6KB/s). Consider self-hosting the tarball.
ARG FPC_RISCV64_SNAPSHOT_URL="https://downloads.freepascal.org/fpc/snapshot/trunk/riscv64-linux/fpc-3.3.1.riscv64-linux.tar.gz"

RUN apt-get -o Acquire::Retries=5 -o Acquire::ForceIPv4=true update \
  && apt-get -o Acquire::Retries=5 -o Acquire::ForceIPv4=true install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    gzip \
  && if [ "${TARGETARCH}" = "riscv64" ]; then \
      apt-get -o Acquire::Retries=5 -o Acquire::ForceIPv4=true install -y --no-install-recommends \
        binutils \
        libc6-dev; \
      echo "[INFO] Installing FPC snapshot for ${TARGETARCH}: ${FPC_RISCV64_SNAPSHOT_URL}"; \
      mkdir -p /opt/fpc; \
      curl -L --retry 5 --retry-delay 2 --speed-limit 500 --speed-time 120 \
        -o /tmp/fpc.tar.gz "${FPC_RISCV64_SNAPSHOT_URL}"; \
      tar -xzf /tmp/fpc.tar.gz -C /opt/fpc; \
      ln -sf /opt/fpc/bin/fpc /usr/local/bin/fpc; \
      ln -sf /opt/fpc/lib/fpc/3.3.1/ppcrv64 /usr/local/bin/ppcrv64; \
      mkdir -p /etc; \
      echo '-Fu/opt/fpc/lib/fpc/3.3.1/units/riscv64-linux/*' > /etc/fpc.cfg; \
      echo '-Fl/opt/fpc/lib/fpc/3.3.1/units/riscv64-linux/rtl' >> /etc/fpc.cfg; \
      rm -rf /tmp/fpc.tar.gz; \
    else \
      echo "[INFO] Installing FPC from apt for ${TARGETARCH}"; \
      apt-get -o Acquire::Retries=5 -o Acquire::ForceIPv4=true install -y --no-install-recommends \
        fpc \
        fp-units-base \
        fp-units-fcl \
        fp-utils; \
    fi \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work
