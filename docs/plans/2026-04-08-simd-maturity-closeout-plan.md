# SIMD Maturity Closeout Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.

> Current HEAD note (2026-05-17):
> This plan is historical closeout guidance, not proof that the current
> repository is release-ready. Latest
> `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
> remains `ready=False / mainline-ready=True / cross-ready=False`, with
> `win-evidence-preflight=RECENT_BILLING_BLOCK` and
> `windows_evidence_verify` failing at
> `cmd.exe cannot resolve LAZBUILD command "lazbuild"`. For current operator
> truth, use `docs/fafafa.core.simd.closeout.md` and
> `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`.

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不扩大 SIMD 稳定面风险的前提下，把 `fafafa.core.simd` 从“代码门禁通过但 freeze 未就绪”推进到可重复、可审计、可收口的 release-ready 状态。

**Architecture:** 本计划分为两段。第一段只做 closeout 证据刷新，不改 SIMD 核心行为，优先恢复 `freeze-status` 绿态。第二段只做低风险流程固化，把当前分散在 runbook 和环境变量里的发布动作收口成单一入口，避免后续再次出现“代码是绿的，但证据链过期/缺步”的成熟度倒挂。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, Python checker scripts, GitHub Actions Windows evidence flow, QEMU CPUInfo evidence, Markdown docs.

---

## Review Summary

- 当前 worktree 的 SIMD diff 只是在 `Pointer` 路径上把 `atomic_load_ptr/atomic_store_ptr` 切换为 `atomic_load/atomic_store` 重载。
- 已验证通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前 freeze 阻塞点不是代码正确性，而是发布级证据链：
  - 最新 fast `gate` 没有包含 `qemu-cpuinfo-nonx86-evidence`
  - Windows evidence 已过 freshness 阈值，且早于最新 SIMD 源码

## Task 1: Freeze 当前审查基线

**Files:**

- Read: `src/fafafa.core.simd.pas`
- Read: `src/fafafa.core.simd.dispatch.pas`
- Read: `src/fafafa.core.simd.direct.pas`
- Read: `src/fafafa.core.simd.public_abi.impl.inc`
- Read: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: 记录当前 diff 与基线验证结果**

Run:

```bash
git diff --stat -- src/fafafa.core.simd.pas src/fafafa.core.simd.dispatch.pas src/fafafa.core.simd.direct.pas src/fafafa.core.simd.public_abi.impl.inc
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:

- diff 只落在原子 API 调用口径统一
- `check / DispatchAPI / DirectDispatch / gate` 全绿

**Step 2: 明确 freeze 缺口**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
```

Expected:

- `linux_gate_summary` PASS
- `windows_evidence_freshness` FAIL
- `linux_qemu_cpuinfo_nonx86_evidence` FAIL 或 `SKIP`

## Task 2: 刷新 Linux release gate 证据

**Files:**

- Use: `tests/fafafa.core.simd/BuildOrTest.sh`
- Output: `tests/fafafa.core.simd/logs/gate_summary.md`
- Output: `tests/fafafa.core.simd/logs/gate_summary.json`

**Step 1: 跑 release-gate，不再用 fast gate 充当 freeze 依据**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

Expected:

- runner 自动打开 `SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1`
- runner 自动要求 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1`
- `logs/gate_summary.md` 末行出现 `gate PASS`

**Step 2: 如果环境不适合直接跑 full strict，则至少显式补齐 cross gate**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' \
SIMD_GATE_QEMU_NONX86_EVIDENCE=0 \
SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 \
SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 \
SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 \
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 \
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:

- `qemu-cpuinfo-nonx86-evidence` 不再是 `SKIP`
- `freeze-status` 中 `linux_qemu_cpuinfo_nonx86_evidence` 进入 PASS

## Task 3: 刷新 Windows evidence

**Files:**

- Use: `tests/fafafa.core.simd/BuildOrTest.sh`
- Use: `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`
- Output: `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Output: `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

Before using the manual Windows path:

- if `win-evidence-preflight` still reports `RECENT_BILLING_BLOCK`, stop there
  and treat the batch as `code-green / release-evidence-blocked`
- do not use Wine/cmd as a stand-in for a real Windows host
- make sure `LAZBUILD` resolves to a native Windows `.exe/.bat/.cmd`, not a
  Wine-visible Linux ELF

**Step 1: 做 preflight，避免先开 GitHub job 再发现本地前置条件不满足**

Run:

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight
```

Expected:

- 明确 GH workflow、令牌、产物目录、canonical logs 回写路径都准备完成

**Step 2: 触发 Windows evidence via GH**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260408-152
```

Expected:

- `tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260408-152/` 生成 fresh 证据
- canonical `logs/windows_b07_gate.log` 被回写到最新批次

**Step 3: 验证 Windows evidence**

Run:

```bash
tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify
```

Expected:

- verifier PASS
- `windows_b07_gate.log` 与 closeout summary mtime 进入 freshness 窗口

## Task 4: 完成 closeout finalize

**Files:**

- Use: `tests/fafafa.core.simd/BuildOrTest.sh`
- Output: `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

**Step 1: 回写 Windows closeout 总结**

Run:

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-20260408-152
```

Expected:

- canonical Windows closeout summary 指向最新批次
- closeout summary 内容与 verifier 结果一致

**Step 2: 复核 freeze-ready**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
```

Expected:

- `ready=True`
- `mainline-ready=True`
- `cross-ready=True`

## Task 5: 把 closeout 流程固化成单一入口

**Files:**

- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.handoff.md`
- Modify: `src/fafafa.core.simd.README.md`

**Step 1: 增加 release closeout 聚合动作**

实现一个新的 runner action，例如 `closeout-release` 或 `freeze-ready`，内部顺序固定为：

```text
gate-strict
win-evidence-preflight
win-evidence-via-gh <batch-id>
win-closeout-finalize <batch-id>
freeze-status
```

Expected:

- 维护者不需要手写长环境变量串
- 文档里的“发布路径”与脚本入口一一对应

**Step 2: Windows runner 至少给出等价入口或清晰失败语义**

Expected:

- shell/batch parity 不要求完全同实现，但必须清晰说明“Windows 原生只负责 evidence verify / finalize，GH/closeout 主链由 shell 入口编排”

**Step 3: 更新真相源文档**

把唯一推荐 closeout 路径收口到以下文档：

- `docs/fafafa.core.simd.checklist.md`
- `docs/fafafa.core.simd.handoff.md`
- `src/fafafa.core.simd.README.md`

Expected:

- 不再出现“文档写 gate-strict，实际人工还要自己拼 cross gate + win evidence 命令”的二次翻译成本

## Task 6: 建立 evidence freshness 纪律

**Files:**

- Modify: `backlog.md`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
- Optional: `docs/fafafa.core.simd.closeout.md`

**Step 1: 明确 freshness 失效条件**

写死以下规则：

- 任一 `src/fafafa.core.simd*` 变更后，旧 Windows evidence 自动视为 stale
- 任一 closeout 候选必须重新跑 `gate-strict + win evidence + freeze-status`

**Step 2: 明确 artifact 生命周期**

Expected:

- latest canonical logs 始终指向“最近一次与当前源码对应”的证据
- 历史 evidence 归档保留，但不得继续充当 freeze 判断依据

## Acceptance

- 当前 SIMD diff 在 release 基线下保持 `check / DispatchAPI / DirectDispatch / gate` 通过
- `gate-strict` 或显式 cross gate 不再让 `qemu-cpuinfo-nonx86-evidence` 处于 `SKIP`
- Windows evidence 回到 freshness 窗口，且不早于最新 SIMD 源码
- `freeze-status` 返回 `ready=True`
- closeout 路径具备单一官方入口，文档与脚本口径一致
