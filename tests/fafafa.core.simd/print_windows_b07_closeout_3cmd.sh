#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-SIMD-$(date '+%Y%m%d')-152}"

cat <<EOM
[CLOSEOUT] Windows 证据闭环入口（复制即跑）

0) 先做 GH 阻塞预检（Git Bash / WSL，推荐）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight

1) 主入口（Git Bash / WSL，自动 dispatch GH Windows runner -> 下载证据 -> 校验 -> finalize）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh ${LBatchId}

2) 若你走手工 Windows 实机路径：
   2.1 Windows PowerShell 采集+校验证据
       \$env:FAFAFA_BUILD_MODE = 'Release'
       tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify
   2.2 Git Bash / WSL 一键收口
       FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize ${LBatchId}

3) 最终确认冻结状态（Git Bash / WSL）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status

说明：
- `win-evidence-via-gh` 现在会把中间态快照落到 `tests/fafafa.core.simd/logs/windows-closeout/${LBatchId}/`，同时回写 canonical `logs/` 指针。
- `win-evidence-via-gh` 只会消费远端 ref；若本地还有未提交/未推送的 closeout 修复，它会直接拒绝 dispatch，避免跑一轮注定失败的 Windows runner。
- `win-closeout-finalize` 内部顺序：finalize -> freeze-status -> apply（freeze PASS 才会回填文档）。
- apply_windows_b07_closeout_updates.sh 默认强制读取 freeze_status.json，拒绝未冻结状态写文档。
- 若第 0 步返回 RECENT_BILLING_BLOCK，请先恢复 GitHub Billing/额度，再继续后续步骤。
- 若你只是在 Linux 预演，使用 win-closeout-dryrun 与 win-closeout-snippets，不要执行收口回填。
EOM
