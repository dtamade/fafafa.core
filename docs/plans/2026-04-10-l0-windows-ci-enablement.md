# 2026-04-10 L0 Windows CI Enablement Checklist

> 这份清单只回答一件事：在当前只有 Linux x64 执行面的前提下，怎样把 strict L0 的 Windows native evidence lane 通过 GitHub Actions 真正打通。
> 它不是新的长期路线图；L0 的长期边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准。

## Goal

- 先把 `.github/workflows/l0-windows-native-evidence.yml` 注册到 default branch `main`
- 再从 Linux x64 触发 Windows CI 收集 strict L0 native evidence
- 最后把下载回来的 artifact 回填到当前 L0 closeout 面

## Why this is the current blocker

当前仓库内的本地 closeout stack 已经具备：

- Windows native matrix driver contract
- native evidence collector / verifier contract
- GH preflight / dispatch-download helper contract
- shell verifier contract

但当前 preflight 仍然可能返回：

- `WORKFLOW_NOT_FOUND`
- `code=22`

这说明：

- L0 本地脚本已经够了
- 真正缺的不是代码逻辑，而是 workflow 还没有在 default branch 注册

## Required slice

推荐先只把最小 CI registration slice 带到 `main`：

- `c1b77313` `ci(l0): add windows native evidence collector`
- `dd9b7421` `ci(l0): add github actions native evidence helper`
- `0c7dcc96` `test(l0): avoid exec-bit dependency in gh helper`
- `db4527cb` `test(l0): extract shell verifier for native evidence`

为什么是这四个：

- `c1b77313`：引入 workflow、Windows collector、Windows verifier、基础文档
- `dd9b7421`：引入 Linux x64 的 GH preflight / dispatch-download helper
- `0c7dcc96`：修正 helper 对 exec-bit 的隐式依赖
- `db4527cb`：把 shell-side artifact verifier 抽出来，形成完整的 Linux x64 复核链

下面两条是可选的 operator UX slice，不是 workflow 注册硬依赖：

- `f8eb351c` `test(l0): add native closeout stack runner`
- `08801ab1` `docs(l0): add native evidence handoff helper`

## Command checklist

### 1. 从 `origin/main` 切出一个 CI-only enablement 分支

Run:

```bash
git fetch origin
git switch -C l0-windows-ci-enablement origin/main
git cherry-pick c1b77313^..db4527cb
```

### 2. 如果你希望把 today helper 一并带到 `main`

Run:

```bash
git cherry-pick f8eb351c 08801ab1
```

### 3. 推分支并发一个只做 workflow registration 的 PR

Run:

```bash
git push origin HEAD:refs/heads/l0-windows-ci-enablement
gh pr create --base main --head l0-windows-ci-enablement --title "ci(l0): register windows native evidence workflow"
```

建议 PR 描述至少写清楚：

- 这次 PR 的目标只是让 `l0-windows-native-evidence.yml` 在 `main` 上可见
- Windows evidence 本身仍要在 PR 合并后，从 Linux x64 侧触发 CI 再采
- 这次 PR 不代表 native parity 已闭环

### 4. PR 合到 `main` 后，从 Linux x64 重新跑 preflight

Run:

```bash
bash tests/preflight_windows_strict_l0_native_evidence_gh.sh
```

通过标准：

- 返回 `rc=0`
- 不再是 `WORKFLOW_NOT_FOUND`

### 5. 从 Linux x64 触发 Windows evidence workflow

Run:

```bash
bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh L0-YYYYMMDD-native
```

如果只想先拿 today source-of-truth 命令，再跑：

```bash
bash tests/print_windows_strict_l0_native_closeout_3cmd.sh L0-YYYYMMDD-native
```

### 6. 下载 artifact 后做 closeout 复核

Run:

```bash
bash tests/test_windows_strict_l0_native_closeout_stack.sh
git diff --check
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
```

## Evidence acceptance

只有同时满足下面几条，Windows native parity 才能记成完成：

- artifact 的 `summary.md` 明确写出 `- Result: PASS`
- `environment.txt` 明确写出 `host_os=Windows_NT`
- `source_revision.txt` 明确写出 `git_commit=` 和 `git_ref_hint=`
- `native_matrix.log` / `evidence.log` 体现 12 个 strict L0 `.bat` 入口的 fresh PASS
- 模块日志没有 `[BUILD] SKIPPED`、`lazbuild not found`、`Test executable not found`

## What not to do

- 不要把 workflow 注册 PR 和 strict L0 主线 merge 混成同一件事
- 不要把 SIMD worktree 的工作混入这条 enablement 线
- 不要在 `code=22` 还没消失时假装 GH helper 已经可用
- 不要把“workflow 在 `main` 上可见”误写成“Windows native parity 已完成”

## Fast handoff

如果你只是要把这件事转给下一个同学，直接让他先跑：

```bash
bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh
```
