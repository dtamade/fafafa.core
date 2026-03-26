# Strict L0 Merge Closeout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把当前 strict non-SIMD L0 波次收口为可合并状态，补齐 README / 文档一致性，并输出最终 merge checklist。

**Architecture:** 本次不再扩张 L0 范围，也不触碰 SIMD。执行重点是把 `bits` / `layout` / `endian` / `contracts` 这组 strict L0 能力的 source-of-truth、测试入口说明和最终收口文档统一起来，再用现有 gate 结果与最终文本校验支撑合并。

**Tech Stack:** Free Pascal / Lazarus, shell BuildOrTest scripts, markdown docs.

---

### Task 1: 固化收口范围与执行顺序

**Files:**
- Create: `docs/plans/2026-03-26-strict-l0-merge-closeout.md`

**Step 1: 写计划文件**

- 明确本轮只收口 strict non-SIMD L0。
- 明确包含模块：`base`、`contracts`、`bits`、`layout`、`endian`、`option`、`result`、`atomic`、`mem.allocator.foundation`。
- 明确 deferred：`platform`、`span`、所有 SIMD 相关内容。

**Step 2: 记录验证命令**

Run:
```bash
bash tests/fafafa.core.contracts/BuildOrTest.sh test
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
bash tests/fafafa.core.option/BuildOrTest.sh test
bash tests/fafafa.core.result/BuildOrTest.sh test
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test
bash tests/fafafa.core.atomic/BuildOrTest.sh test
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation
git diff --check
```

### Task 2: 对齐 README / 文档口径

**Files:**
- Modify: `tests/fafafa.core.bits/README.md`
- Modify: `tests/fafafa.core.layout/README.md`
- Modify: `tests/fafafa.core.endian/README.md`
- Review: `tests/fafafa.core.contracts/README.md`
- Review: `docs/fafafa.core.bits.md`
- Review: `docs/fafafa.core.layout.md`
- Review: `docs/fafafa.core.endian.md`
- Review: `docs/fafafa.core.contracts.md`
- Review: `docs/fafafa.core.l0.foundation.md`
- Review: `docs/ARCHITECTURE_LAYERS.md`

**Step 1: 补齐 source-of-truth 一致性**

- 把 `bits` / `layout` / `endian` README 的 source-of-truth 与模块文档保持一致。
- 明确它们都受 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 约束。

**Step 2: 补齐 strict L0 边界表述**

- 在 README 顶部明确“当前测试入口锁定 strict non-SIMD L0 today contract”。
- 避免 README 只描述模块自身，遗漏 L0 边界与 deferred 项约束。

### Task 3: 产出最终收口清单

**Files:**
- Create: `docs/fafafa.core.l0.merge-closeout.md`

**Step 1: 写模块清单**

- 列出本轮 strict L0 实际纳入模块。
- 区分新增能力、既有能力、兼容层与 deferred 项。

**Step 2: 写验证结果**

- 记录已执行的 gate 与结果。
- 记录 `NoContracts` smoke 的验证结论。

**Step 3: 写合并前注意事项**

- 当前分支 / 工作树状态。
- 尚未提交的改动范围。
- 需要保持不扩张的边界：`platform`、`span`、SIMD。

### Task 4: 最终校验

**Files:**
- Review: `docs/fafafa.core.l0.merge-closeout.md`

**Step 1: 运行文本校验**

Run:
```bash
git diff --check
```

Expected:
- 无尾随空格、无 patch 格式问题。

**Step 2: 汇总结论**

- 给出当前是否“可合并”的结论。
- 明确说明这只是工作树状态，不等于已经 commit / merge。
