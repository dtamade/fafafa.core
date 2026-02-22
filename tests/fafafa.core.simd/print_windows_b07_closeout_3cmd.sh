#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-SIMD-$(date '+%Y%m%d')-152}"

cat <<EOM
[CLOSEOUT] Windows 实机闭环 3 命令（复制即跑）

1) 采集+校验证据（Windows PowerShell）
   tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify

2) 生成收口摘要（Git Bash / WSL）
   bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence

3) 自动回填文档（Git Bash / WSL）
   bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id ${LBatchId}

说明：
- 第 3 步默认拒绝 simulated summary，不会误关单。
- 若你只是在 Linux 预演，使用 win-closeout-dryrun 与 win-closeout-snippets，不要执行第 3 步 apply。
- 等价单命令（Windows 日志到位后）：
  bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize ${LBatchId}
EOM
