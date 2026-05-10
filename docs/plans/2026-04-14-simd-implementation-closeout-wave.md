# SIMD Implementation Closeout Wave Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把本轮 `simd` src implementation closeout 的 source truth、closeout facts 和 handoff 边界一次性落盘，避免下轮再回到“靠聊天回忆当前结论”。

**Architecture:** 当前 worktree 已经有 fresh green baseline：`targeted release suites`、`impl-audit-nonx86`、`qemu-nonx86-evidence`、`closeout-host-local` 都在 2026-04-14 跑绿。本轮不再扩 public API / ABI，不再重做泛审查，而是把最容易回归的 NEON hygiene source truth 编进 checker，并把这轮的 implementation closeout 事实同步回 `closeout` 与 `implementation-matrix`。

**Tech Stack:** FreePascal/Lazarus, Bash runners, Python3 source checker, Markdown docs, existing `BuildOrTest.sh` evidence pipeline.

---

### Task 1: 固化 NEON hygiene source truth

**Files:**
- Modify: `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
- Read: `src/fafafa.core.simd.neon.pas`

**Step 1: 把 `neon.pas` 纳入 helper semantics checker**

要求：

- 不破坏现有 `wide_memory` checker
- 新增 `NEON_IMPL_FILE`
- 只补 source-side fragment checks，不做 runner 重构

**Step 2: 锁定 4 个最容易被误改的 truth**

至少覆盖：

- `NEONShiftLeftI32x16` invalid-count -> `ScalarShiftLeftI32x16`，valid -> `NEONShiftLeftI32x16Asm`
- `NEONShiftRightArithI64x4` invalid-count -> `ScalarShiftRightArithI64x4`，valid -> `NEONShiftRightArithI64x4Asm`
- `NEONShiftLeftI64x4Asm` 必须保留 `uxtw  x1, w1`
- `NEONSelectF32x4` 必须保留按 `mask/lane` 显式选择，而不是直接 scalar-forward

**Step 3: 运行 checker 验证**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
```

Expected:

- `NONX86_HELPER_SEMANTICS_SUMMARY ... status=ok`

**Step 4: 运行 patch 健康检查**

Run:

```bash
git diff --check -- tests/fafafa.core.simd/check_nonx86_helper_semantics.py
```

Expected:

- 无 whitespace / conflict marker 问题

---

### Task 2: 回填 implementation closeout 文档事实

**Files:**
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/fafafa.core.simd.implementation-matrix.md`

**Step 1: 在 closeout 文档写清当前轮次的真实结论**

要求：

- 不再把这轮描述成“只补注释”
- 要明确写成：当前已经落地了经 `release + impl-audit + QEMU evidence` 支撑的 `ABI / wiring / shift` 修正
- 把 `x86_64` source/runtime proof 与 `QEMU non-x86 runtime proof` 区分清楚

**Step 2: 把 2026-04-14 fresh evidence 路径写死**

必须引用：

- `tests/fafafa.core.simd/logs/qemu-multiarch-20260414-083827-1057268/summary.md`
- `tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085109-1103235/summary.md`
- `tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085836-1128552/summary.md`

**Step 3: 把 Task 2 / Task 3 从“待回填”推进到当前真实状态**

要求：

- `Task 2 / shift-bitwise`：标成当前已具备 fresh evidence，next action 改成 hold green
- `Task 3 / arithmetic-minmax-mul`：标成当前已具备 fresh evidence，next action 改成 hold green
- 增加一条 `NEON hygiene` 叙事：`src/fafafa.core.simd.neon.pas` 当前已 green，但若后续切历史可单列

**Step 4: 运行文档命中检查**

Run:

```bash
rg -n "2026-04-14|083827-1057268|085109-1103235|085836-1128552|NEON hygiene|ABI/wiring/shift" \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md
```

Expected:

- 新证据路径与新结论可直接命中

---

### Task 3: 保存这轮 handoff 计划

**Files:**
- Create: `docs/plans/2026-04-14-simd-implementation-closeout-wave.md`

**Step 1: 把当前轮次的执行顺序写成可重放计划**

要求：

- 先锁 source truth，再回填 closeout docs，再做 release 验证
- 诚实写明“当前 worktree 已有 green baseline”，不要伪造 red 阶段

**Step 2: 写清下一轮边界**

要求：

- 下一轮不再做 correctness 大盘
- 只允许做 `NEON wrapper/select hygiene` 或 `RISCVV facade/register elegance` 一类的优雅化专项

**Step 3: 运行文件存在性检查**

Run:

```bash
test -f docs/plans/2026-04-14-simd-implementation-closeout-wave.md
```

Expected:

- 文件存在

---

## Post-Closeout Note

在这份计划落盘后，当前 worktree 又完成了一轮只针对接口/注册层的最小优雅化收口：

- `src/fafafa.core.simd.neon.pas` 只补了 wrapper vs `*Asm helper` 的职责边界说明，并保留已有 helper semantics checker 锁定的 shift/select 行为真相
- `src/fafafa.core.simd.riscvv.facade.inc` 明确把 scalar-pass-through facade helper 留在 base scalar slot，不再继续维持无价值的 backend-local 包装层
- `src/fafafa.core.simd.riscvv.register.inc` 保留 `ExtractI64x4` / `ExtractI32x8` / `ExtractI32x16` 的显式 asm-gated 结构；这是经 fresh `register-truthfulness` 验证后的刻意选择，不是遗漏清理

这轮 follow-up 对应的 fresh 证据是：

- `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line` -> `NONX86_HELPER_SEMANTICS_SUMMARY checks=39 status=ok`
- `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict` -> `miswired=0`
- `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line` -> `issues=0 status=ok`
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86` -> `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
