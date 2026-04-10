# 2026-04-09 L0 Native Windows Matrix Runbook

## Goal

- 补齐 strict non-SIMD L0 最后一块缺失的 Windows 证据：真实 Windows `.bat` build-path parity。
- 明确区分：
  - Linux/macOS + `wine` 路径只能验证 runtime smoke / runtime-only parity。
  - 真实 Windows 主机才负责验证 native `.bat` build-path parity。

## Host Requirements

- 执行面：当前唯一 L0 worktree
  - `/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 分支：`l0-mainline-integration-20260409`
- 主机：专用 Windows CMD / PowerShell
- 工具链：
  - `lazbuild.exe` 在 PATH 上，或显式设置 `LAZBUILD_EXE`
  - 不要把 `LAZBUILD_EXE` 指到 Unix 路径或 `wine` 下的 wrapper
- 环境约束：
  - `FAFAFA_SKIP_BUILD` 必须保持未设置
  - 不要在 SIMD worktree 或根 `main` 脏工作树上收集这条证据

## Command

- CMD：
  - `tests\test_windows_strict_l0_batch_native_matrix.bat`
- 推荐的 evidence collector：
  - `tests\collect_windows_strict_l0_native_evidence.bat`
- collector 产物校验：
  - `tests\verify_windows_strict_l0_native_evidence.bat tests\_windows_l0_native_evidence\<batch-id>`
- Linux/macOS artifact verifier：
  - `bash tests/verify_windows_strict_l0_native_evidence.sh [snapshot-root] [expected-commit] [expected-ref]`
- Linux/macOS GH preflight：
  - `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh`
- Linux/macOS CI enablement helper：
  - `bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh [batch-id]`
- Linux/macOS GH helper：
  - `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh [batch-id] [run-id]`
- Linux/macOS 复制即跑 helper：
  - `bash tests/print_windows_strict_l0_native_closeout_3cmd.sh [batch-id]`
- Linux/macOS aggregate closeout stack：
  - `bash tests/test_windows_strict_l0_native_closeout_stack.sh`
- PowerShell：
  - `cmd /c tests\test_windows_strict_l0_batch_native_matrix.bat`
  - `cmd /c tests\collect_windows_strict_l0_native_evidence.bat`

如果本机没有把 Lazarus 加进 PATH，可先显式设置：

```bat
set LAZBUILD_EXE=C:\Lazarus\lazbuild.exe
tests\collect_windows_strict_l0_native_evidence.bat
```

via-GitHub-Actions helper 约束：

- 默认模式会先执行 `preflight_windows_strict_l0_native_evidence_gh.sh`
- 如果 workflow 没有出现在仓库 default branch，预期由 preflight 以 `code=22` fail-close
- 当前仓库 today 状态已经不是这样；default branch workflow 已注册，且 GitHub Actions run `24224880061` 已 fresh 通过
- 如果你当前只有 Linux x64，且 preflight 重新退回 `code=22`，再去执行 `docs/plans/2026-04-10-l0-windows-ci-enablement.md` 里的 registration checklist，把它当成 registration drift 排障而不是 current baseline
- 默认 dispatch 模式会拒绝当前 worktree dirty 或 remote ref 与 local HEAD 不一致的场景
- 若已经有可复用的 `run-id`，可传第二个参数旁路 dispatch；这时只会做 wait/download/Linux-side artifact 校验
- Linux-side 校验只负责核对 artifact 结构和关键字段；默认由 `verify_windows_strict_l0_native_evidence.sh` 执行；native parity 是否完成，仍以 workflow 内 Windows `collect + verify` 的 fresh PASS 为准
- `print_windows_strict_l0_native_closeout_3cmd.sh` 只负责输出今天这条 lane 的复制即跑命令；它不会替代真实 Windows evidence
- `test_windows_strict_l0_native_closeout_stack.sh` 会把 bootstrap、preflight contract、native matrix contract、collector/verifier contract、GH helper contract、shell verifier contract 以及当前 GH preflight 状态串成单入口

## Quick Start

如果你只想先拿最短可执行入口，不想手工从 runbook 摘命令，先跑：

```bash
bash tests/print_windows_strict_l0_native_closeout_3cmd.sh
```

如果未来某次排障里真正卡住的是 workflow registration 漂移，先跑：

```bash
bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh
```

如果你手里已经有目标批次号，再显式传进去：

```bash
bash tests/print_windows_strict_l0_native_closeout_3cmd.sh L0-YYYYMMDD-native
```

这条 helper 会同时打印：

- GH preflight
- Linux/macOS GH helper 主路径
- 手工 Windows collector / verifier 路径
- Linux/macOS shell verifier 路径
- 当前本地 aggregate closeout stack 路径

## Coverage

native matrix 当前固定覆盖 12 个 strict L0 batch 入口：

- `base`
- `contracts`
- `bits`
- `layout`
- `endian`
- `span`
- `option`
- `result`
- `platform`
- `atomic`
- `mem.allocator.foundation`
- `mem allocator-only`

## Logs And Pass Criteria

日志目录：

- `tests\_windows_batch_native_matrix\bootstrap.log`
- `tests\_windows_batch_native_matrix\base.log`
- `tests\_windows_batch_native_matrix\contracts.log`
- `tests\_windows_batch_native_matrix\bits.log`
- `tests\_windows_batch_native_matrix\layout.log`
- `tests\_windows_batch_native_matrix\endian.log`
- `tests\_windows_batch_native_matrix\span.log`
- `tests\_windows_batch_native_matrix\option.log`
- `tests\_windows_batch_native_matrix\result.log`
- `tests\_windows_batch_native_matrix\platform.log`
- `tests\_windows_batch_native_matrix\atomic.log`
- `tests\_windows_batch_native_matrix\mem_allocator_foundation.log`
- `tests\_windows_batch_native_matrix\mem_allocator_only.log`

标准 evidence 包目录：

- `tests\_windows_l0_native_evidence\<batch-id>\evidence.log`
- `tests\_windows_l0_native_evidence\<batch-id>\native_matrix.log`
- `tests\_windows_l0_native_evidence\<batch-id>\summary.md`
- `tests\_windows_l0_native_evidence\<batch-id>\environment.txt`
- `tests\_windows_l0_native_evidence\<batch-id>\source_revision.txt`
- `tests\_windows_l0_native_evidence\<batch-id>\module-logs\*.log`

通过标准：

- `bootstrap.log` 能证明 `tools\lazbuild.bat` 找到并调用了真实 Windows `lazbuild.exe`
- 每个模块日志都包含：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- `summary.md` 显式写出 `- Result: PASS`
- `source_revision.txt` 至少包含：
  - `git_commit=...`
  - `git_ref_hint=...`
- `environment.txt` 至少包含：
  - `host_os=Windows_NT`
  - `tool_lazbuild_wrapper=...`
  - `where_lazbuild_exe=...`
- 所有模块日志都不允许出现：
  - `[BUILD] SKIPPED`
  - `lazbuild not found`
  - `non-Windows executable`
  - `Test executable not found`
  - `heaptrc reports unfreed blocks`
- 终端最终输出：
  - `[PASS] strict L0 Windows native batch matrix verified`

## Failure Semantics

- `31`
  - 没有可用的真实 Windows `lazbuild.exe`
- `32`
  - `LAZBUILD_EXE` 指到了 non-Windows executable
- `33`
  - `tools\lazbuild.bat` 在当前 `cmd` 路径下不可调用
- `34` / `35` / `36`
  - 模块日志缺少 `[BUILD] OK` / `[TEST] OK` / `[LEAK] OK`
- `37`
  - 模块日志里出现 build/runtime failure markers
- `41`
  - 误设置了 `FAFAFA_SKIP_BUILD=1`

## Current Status

- 仓库内现在已经具备 native lane 驱动：
  - `tests\test_windows_strict_l0_batch_native_matrix.bat`
- 也已经具备 dedicated-host evidence helper：
  - `tests\collect_windows_strict_l0_native_evidence.bat`
  - `tests\verify_windows_strict_l0_native_evidence.bat`
- GitHub Actions 手工入口也已经接好：
  - `.github/workflows/l0-windows-native-evidence.yml`
- Linux/macOS 上也已经具备 hosted/manual workflow helper：
  - `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh`
  - `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
- Linux/macOS 当前能 fresh 复核的是：
  - `bash tests/test_windows_strict_l0_batch_native_matrix_contract.sh`
  - `bash tests/test_windows_strict_l0_native_evidence_contract.sh`
  - `bash tests/test_windows_strict_l0_native_evidence_gh_contract.sh`
  - `bash tests/test_windows_strict_l0_native_evidence_shell_verifier_contract.sh`
  - 它只证明脚本 contract 和 fail-close 语义已锁定，不等于 native parity 已完成
- 截至 `2026-04-10`，GitHub Actions run `24224880061` 已通过 Windows-host `collect + verify`，artifact summary 记录 strict L0 native evidence `12/12` PASS
- 当前若再出现 `code=22`，应把它视作 registration drift / GH 可见性异常，而不是 current baseline
- 当前 strict L0 的 Windows native evidence 已闭环；这份 runbook 主要保留 dedicated Windows host / artifact verifier / GH helper 的操作与失败语义
