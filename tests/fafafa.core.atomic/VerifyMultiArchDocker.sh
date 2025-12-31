#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# You can override the list via env:
#   FAFAFA_ATOMIC_DOCKER_TARGETS="host i386 arm64 armv7"
# Extra (slow) targets are opt-in:
#   FAFAFA_ATOMIC_DOCKER_TARGETS="host i386 arm64 armv7 ppc64le s390x"
#
# Notes:
# - "host" runs the suite on the current machine (no Docker).
# - Docker image tags like debian:bookworm can be accidentally retagged to another arch if you previously ran
#   docker with --platform. This script prefers arch-specific images and a local i386 FPC image when available.
TARGETS_STRING="${FAFAFA_ATOMIC_DOCKER_TARGETS:-host i386 arm64 armv7}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker not found in PATH"
  exit 1
fi

# Ensure we don't accidentally write root-owned artifacts into the working tree.
# We mount the repo read-only and copy into /tmp inside the container.

run_one() {
  local target="$1"
  local image=""
  local platform=""

  case "$target" in
    host)
      echo "============================================================"
      echo "[TARGET] host"
      echo "[TEST] Running atomic suite on host..."
      "${SCRIPT_DIR}/BuildOrTest.sh" test
      echo "[OK] host"
      echo
      return 0
      ;;

    # i386 via QEMU (native 32-bit userland) for maximum fidelity.
    i386)
      platform="linux/386"
      image="i386/debian:bookworm"
      ;;

    arm64)
      platform="linux/arm64"
      image="arm64v8/debian:bookworm"
      ;;

    armv7)
      platform="linux/arm/v7"
      image="arm32v7/debian:bookworm"
      ;;

    ppc64le)
      platform="linux/ppc64le"
      image="ppc64le/debian:bookworm"
      ;;

    s390x)
      platform="linux/s390x"
      image="s390x/debian:bookworm"
      ;;

    # Fallback: allow running amd64 explicitly via Docker, but it may require pulling an amd64 base image.
    amd64)
      platform="linux/amd64"
      image="debian:bookworm"
      ;;

    *)
      echo "[ERROR] Unknown target: $target"
      exit 1
      ;;
  esac

  echo "============================================================"
  echo "[TARGET] $target ($platform)"
  echo "[IMAGE ] $image"

  docker run --rm \
    --platform "$platform" \
    -v "${ROOT_DIR}":/workspace:ro \
    -w /tmp/atomic-test \
    "$image" \
    bash -lc '
      set -euo pipefail

      echo "[INFO] OS:"
      cat /etc/os-release | head -n 6 || true

      echo "[INFO] Arch:"
      uname -m || true
      getconf LONG_BIT || true

      if command -v fpc >/dev/null 2>&1; then
        echo "[INFO] FPC already present in image."
      else
        if ! command -v apt-get >/dev/null 2>&1; then
          echo "[ERROR] fpc not found and apt-get not available in this image."
          exit 1
        fi

        # Some environments have flaky HTTP access. Prefer https + retries.
        if [ -f /etc/apt/sources.list ]; then
          sed -i "s|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g" /etc/apt/sources.list || true
        fi
        if [ -d /etc/apt/sources.list.d ]; then
          for f in /etc/apt/sources.list.d/*.list; do
            [ -f "$f" ] || continue
            sed -i "s|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g" "$f" || true
          done
        fi

        echo "[INFO] Installing FPC (apt)..."
        apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 update -qq
        DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 install -y -qq --no-install-recommends fpc >/dev/null
      fi

      echo "[INFO] FPC:"
      fpc -iV
      fpc -iTP
      fpc -iTO

      # If we are running on amd64 userland but targeting i386 (cross toolchain image),
      # we need 32-bit libc dev files to link (otherwise: cannot find -lc).
      if [ "$(uname -m || true)" = "x86_64" ] && [ "$(fpc -iTP || true)" = "i386" ]; then
        if command -v apt-get >/dev/null 2>&1; then
          echo "[INFO] Installing i386 libc dev files for linking (multiarch)..."
          dpkg --add-architecture i386 || true
          apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 update -qq
          DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 -o Acquire::http::Timeout=30 install -y -qq libc6-dev:i386 libgcc-s1:i386 gcc-multilib binutils-i686-linux-gnu >/dev/null
        else
          echo "[ERROR] Need i386 libc dev files to link, but apt-get is not available in this image."
          exit 1
        fi
      fi

      mkdir -p /tmp/atomic-test
      cp -a /workspace/. /tmp/atomic-test/

      cd /tmp/atomic-test/tests/fafafa.core.atomic
      chmod +x BuildOrTest.sh

      echo "[TEST] Running atomic suite..."
      ./BuildOrTest.sh test
    '

  echo "[OK] $target"
  echo
}

for t in ${TARGETS_STRING}; do
  run_one "$t"
done

echo "All requested targets completed successfully."