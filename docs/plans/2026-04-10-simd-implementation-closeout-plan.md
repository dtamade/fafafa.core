# SIMD Implementation Closeout Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不改 SIMD 公共接口的前提下，把 `fafafa.core.simd` 的实现层问题一次性收口到“register ownership 说真话、真实 asm 接线完整、语义正确性可复验、checker 可自动报警”的状态。

**Architecture:** 本计划分四段推进。第一段完成 `NEON` register truthfulness 全量收口，并把规则固化为自动检查器。第二段把同一套方法应用到 `RISCVV`。第三段只审真实实现 correctness，不再混入接口或 ownership 讨论。第四段整理测试结构，把这轮修复沉淀成低维护成本的 grouped helper / checker 体系。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, Python3 maintenance checkers, `ripgrep`, existing `BuildOrTest.sh` / `buildOrTest.bat` gate flow.

---

## Scope And Constraints

- 不改 `fafafa.core.simd` 对外接口，不引入新的 public ABI。
- 优先修改：
  - `src/fafafa.core.simd.neon.register.inc`
  - `src/fafafa.core.simd.riscvv.register.inc`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `tests/fafafa.core.simd/check_interface_implementation_completeness.py`
  - `tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- 默认验证命令统一使用 release 路径：
  - `FAFAFA_BUILD_MODE=Release`
  - 非 x86 opt-in 用：
    - `SIMD_ENABLE_NEON_BACKEND=1`
    - `SIMD_ENABLE_RISCVV_BACKEND=1`
- `check` / `gate` 必须串行执行，不能并行跑，避免共享 `bin2/lib2` 造成假阴性。

## Phase Order

1. Task 1: `NEON` register truthfulness 全量收口
2. Task 2: 新增 ownership 自动 checker 并接入 gate
3. Task 3: `RISCVV` 按同一模板收口
4. Task 4: `NEON/RISCVV` 真实 asm helper correctness
5. Task 5: `NEON/RISCVV` 真实 asm integer semantics correctness
6. Task 6: grouped test helper / checker 收尾与减噪

---

### Task 1: 完成 NEON register truthfulness 全量收口

**Files:**
- Modify: `src/fafafa.core.simd.neon.register.inc`
- Modify: `src/fafafa.core.simd.neon.scalar.autowrap.inc`
- Modify: `src/fafafa.core.simd.neon.scalar.wide_memory.inc`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/check_interface_implementation_completeness.py`

**Step 1: 扩充 failing source/runtime 审计**

在 `TTestCase_DispatchAPI.Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` 中把宽整数族分三类断言清楚：

- `ASM_EXACT`：`@NEONFoo`
- `ASM_SUFFIX_ONLY`：`@NEONFoo_ASM`
- `WRAPPER_ONLY`：`FillBaseDispatchTable` 继承

首批必须覆盖：

```text
I32x16 / I32x8 / I64x4 / I64x8 / U32x8 / U64x4
```

**Step 2: 跑 DispatchAPI，确认先红**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:

- `BUILD OK`
- `TEST FAIL`
- 失败点落在新增的 source/runtime ownership 断言

**Step 3: 修改 NEON register**

规则固定：

- 真 `assembler` 定义存在时：只在 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 下注册
- 只有 `*_ASM` 真正实现时：明确接到 `*_ASM`
- 只有 scalar wrapper 时：从 no-asm 注册区删除，继承 `FillBaseDispatchTable`

**Step 4: 同步 whitelist**

在 `check_interface_implementation_completeness.py` 里为 `NEON` 增加新的 intentional-base-scalar 集合，避免 gate 对“有意继承 scalar”的 slot 误报缺口。

**Step 5: 跑 targeted 回归**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:

- `BUILD OK`
- `TEST OK`
- `LEAK OK`

**Step 6: 跑 non-x86 parity 联合回归**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity
```

Expected:

- `TEST OK`
- `NEON` 在 `vector asm disabled` 情况下退回 scalar
- `NEON` 在 `vector asm enabled` 情况下只对真实 native slot 保持 non-scalar

**Step 7: 跑完整度和门禁**

Run:

```bash
python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict --strict-level p2 --json
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check -- src/fafafa.core.simd.neon.register.inc tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas tests/fafafa.core.simd/check_interface_implementation_completeness.py
```

Expected:

- `P0=0 P1=0 P2=0`
- `check OK`
- `gate OK`
- `git diff --check` clean

**Step 8: Commit**

```bash
git add src/fafafa.core.simd.neon.register.inc \
  src/fafafa.core.simd.neon.scalar.autowrap.inc \
  src/fafafa.core.simd.neon.scalar.wide_memory.inc \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/check_interface_implementation_completeness.py
git commit -m "simd: close neon register truthfulness gaps"
```

---

### Task 2: 新增 non-x86 register truthfulness 自动 checker

**Files:**
- Create: `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Modify: `docs/fafafa.core.simd.checklist.md`

**Step 1: 写 checker 的最小契约**

Checker 必须输出四类结果：

```text
asm_exact
asm_suffix_only
wrapper_only
miswired
```

支持 backend 参数：

```text
--backend neon
--backend riscvv
--summary-line
--json
--strict
```

**Step 2: 加一个最小负例 fixture**

新增最小 fixture，至少覆盖：

- `wrapper_only` 却出现在 asm-only 区
- `asm_suffix_only` 却仍接到 wrapper 名字
- `no-asm` block 出现 backend-owned 假阳性

**Step 3: 跑 fixture，确认先红再绿**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture bad
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture good
```

Expected:

- `bad` 返回非零
- `good` 返回零

**Step 4: 对当前仓库跑真实检查**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
```

Expected:

- `neon` 绿
- `riscvv` 先允许红，用于下一任务收口

**Step 5: 接入 check/gate**

在 `BuildOrTest.sh` / `buildOrTest.bat` 中加入：

- `check` 路径 summary-line
- `gate` 路径 strict 模式

**Step 6: 更新 checklist**

在 `docs/fafafa.core.simd.checklist.md` 增加：

```bash
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
```

**Step 7: Commit**

```bash
git add tests/fafafa.core.simd/check_nonx86_register_truthfulness.py \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  docs/fafafa.core.simd.checklist.md
git commit -m "simd: add nonx86 register truthfulness checker"
```

---

### Task 3: 把同一套 truthfulness 模板应用到 RISCVV

**Files:**
- Modify: `src/fafafa.core.simd.riscvv.register.inc`
- Modify: `src/fafafa.core.simd.riscvv.facade.inc`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/check_interface_implementation_completeness.py`
- Modify: `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`

**Step 1: 先补 failing source/runtime 审计**

优先扩现有：

- `Test_RISCVV_FacadeSlots_Reuse_BaseScalar_When_Wrappers_Are_ScalarPassThrough`
- `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`

要求同样分清：

- 真 native
- 只有 wrapper
- intentional base scalar

**Step 2: 跑 checker + DispatchAPI，确认先红**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:

- 至少一项红在 `riscvv` wiring / ownership

**Step 3: 修 register truthfulness**

规则与 `NEON` 一致：

- 真 native → asm-only / rvv-only 注册
- wrapper-only → 继承 base scalar
- 不再保留“名字看起来像 RISCVV、本质只是 scalar forwarder”的 backend-owned slot

**Step 4: 同步 completeness 和 checker**

把 `RISCVV` intentional-base-scalar 集合同步到：

- `check_interface_implementation_completeness.py`
- `check_nonx86_register_truthfulness.py`

**Step 5: 跑 targeted 回归**

Run:

```bash
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
```

Expected:

- `DispatchAPI` 绿
- `NonX86BackendParity` 绿
- `RISCVV truthfulness checker` 绿

**Step 6: 跑模块门禁**

Run:

```bash
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:

- `check OK`
- `gate OK`

**Step 7: Commit**

```bash
git add src/fafafa.core.simd.riscvv.register.inc \
  src/fafafa.core.simd.riscvv.facade.inc \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/check_interface_implementation_completeness.py \
  tests/fafafa.core.simd/check_nonx86_register_truthfulness.py
git commit -m "simd: close riscvv register truthfulness gaps"
```

---

### Task 4: 审真实 asm helper correctness，不再讨论 ownership

**Files:**
- Modify: `src/fafafa.core.simd.neon.scalar.wide_memory.inc`
- Modify: `src/fafafa.core.simd.riscvv.helpers.inc`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`

**Target Families:**

```text
LoadI64x4
StoreI64x4
SplatI64x4
ZeroI64x4
InsertI32x8 / InsertI32x16 / InsertI64x4
ExtractI32x8 / ExtractI32x16 / ExtractI64x4
```

**Step 1: 在 direct / parity 测试里补边界值**

覆盖：

- 正负数
- `0`
- `High(Int32/Int64)`
- `Low(Int32/Int64)`
- 非对齐 / 对齐路径

**Step 2: 先跑 targeted，确认缺陷能被打中**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_NonX86BackendParity
```

Expected:

- 如果 helper 存在 lane 顺序、符号、store/load 对称性问题，这里先红

**Step 3: 修 helper 实现**

只改真实 helper，不碰 facade / public API。

**Step 4: 跑 helper 定向回归**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_NonX86BackendParity
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_NonX86BackendParity
```

Expected:

- direct / facade / dispatch 三层一致

**Step 5: Commit**

```bash
git add src/fafafa.core.simd.neon.scalar.wide_memory.inc \
  src/fafafa.core.simd.riscvv.helpers.inc \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas
git commit -m "simd: verify nonx86 helper asm correctness"
```

---

### Task 5: 审真实 asm integer semantics correctness

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Modify: `src/fafafa.core.simd.neon.compare.inc`
- Modify: `src/fafafa.core.simd.riscvv.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Target Semantics:**

```text
Compare: Eq / Lt / Gt / Le / Ge / Ne
Shift: Left / Right / RightArith
Bitwise: And / Or / Xor / Not / AndNot
Arithmetic: Add / Sub / Mul
Selection: signed / unsigned min/max
```

**Step 1: 先按 family 分小批写定向差分测试**

建议顺序：

1. `I32x8 / U32x8`
2. `I64x4 / U64x4`
3. `I32x16`
4. `I64x8`

每批只加一个 family，避免混改。

**Step 2: 每批先跑红**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

Expected:

- 如果实现错误，失败应落在具体 family / lane / shift-count

**Step 3: 最小修复实现**

要求：

- 只修一个 family
- 只处理一个语义类
- 不顺手重构别的 backend

**Step 4: 每批跑绿**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:

- `DispatchAPI` 绿
- `DirectDispatch` 绿
- `DataPlane` 绿
- `check` 绿

**Step 5: family 完成后再跑总门禁**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:

- 两条 non-x86 opt-in 路径都通过

**Step 6: Commit**

```bash
git add src/fafafa.core.simd.neon.pas \
  src/fafafa.core.simd.neon.compare.inc \
  src/fafafa.core.simd.riscvv.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
git commit -m "simd: validate nonx86 integer asm semantics"
```

---

### Task 6: 收尾 grouped helper / checker，降低后续维护成本

**Files:**
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
- Modify: `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
- Modify: `docs/fafafa.core.simd.checklist.md`

**Step 1: 抽 grouped slot list**

把重复的大段断言沉淀成：

- grouped slot arrays
- shared assert helper
- source audit helper
- runtime equality helper

要求新增一个 family 只改一处名单。

**Step 2: 跑 DispatchAPI，确认重构不改行为**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:

- 仅结构变化，无语义变化

**Step 3: 同步 wiring / truthfulness checker**

保证：

- grouped test 使用的 slot 集合
- checker 使用的 slot 集合
- checklist 文档中的关注族

三者一致。

**Step 4: 跑最终门禁**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check
```

Expected:

- wiring sync 绿
- truthfulness checker 双绿
- gate 双绿
- diff clean

**Step 5: Commit**

```bash
git add tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/check_nonx86_wiring_sync.py \
  tests/fafafa.core.simd/check_nonx86_register_truthfulness.py \
  docs/fafafa.core.simd.checklist.md
git commit -m "simd: group nonx86 implementation audits"
```

---

## Done Criteria

必须同时满足：

- `NEON` 和 `RISCVV` 的 register ownership 都能被 source/runtime/checker 三处同时证明。
- `NEON` 和 `RISCVV` 的真实 asm helper 接线不再依赖 wrapper 名字暗示，`*_ASM` 接线明确。
- `NEON` 和 `RISCVV` 的宽整数 / helper / compare / shift / bitwise / min-max / mul 语义能被 scalar parity 复验。
- `check_interface_implementation_completeness.py`、`check_nonx86_wiring_sync.py`、新 truthfulness checker 三者不冲突。
- 以下命令全部 fresh 通过：

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict --strict-level p2 --json
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
```

## Not In Scope

- 不做 public API 设计讨论
- 不做大规模 backend 架构重构
- 不做性能 benchmark 优化轮
- 不把 experimental backend 提升为默认 stable surface

