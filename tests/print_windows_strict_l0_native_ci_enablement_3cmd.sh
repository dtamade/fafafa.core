#!/usr/bin/env bash
set -euo pipefail

LBatchId="${1:-L0-$(date '+%Y%m%d')-native}"

cat <<'EOM' | sed "s/__BATCH_ID__/${LBatchId}/g"
[CLOSEOUT] strict L0 Windows CI enablement（default-branch registration first）

0) 先把 Windows native evidence workflow 注册到 default branch `main`
   git fetch origin
   git switch -C l0-windows-ci-enablement origin/main
   git cherry-pick 5c2c6e40 f8e2a09b 743af329 2bdbd479 1c09a01a 57faf2ef c3e7011e 1ca0af89 c1b77313 dd9b7421 0c7dcc96 db4527cb

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
- 不要再把 `c1b77313^..db4527cb` 当成最小 CI registration slice；对 `origin/main` 来说，它缺少 lazbuild bootstrap、smoke preflight、batch runtime parity 和 native matrix closeout 依赖。
- 当前可运行的最小依赖链从 `5c2c6e40` 开始，到 `db4527cb` 收口；上面那条 `git cherry-pick` 命令已经按硬依赖顺序展开。
- `f8eb351c` 和 `08801ab1` 只属于 operator-facing closeout UX；它们不是 workflow 注册的硬依赖。
- Windows native parity 只有在 GH artifact 里出现 fresh PASS evidence 后才能记成完成；把 workflow 注册到 `main` 本身不等于证据闭环。
EOM
