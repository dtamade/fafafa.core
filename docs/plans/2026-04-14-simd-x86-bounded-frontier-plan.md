# SIMD X86 Bounded Frontier Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在当前 non-x86 implementation closeout 已 green 的前提下，用最高 ROI 的方式完成一轮 bounded x86 implementation 推进，优先锁定一个真实、可证明、可收口的 x86 family 问题，而不是再次做泛审查。

**Architecture:** 当前 `simd` 的 non-x86 主线已经有 `impl-smoke-nonx86` / `impl-audit-nonx86` / `closeout-host-local` 和 QEMU evidence。下一轮不再回头打磨 non-x86，而是先把这轮 non-x86 结果提交成稳定基线；随后只挑一个 bounded x86 目标做 TDD 式推进。首选 frontier 是 `AVX512 U32x16/U64x8`，因为现有 `DispatchAPI` 已经有明确的 mapping/parity 测试和对应 register/family 文件，命中文件少、证据链短、实现闭环快。若该方向在限定时间内没有产出高信号红点，则立即切到 `AVX2 capability/facade` 分支，不做大范围探索。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, existing `DispatchAPI/DirectDispatch/DataPlane` tests, x86 SIMD backends (`AVX2` / `AVX512`), current implementation matrix / closeout docs.

---

### Task 1: 冻结当前 non-x86 implementation closeout 基线

**Files:**
- Verify only: `tests/fafafa.core.simd/BuildOrTest.sh`
- Verify only: `tests/fafafa.core.simd/buildOrTest.bat`
- Verify only: `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
- Verify only: `docs/fafafa.core.simd.closeout.md`
- Verify only: `docs/fafafa.core.simd.implementation-matrix.md`

**Step 1: 运行高频 smoke**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
```

Expected:
- `NONX86_IMPL_SMOKE_SUMMARY ... status=ok`

**Step 2: 运行实现聚合审计**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
```

Expected:
- `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`

**Step 3: 运行基础 source/runtime checker**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:
- exit `0`

**Step 4: 检查 patch 形状**

Run:
```bash
git diff --check -- tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat docs/fafafa.core.simd.closeout.md docs/fafafa.core.simd.implementation-matrix.md
```

Expected:
- no output

**Step 5: 提交 non-x86 收口基线**

Run:
```bash
git add tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat docs/fafafa.core.simd.closeout.md docs/fafafa.core.simd.implementation-matrix.md docs/plans/2026-04-14-simd-x86-bounded-frontier-plan.md
git commit -m "simd: close out non-x86 implementation audit wave"
```

---

### Task 2: 先做 AVX512 U32x16/U64x8 bounded triage

**Files:**
- Verify/Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Candidate implementation: `src/fafafa.core.simd.avx512.register.inc`
- Candidate implementation: `src/fafafa.core.simd.avx512.u32x16_family.inc`
- Candidate implementation: `src/fafafa.core.simd.avx512.u64x8_family.inc`

**Step 1: 先跑现有 AVX512 映射与 parity 基线**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:
- 如果现有 `Test_AVX512_U32x16_U64x8_MappingAndParity` 已经暴露红点，则直接进入 Task 3
- 如果全绿，不做“大审查”，继续 Step 2

**Step 2: 在 `DispatchAPI` 里先补一个最小 failing test**

要求：
- 只针对 `AVX512 U32x16/U64x8`
- 优先补 `shift boundary` / `mapping ownership` / `scalar contract` 三类之一
- 不顺手修改 `DirectDispatch` / `DataPlane`

**Step 3: 跑红**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:
- FAIL 明确落在 `AVX512 U32x16/U64x8`

**Step 4: 若 30-45 分钟内没有拿到高信号红点，立即停止本 task**

Stop condition:
- 不继续翻 `AVX512` 全家桶
- 直接切到 Task 5 的 `AVX2 capability/facade` 分支

---

### Task 3: 最小修复 AVX512 U32x16/U64x8 单点问题

**Files:**
- Modify: `src/fafafa.core.simd.avx512.register.inc`
- Modify: `src/fafafa.core.simd.avx512.u32x16_family.inc`
- Modify: `src/fafafa.core.simd.avx512.u64x8_family.inc`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`

**Step 1: 只修红掉的那个 family / contract**

要求：
- 只改一个 family
- 不动 public API / ABI
- 不顺手改 `AVX2` / `SSE*`

**Step 2: 跑绿当前 red test**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:
- PASS

**Step 3: 扩到最小安全面**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

Expected:
- PASS

**Step 4: 只在需要时补 source truth**

要求：
- 如果修复属于 register ownership / facade contract / wrapper-vs-base-scalar 这一类，才新增对应 checker
- 如果只是纯算术实现修正，不新增“花哨 checker”，只保留 runtime proof

**Step 5: 提交**

Run:
```bash
git add tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas src/fafafa.core.simd.avx512.register.inc src/fafafa.core.simd.avx512.u32x16_family.inc src/fafafa.core.simd.avx512.u64x8_family.inc
git commit -m "simd: fix bounded avx512 wide integer contract"
```

---

### Task 4: 把 AVX512 单点问题升级为长期可维护证据

**Files:**
- Maybe modify: `docs/fafafa.core.simd.closeout.md`
- Maybe modify: `docs/fafafa.core.simd.implementation-matrix.md`
- Maybe modify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: 只有在修复确实产出新 contract 时才更新 matrix**

要求：
- 写清 backend / slot / contract / source truth / runtime evidence / next action
- 不写空泛结论

**Step 2: 只有在该类问题会重复出现时，才考虑新的 smoke 入口**

要求：
- 不新增又一个“大而全”入口
- 只在能显著复利时才加

**Step 3: 验证 docs patch**

Run:
```bash
git diff --check -- docs/fafafa.core.simd.closeout.md docs/fafafa.core.simd.implementation-matrix.md tests/fafafa.core.simd/BuildOrTest.sh
```

Expected:
- no output

---

### Task 5: 如果 AVX512 不出红点，立即切换到 AVX2 capability/facade 分支

**Files:**
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Candidate implementation: `src/fafafa.core.simd.avx2.register.inc`
- Candidate implementation: `src/fafafa.core.simd.avx2.facade.inc`

**Step 1: 只用现成 tests 做 triage**

关注现有用例：
- `Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable`
- `Test_AVX2_BackendCapabilities_Clear_FMA_When_VectorAsmDisabled`
- `Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable`
- `Test_AVX2_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`
- `Test_AVX2_FacadeScalarFallback_Uses_BaseFill_Without_Redundant_Win64_Rebinds`
- `Test_AVX2_FmaSlots_StayScalar_When_HardwareFmaUnavailable`

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

**Step 2: 拿到明确红点后，再写最小 failing test / 最小修复**

要求：
- 只改 capability bits 或 facade/base-fill contract
- 不把范围扩到 `AVX2` 全实现

**Step 3: 跑绿**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
```

**Execution Update (2026-04-14):**

- fresh triage 结果：现有 `DispatchAPI` 在当前宿主机是 green，没有立刻暴露新的 bounded `AVX2` 实现红点
- 这一轮收口点改为 **接口证据缺口**，而不是继续扩大实现面审查：
  - 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2FMA_When_FusedPathUsable`
  - 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_When_NativeShuffleSlotsUsable`
  - 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_AVX2VectorAsmGatedBits_When_VectorAsmDisabled`
- 目标是把 `registered table -> BackendInfo.Capabilities -> TryGetSimdBackendPodInfo(...).CapabilityBits` 这条 AVX2 public-ABI 可见契约显式锁住，避免后续再次只靠内部 `BackendInfo` 推断
- 这符合 bounded 收口原则：不扩到 `AVX2` 全实现，只补最小 public contract proof

---

### Task 6: 明确不做的事

**Do not:**
- 不再回头重做 non-x86 泛审查
- 不开启新的“大矩阵全家桶”重构
- 不在没有红点前先重构 `DispatchAPI/DirectDispatch/DataPlane`
- 不先做测试去重；只有在 x86 单点问题完成后，才讨论这件事
- 不把没有 fresh runtime proof 的 x86 结论写进 closeout

---

### 推荐执行顺序（最高 ROI）

1. 先提交当前 non-x86 closeout 基线
2. 再做 `AVX512 U32x16/U64x8` bounded triage
3. 有红就修并固化证据
4. 无红 30-45 分钟内立刻切 `AVX2 capability/facade`
5. 全程只做单点、小批、可证明修复
