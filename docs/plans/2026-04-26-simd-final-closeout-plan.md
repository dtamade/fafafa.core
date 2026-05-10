# SIMD Final Closeout Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 以最短路径把 `fafafa.core.simd` 从“实现层已收口但 release evidence 已过期”推进到 `freeze-status` 全绿的完成态。

**Architecture:** 不再重新打开 SIMD 接口审查或实现泛审查；默认认为当前实现层基线已经成立，主线只做 release closeout 刷新。执行顺序固定为：准备可 dispatch 的干净 ref，刷新 host-local/Linux 证据，刷新 Windows GH evidence，最后以 `freeze-status` 作为唯一完成判据；只有 fresh red 才允许回到代码修复。

**Tech Stack:** FreePascal/Lazarus, Bash runners, Python verifiers, QEMU multi-arch evidence, GitHub Actions Windows evidence flow, Markdown closeout docs.

---

### Task 1: 锁定 closeout 基线与 stop condition

**Files:**
- Read: `src/fafafa.core.simd.README.md`
- Read: `docs/fafafa.core.simd.closeout.md`
- Read: `docs/fafafa.core.simd.checklist.md`
- Read: `docs/fafafa.core.simd.handoff.md`
- Read: `docs/fafafa.core.simd.implementation-matrix.md`

**Step 1: 读取 closeout 主入口说明**

Run:
```bash
sed -n '1,120p' src/fafafa.core.simd.README.md
sed -n '1,260p' docs/fafafa.core.simd.closeout.md
sed -n '1,220p' docs/fafafa.core.simd.checklist.md
```

Expected:

- 明确 canonical closeout 入口是 `closeout-release`
- 明确 host-local 入口是 `closeout-host-local`
- 明确最终完成判据是 `freeze-status`

**Step 2: 读取实现层 ledger**

Run:
```bash
sed -n '1,180p' docs/fafafa.core.simd.implementation-matrix.md
sed -n '1,180p' docs/fafafa.core.simd.handoff.md
```

Expected:

- 当前实现层结论为 `hold green`
- 没有新的必须先做的泛审查任务

**Step 3: 记录 stop condition**

完成标准固定为：

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- 输出必须同时满足：
  - `ready=True`
  - `mainline-ready=True`
  - `cross-ready=True`

**Step 4: Commit**

```bash
git add docs/plans/2026-04-26-simd-final-closeout-plan.md
git commit -m "docs: add simd final closeout plan"
```

---

### Task 2: 准备可执行 Windows evidence 的干净 ref

**Files:**
- Read: `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`
- Read: `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`

**Step 1: 确认当前仓库是否允许直接 dispatch**

Run:
```bash
git status --short
git branch --show-current
git rev-parse --abbrev-ref --symbolic-full-name @{upstream}
git rev-list --left-right --count @{upstream}...HEAD
```

Expected:

- 如果工作区脏，记为 `dispatch blocked`
- 如果本地 HEAD 未推送到远端 ref，记为 `dispatch blocked`

**Step 2: 读取 GH Windows evidence 拒绝条件**

Run:
```bash
sed -n '260,330p' tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh
sed -n '1,120p' tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md
```

Expected:

- 明确 dirty worktree / remote ref mismatch 会拒绝 dispatch
- 明确显式 `run-id` 旁路仅适合复用既有 run

**Step 3: 选择干净 ref 策略**

只允许以下两种：

- 策略 A：在只含 SIMD closeout 相关提交的分支 / worktree 上执行
- 策略 B：把当前 SIMD closeout 提交推到远端可见 ref 后执行

禁止：

- 在当前混有大量非 SIMD 脏改动的 worktree 上直接尝试 GH dispatch

**Step 4: 验证 preflight**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight
```

Expected:

- `STATUS=PASS`
- 若失败，必须先解决 GH/billing/runner block，再继续

**Step 5: Commit**

若此任务只形成执行决策、不改文件，则不单独提交；与下一任务的执行批次一起提交。

---

### Task 3: 刷新 host-local/Linux closeout 证据

**Files:**
- Verify only

**Step 1: 跑 x86 bounded frontier smoke**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
```

Expected:

- `status=ok`

**Step 2: 跑 non-x86 高频 smoke**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
```

Expected:

- `status=ok`

**Step 3: 跑完整 non-x86 实现审计**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
```

Expected:

- `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`

**Step 4: 跑 host-local strict closeout**

Run:
```bash
SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' \
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 \
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

Expected:

- `[CLOSEOUT-HOST-LOCAL] OK`
- fresh QEMU runtime summary / cpuinfo summary 落盘

**Step 5: 若 fresh red，执行 3-strike 约束**

规则：

- 第 1 次 red：只修当前直接失败点
- 第 2 次 red：换诊断入口，不重复同一命令/假设
- 第 3 次仍 red：停下来写 blocker 结论，不继续泛改

**Step 6: Commit**

如果需要修代码或回填文档：

```bash
git add <only-simd-files>
git commit -m "simd: refresh host-local closeout evidence"
```

---

### Task 4: 刷新 Windows evidence 并 finalize

**Files:**
- Verify only unless docs/log pointers need refresh

**Step 1: 从干净 ref 触发 GH Windows evidence**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260426-152
```

Expected:

- artifact 下载成功
- `windows_b07_gate.log` 更新到 canonical logs
- backfill cross gate 成功
- closeout finalize 成功

**Step 2: 如果已有现成 GH run-id，走旁路复用**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260426-152 <run-id>
```

Expected:

- 跳过 dispatch
- 仍完成 download / verify / finalize

**Step 3: 独立验证 Windows evidence**

Run:
```bash
tests/fafafa.core.simd/buildOrTest.bat evidence-win-verify
```

Expected:

- verifier PASS

**Step 4: 确认 closeout finalize 结果**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-20260426-152
```

Expected:

- closeout summary 与 freeze json 更新

**Step 5: Commit**

如果这一步产生了需要入库的 closeout 文档或 canonical pointer 更新：

```bash
git add <only-simd-files>
git commit -m "simd: refresh windows closeout evidence"
```

---

### Task 5: 最终 freeze 判定与文档回填

**Files:**
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/fafafa.core.simd.implementation-matrix.md`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.handoff.md`

**Step 1: 跑最终 freeze 判定**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
```

Expected:

- `ready=True`
- `mainline-ready=True`
- `cross-ready=True`

**Step 2: 仅在 freeze 全绿后回填文档**

回填内容只允许是 fresh 结果：

- 最新 gate summary 时间
- 最新 QEMU summary 路径
- 最新 Windows evidence batch id / summary
- 最新 freeze 结论

禁止：

- 用旧日志“猜测完成”
- 在 `freeze-status` 仍红时把文档写成已完成

**Step 3: 复查 freeze 文档一致性**

Run:
```bash
rg -n "ready=True|mainline-ready=True|cross-ready=True|2026-04-26|SIMD-20260426-152" \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.handoff.md
```

Expected:

- 真相源文档与 fresh freeze 结果一致

**Step 4: Commit**

```bash
git add docs/fafafa.core.simd.closeout.md \
        docs/fafafa.core.simd.implementation-matrix.md \
        docs/fafafa.core.simd.checklist.md \
        docs/fafafa.core.simd.handoff.md
git commit -m "simd: finalize release closeout status"
```

---

## Execution Order

1. Task 1
2. Task 2
3. Task 3
4. Task 4
5. Task 5

## Completion Criteria

- 实现层不再出现 fresh red；若出现，只允许修当前直接 blocker。
- `closeout-host-local` 绿。
- Windows GH evidence 下载、校验、finalize 绿。
- `freeze-status` 最终返回：
  - `ready=True`
  - `mainline-ready=True`
  - `cross-ready=True`
- closeout/checklist/handoff/implementation-matrix 与 fresh 结果一致。

## Non-Goals

- 不再开启 SIMD 接口设计泛审查。
- 不再开启 SIMD 实现泛审查。
- 不再对 `src/fafafa.core.simd.sse2.pas` 做新的结构性大拆分。
- 不把 non-SIMD 脏改动混进 closeout 批次。
