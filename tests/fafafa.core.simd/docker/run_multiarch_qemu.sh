#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
DOCKER_DIR="${ROOT_DIR}/tests/fafafa.core.simd/docker"

IMAGE_BASE="fafafa-core-simd-test"

PLATFORMS=(
  "linux/386"
  "linux/arm64"
  "linux/riscv64"
)

echo "[INFO] Repo: ${ROOT_DIR}"

for platform in "${PLATFORMS[@]}"; do
  arch="${platform#linux/}"
  tag="${IMAGE_BASE}:${arch}"

  echo "[BUILD] ${tag} (${platform})"
  docker buildx build \
    --platform "${platform}" \
    --network "${DOCKER_BUILD_NETWORK:-default}" \
    --tag "${tag}" \
    --file "${DOCKER_DIR}/Dockerfile" \
    --load \
    "${DOCKER_DIR}"

  echo "[RUN] ${tag} (${platform})"
  docker run --rm \
    --platform "${platform}" \
    --user "$(id -u):$(id -g)" \
    --volume "${ROOT_DIR}:/work" \
    --workdir "/work" \
    "${tag}" \
    bash tests/fafafa.core.simd/docker/run_fpc_tests.sh

done

echo "[DONE] All platforms passed"
