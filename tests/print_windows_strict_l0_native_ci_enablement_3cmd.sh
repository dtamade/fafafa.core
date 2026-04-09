#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-L0-$(date '+%Y%m%d')-native}"

cat <<'EOM' | sed "s/__BATCH_ID__/${LBatchId}/g"
[CLOSEOUT] strict L0 Windows CI enablement（default-branch registration first）

0) 先把 Windows native evidence workflow 注册到 default branch `main`
   git fetch origin
   git switch -C l0-windows-ci-enablement origin/main
   git cherry-pick c1b77313^..db4527cb

1) 如果你希望把 today operator helper 一并带到 `main`，再补这两个提交
   git cherry-pick f8eb351c 08801ab1

2) 推一个只做 CI enablement 的分支，然后合到 `main`
   git push origin HEAD:refs/heads/l0-windows-ci-enablement
   gh pr create --base main --head l0-windows-ci-enablement --title "ci(l0): register windows native evidence workflow"

3) 等 PR 合到 `main` 后，再从 Linux x64 执行 GH preflight + Windows evidence helper
   bash tests/preflight_windows_strict_l0_native_evidence_gh.sh
   bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh __BATCH_ID__

4) 下载 artifact 后，再回到当前 L0 worktree 做最终复核
   bash tests/test_windows_strict_l0_native_closeout_stack.sh

说明：
- 当前 default branch 是 `main`；在 workflow 注册到 `main` 之前，`preflight_windows_strict_l0_native_evidence_gh.sh` 预期会以 `code=22` fail-close。
- `c1b77313^..db4527cb` 是当前最小 CI registration slice：workflow、collector/verifier、GH preflight/helper、shell verifier 一起带走，依赖关系最完整。
- `f8eb351c` 和 `08801ab1` 只属于 operator-facing closeout UX；它们不是 workflow 注册的硬依赖。
- Windows native parity 只有在 GH artifact 里出现 fresh PASS evidence 后才能记成完成；把 workflow 注册到 `main` 本身不等于证据闭环。
EOM
