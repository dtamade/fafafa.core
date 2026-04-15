#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-L0-$(date '+%Y%m%d')-native}"

cat <<'EOM' | sed "s/__BATCH_ID__/${LBatchId}/g"
[CLOSEOUT] strict L0 Windows native evidence handoff（复制即跑）

0) 先做 GH 阻塞预检（Linux/macOS，推荐）
   bash tests/preflight_windows_strict_l0_native_evidence_gh.sh

1) 主入口（Linux/macOS，自动 dispatch/reuse GH Windows runner -> 下载 artifact -> shell 校验）
   bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh __BATCH_ID__

2) 若你走手工 Windows 实机路径：
   2.1 Windows CMD / PowerShell 固定批次号后采集 native evidence
       set L0_WINDOWS_EVIDENCE_BATCH_ID=__BATCH_ID__
       tests\collect_windows_strict_l0_native_evidence.bat
   2.2 Windows CMD / PowerShell 校验证据目录
       tests\verify_windows_strict_l0_native_evidence.bat tests\_windows_l0_native_evidence\__BATCH_ID__
   2.3 若你把 snapshot 复制回 Linux/macOS，再补一轮 shell verifier
       bash tests/verify_windows_strict_l0_native_evidence.sh <snapshot-root> [expected-commit] [expected-ref]

3) 一次性复核当前本地 closeout stack（Linux/macOS）
   bash tests/test_windows_strict_l0_native_closeout_stack.sh

说明：
- `run_windows_strict_l0_native_evidence_via_github_actions.sh` 默认会先做 GH preflight；如果 workflow 还没有注册到 default branch，当前预期 fail-close 为 `code=22`。
- 若你手里已有现成 GH Actions `run-id`，可直接执行 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh __BATCH_ID__ <run-id>` 复用旧 run。
- `verify_windows_strict_l0_native_evidence.sh` 只负责 Linux/macOS 侧 artifact 结构校验；native parity 是否完成，仍以 Windows-host `collect + verify` 的 fresh PASS 为准。
- `test_windows_strict_l0_native_closeout_stack.sh` 会串起当前本地所有 native evidence contract，并打印当前 GH preflight 状态；它不会伪造真实 Windows pass evidence。
EOM
