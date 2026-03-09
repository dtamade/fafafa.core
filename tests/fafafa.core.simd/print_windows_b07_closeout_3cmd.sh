#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-SIMD-$(date '+%Y%m%d')-152}"

cat <<EOM
[CLOSEOUT] Windows 实机闭环 3 命令（复制即跑）

0) 先做 GH 阻塞预检（Git Bash / WSL，推荐）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight

1) 采集+校验证据（Windows PowerShell）
   \$env:FAFAFA_BUILD_MODE = 'Release'
   tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify

2) 回灌 cross gate（Git Bash / WSL）
   FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate

3) 一键收口（Git Bash / WSL）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize ${LBatchId}

4) 最终确认冻结状态（Git Bash / WSL）
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status

说明：
- 第 3 步内部顺序：finalize -> freeze-status -> apply（freeze PASS 才会回填文档）。
- apply_windows_b07_closeout_updates.sh 默认强制读取 freeze_status.json，拒绝未冻结状态写文档。
- 若第 0 步返回 RECENT_BILLING_BLOCK，请先恢复 GitHub Billing/额度，再继续后续步骤。
- 若当前无 Windows 实机，可改用 GH 路径：
  FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh ${LBatchId}
- 若你只是在 Linux 预演，使用 win-closeout-dryrun 与 win-closeout-snippets，不要执行收口回填。
EOM
