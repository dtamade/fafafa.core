# SIMD Parallel Closeout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 并行完成 SIMD 模块当前最高优先级的文档收口、API 文档纠偏、伪 skip 修复，以及 gate/gate-strict 分层说明更新。

**Architecture:** 采用互不冲突的并行切片：文档组负责 landing/过时文档/示例定位；测试组负责 cpuinfo 伪 skip 改为显式 skip；门禁组负责 gate/gate-strict 的快门禁/发布门禁命名与说明。避免触碰 `SSE2`、dispatch 大表、backend 真实实现，只做低风险收口。

**Tech Stack:** FreePascal/Lazarus, bash BuildOrTest runners, Markdown docs, FPCUnit tests.

---

### Task 1: 文档 landing 与过时文档收口

**Files:**
- Modify: `src/fafafa.core.simd.README.md`
- Modify: `src/fafafa.core.simd.architecture.md`
- Modify: `src/fafafa.core.simd.next-steps.md`
- Modify: `docs/fafafa.core.simd.md`
- Modify: `docs/fafafa.core.simd.api.md`

**Intent:** 统一“阅读入口 / 真相源 / 过时说明 / API 名称”。

### Task 2: cpuinfo 测试伪 skip 修复

**Files:**
- Modify: `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas`
- Modify: `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.lazy.testcase.pas`
- Verify: `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`

**Intent:** 把 `AssertTrue(..., True)` 形式的伪 skip 改成测试框架可识别的显式 skip，避免绿色误导。

### Task 3: gate / gate-strict 分层命名与说明

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.maintenance.md`
- Modify: `src/fafafa.core.simd.STABLE`

**Intent:** 明确默认 `gate` 是快门禁，`gate-strict` 是发布门禁，并把推荐验证命令同步到文档。

### Task 4: 定向验证

**Files:**
- Verify only: `tests/fafafa.core.simd/BuildOrTest.sh`
- Verify only: `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`

**Commands:**
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
- `bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_BackendSelection`
- `bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --list-suites`

