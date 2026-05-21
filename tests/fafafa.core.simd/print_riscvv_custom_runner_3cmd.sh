#!/usr/bin/env bash
set -euo pipefail

cat <<'EOM'
[CLOSEOUT] RISCVV native-evidence bootstrap flow

1) Repo-side: prepare a registration token outside the repo worktree
   SIMD_RISCVV_RUNNER_TOKEN_FILE=/tmp/fafafa-simd-riscvv-runner.token FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-runner-registration

2) Real riscv64 host: fail-close preflight before repo-ops registers the runner
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-runner-host-preflight

3) After the repo-visible self-hosted,Linux,riscv64 runner is online, collect fresh evidence and refresh the bundle
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh-clean riscvv
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh release-evidence

Notes:
- The repo only provides token prep, host preflight, and closeout guidance. It does not ship a riscv64 runner binary/service.
- Keep the registration token outside repo-tracked files.
- The host preflight rejects mislabeled x86_64/arm64 hosts. RISCVV native evidence must come from uname -m=riscv64.
- native-evidence-via-gh-clean is the preferred operator entry when the current worktree still carries local planning/state files.
- For a fuller operator runbook, use: tests/fafafa.core.simd/docs/riscvv_native_closeout_runbook.md
EOM
