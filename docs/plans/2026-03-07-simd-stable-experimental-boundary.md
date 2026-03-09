# SIMD Stable Experimental Boundary Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不破坏现有行为的前提下，明确 SIMD 模块 stable / experimental 边界，减少 umbrella unit 与维护文档对实验后端成熟度的误导。

**Architecture:** 采用低风险收口：优先修正文档、README、STABLE marker、入口注释与 gate 提示，不先改变实际编译行为。只有在证据表明当前入口说明不足以约束维护者时，才补最小的显式提示或编译开关说明，而不直接重构后端接入方式。

**Tech Stack:** FreePascal/Lazarus, Markdown docs, bash gate scripts.

---

### Task 1: 边界现状盘点

**Files:**
- Read: `src/fafafa.core.simd.pas`
- Read: `src/fafafa.core.simd.base.pas`
- Read: `src/fafafa.core.simd.README.md`
- Read: `docs/fafafa.core.simd.md`
- Read: `docs/fafafa.core.simd.api.md`
- Read: `src/fafafa.core.simd.STABLE`
- Read: `tests/fafafa.core.simd/BuildOrTest.sh`

**Intent:** 明确 stable 与 experimental 口径、当前入口接线、以及是否已有实验隔离检查。

### Task 2: 低风险边界收口

**Files:**
- Modify: `src/fafafa.core.simd.pas`
- Modify: `src/fafafa.core.simd.README.md`
- Modify: `docs/fafafa.core.simd.md`
- Modify: `docs/fafafa.core.simd.api.md`
- Modify: `src/fafafa.core.simd.STABLE`

**Intent:** 统一说明：默认公开 façade 稳定；experimental intrinsics 已隔离；`RISCVV` 属实验后端/受限成熟度，不应被读者误解为与 `SSE2/AVX2/NEON` 同成熟度。

### Task 3: gate/脚本口径补充

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Read/Verify: `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`

**Intent:** 在 usage 或日志中补一句 experimental boundary 提示，让维护者知道默认 gate 对 experimental intrinsics 是隔离校验，不等于实验路径全部发布级保证。

### Task 4: 定向验证

**Commands:**
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- `bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics`
- `bash tests/fafafa.core.simd/BuildOrTest.sh unknown-action || true`

