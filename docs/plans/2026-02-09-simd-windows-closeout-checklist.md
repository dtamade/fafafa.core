# SIMD Windows 收口执行清单（待实机）

> Status: historical baseline.
>
> This document is kept for drift comparison, template reuse, or local design history.
> It is not part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.
>
> Current HEAD note (2026-05-17):
> Treat this page as a historical checklist template, not as proof that the
> current repository is Windows-closeout-ready. Latest `freeze-status` is still
> `ready=False / mainline-ready=True / cross-ready=False`. If
> `win-evidence-preflight` reports `RECENT_BILLING_BLOCK`, stop there and
> recover GitHub Billing/runner capacity first. If you take the manual Windows
> path, use a real Windows host and make sure `LAZBUILD` resolves to a native
> Windows `.exe/.bat/.cmd`, not a Wine-visible Linux ELF.

更新时间：2026-03-20

## 目标

- 在 Windows 实机补齐 SIMD 发布证据链的最后一环。
- 不改变当前 Linux 已冻结结论，只做证据补全。

## 前置条件

- 进入仓库根目录（PowerShell）：
  - `D:\projects\Pascal\lazarus\My\libs\fafafa.core`
- 保证 Lazarus/FPC 可用，且命令行可调用。
- 如果走手工 Windows 实机路径：
  - 只在真实 Windows runner / Windows 实机执行 `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
  - `LAZBUILD` 必须解析到 native Windows `.exe/.bat/.cmd`
  - 不要把 `LAZBUILD` 指到 `Z:\opt\...` 这类 Wine 可见但 `cmd.exe` 不能执行的 Linux ELF

## GH 自动收口前置检查（无 Windows 主机时推荐）

- 在 dispatch 之前先跑：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
- 期望输出：
  - `STATUS=PASS CODE=OK`
- 若输出：
  - `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
  - 说明当前账户计费/额度仍阻塞 Windows runner，应先恢复 Billing 再继续。
- 每次执行会落盘最新状态：
  - `tests/fafafa.core.simd/logs/win_preflight_latest.json`
  - `tests/fafafa.core.simd/logs/win_preflight_latest.md`

## 执行步骤（按顺序）

0. 先输出“复制即跑”三命令（推荐）

- `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260210-150`

`closeout-release` 是当前推荐的单一 release 收口入口。

0.1) 或直接使用 GH 单命令闭环（推荐）

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-20260320-152`
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260320-152`
- 若第 0 步预检返回 `RECENT_BILLING_BLOCK`，不要继续执行这两条；当前批次应记为 `code-green / release-evidence-blocked`。

1. 一键生成并校验证据包（推荐）

- `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
- 前提：本机必须能直接执行 native Windows `lazbuild.exe`（或 `.bat/.cmd` wrapper），不要拿 Wine/cmd 冒充实机。
- 若显式试 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`，也只限 `cmd.exe` 真能解析 `bash` 的环境；当前本机 Wine 不属于这种环境，不要把它当成 host-side Unix bridge 逃生口。

2) Git Bash / WSL 回灌 fail-close cross gate（必需）

- `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`

3. 一键收口（必须在 cross gate PASS 后执行）

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-20260320-152`

4. 等价的分步执行（用于排障）

- `tests\fafafa.core.simd\buildOrTest.bat evidence-win`
- `tests\fafafa.core.simd\buildOrTest.bat verify-win-evidence`

5. 如需单独复跑 native batch gate（诊断用，可选）

- `tests\fafafa.core.simd\buildOrTest.bat gate`

6. 确认关键日志存在

- `tests\fafafa.core.simd\logs\windows_b07_gate.log`

7. 可选：再跑一次 strict coverage（留痕）

- `set SIMD_COVERAGE_STRICT_EXTRA=1 && tests\fafafa.core.simd\buildOrTest.bat coverage`

8. 回到 Linux/WSL 运行冻结判定（推荐）

- `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- 期望：`ready=True`

说明：

- native batch evidence 不会生成 fresh `gate_summary.md/json`，所以不能从 `evidence-win-verify` 直接跳到 `win-closeout-finalize`。
- 真正决定 `cross-ready=True` 的是 Linux/WSL 侧这条 fail-close cross gate，而不是 Windows batch `gate` 自身。
- 如果当前最新失败边界仍是 `cmd.exe cannot resolve LAZBUILD command "lazbuild"`，优先处理 real Windows runner / native `LAZBUILD`，而不是继续重试 Wine。

## 通过判据

- `buildOrTest.bat evidence-win-verify` 或 `verify-win-evidence` 返回码为 0。
- `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 返回码为 0。
- `windows_b07_gate.log` 存在且包含 `GATE OK`。
- （可选）coverage 输出：
  - `sse declared=79 tested=79 missing=0 extra=0`
  - `mmx declared=75 tested=75 missing=0 extra=0`

## 回填位置

- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
  - 将 P0 的“Windows 实机证据未归档”更新为完成。
- `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
  - 将 Windows 证据状态由待补改为已完成。
- `plans/scratch/2026-04-08-simd-review/progress.md`
  - 追加 Windows 收口执行记录与日志路径。

## 收口摘要（推荐追加）

在证据日志生成后，可一键产出 Markdown 摘要，便于直接粘贴到变更记录：

- Linux/macOS:
  - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
- Windows（Git Bash/WSL 可用时）:
  - `bash tests/fafafa.core.simd/finalize_windows_b07_closeout.sh`

默认输出：

- `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

## 回填模板

- 已提供可直接复制的回填模板：
  - `docs/plans/2026-02-09-simd-windows-postrun-fill-template.md`

## 无 Windows 环境预演（dry-run）

在 Linux/macOS 可先预演完整收口链路，提前发现脚本问题：

- `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`

产物：

- 模拟日志：`tests/fafafa.core.simd/logs/windows_b07_gate.simulated.log`
- 模拟摘要：`tests/fafafa.core.simd/logs/windows_b07_closeout_summary.simulated.md`

## 自动回填片段（无侵入）

可从收口摘要自动生成三段可粘贴片段（roadmap/matrix/scratch progress）：

- `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-snippets`

若要直接自动追加到目标文档（幂等、带 marker，且仅在 `freeze-status` 为 `ready=True` 时允许）：

- `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply`
- 或在 cross gate PASS 后执行一键收口：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize <BATCH_ID>`

自动 apply 还会同步结构化更新：

- `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

可选参数：

- `--batch-id <id>`：指定 scratch progress 回填批次标识（例如 `SIMD-20260210-149`）
- `--allow-simulated`：仅用于 dry-run 测试；即使允许 simulated apply，也会跳过结构化状态置 `[x]`，防止误关单
