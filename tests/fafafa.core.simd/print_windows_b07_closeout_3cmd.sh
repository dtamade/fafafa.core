#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-SIMD-$(date '+%Y%m%d')-152}"

cat <<'EOM' | sed "s/__BATCH_ID__/${LBatchId}/g"
[CLOSEOUT] Windows 证据闭环入口（复制即跑）

0) 先做 GH 阻塞预检（Git Bash / WSL，推荐）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight

1) 主入口（Git Bash / WSL，自动 dispatch GH Windows runner -> 下载证据 -> 校验 -> finalize）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh __BATCH_ID__

2) 若你走手工 Windows 实机路径：
   2.1 Windows PowerShell 采集+校验证据
       $env:FAFAFA_BUILD_MODE = 'Release'
       tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify
   2.2 Git Bash / WSL 回灌 cross gate（必需，native batch evidence 不会生成 fresh gate_summary）
       FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate
   2.3 Git Bash / WSL 一键收口
       FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize __BATCH_ID__

3) 最终确认冻结状态（Git Bash / WSL）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status

说明：
- `win-evidence-via-gh` 现在会把中间态快照落到 `tests/fafafa.core.simd/logs/windows-closeout/__BATCH_ID__/`，同时回写 canonical `logs/` 指针。
- 默认 `win-evidence-via-gh` 会消费远端 ref；若本地还有未提交/未推送的 closeout 修复，它会直接拒绝 dispatch，避免跑一轮注定失败的 Windows runner。
- 若你手里已有现成 GH Actions `run-id`，可直接执行 `... win-evidence-via-gh __BATCH_ID__ <run-id>` 复用旧 run；这条旁路不会因为本地 dirty worktree / remote ref mismatch 被拒绝。
- `win-evidence-via-gh` 在下载并校验证据后，会自动补一轮 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1` 的 Linux cross gate，再进入 closeout finalize。
- 手工 Windows 实机路径必须先显式补一轮 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1` 的 Linux cross gate；`win-closeout-finalize` 自己不会回灌 gate。
- `win-closeout-finalize` 内部顺序：finalize -> freeze-status -> apply（freeze PASS 才会回填文档）。
- apply_windows_b07_closeout_updates.sh 默认强制读取 freeze_status.json，拒绝未冻结状态写文档。
- 若第 0 步返回 RECENT_BILLING_BLOCK，请先恢复 GitHub Billing/额度，再继续后续步骤。
- 若你只是在 Linux 预演，使用 win-closeout-dryrun 与 win-closeout-snippets，不要执行收口回填。
EOM
