#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

find_lazbuild() {
  local LCandidate

  if [[ -n "${LAZBUILD_EXE:-}" ]]; then
    echo "${LAZBUILD_EXE}"
    return 0
  fi

  if LCandidate="$(command -v lazbuild 2>/dev/null || true)"; then
    if [[ -n "${LCandidate}" ]]; then
      LCandidate="$(readlink -f "${LCandidate}" 2>/dev/null || echo "${LCandidate}")"
      if [[ "${LCandidate}" != "${SCRIPT_PATH}" ]]; then
        echo "${LCandidate}"
        return 0
      fi
    fi
  fi

  for LCandidate in \
    "/opt/fpcupdeluxe/lazarus/lazbuild" \
    "/usr/bin/lazbuild" \
    "/usr/local/bin/lazbuild"
  do
    if [[ -x "${LCandidate}" ]]; then
      echo "${LCandidate}"
      return 0
    fi
  done

  return 1
}

detect_lazarusdir() {
  local LLazbuildPath
  local LMaybeRoot
  local LCandidate

  if [[ -n "${FAFAFA_LAZARUSDIR:-}" && -d "${FAFAFA_LAZARUSDIR}/lcl" ]]; then
    echo "${FAFAFA_LAZARUSDIR}"
    return 0
  fi

  if [[ -n "${LAZARUSDIR:-}" && -d "${LAZARUSDIR}/lcl" ]]; then
    echo "${LAZARUSDIR}"
    return 0
  fi

  if [[ -d "/opt/fpcupdeluxe/lazarus/lcl" ]]; then
    echo "/opt/fpcupdeluxe/lazarus"
    return 0
  fi

  if LLazbuildPath="$(find_lazbuild 2>/dev/null || true)"; then
    if [[ -n "${LLazbuildPath}" ]]; then
      LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
      if [[ -d "${LMaybeRoot}/lcl" ]]; then
        echo "${LMaybeRoot}"
        return 0
      fi
    fi
  fi

  for LCandidate in /usr/lib/lazarus/* /usr/local/lib/lazarus/*; do
    if [[ -d "${LCandidate}/lcl" ]]; then
      echo "${LCandidate}"
      return 0
    fi
  done

  return 1
}

main() {
  local LLazbuild
  local LLazarusDir=""
  local -a LArgs
  local LArg
  local LHasLazarusDir=0

  if ! LLazbuild="$(find_lazbuild)"; then
    echo "[ERROR] lazbuild not found. Set LAZBUILD_EXE or install Lazarus." >&2
    exit 127
  fi

  for LArg in "$@"; do
    if [[ "${LArg}" == --lazarusdir=* || "${LArg}" == "--lazarusdir" ]]; then
      LHasLazarusDir=1
      break
    fi
  done

  LArgs=()
  if [[ "${LHasLazarusDir}" -eq 0 ]]; then
    LLazarusDir="$(detect_lazarusdir || true)"
    if [[ -n "${LLazarusDir}" ]]; then
      LArgs+=("--lazarusdir=${LLazarusDir}")
    fi
  fi

  exec "${LLazbuild}" "${LArgs[@]}" "$@"
}

main "$@"
