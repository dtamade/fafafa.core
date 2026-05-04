# SIMD Implementation Phase 2 Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 `simd` 模块已完成接口/ownership/Task 4 helper 收口的基础上，把剩余“实现层语义正确性”一次性做完，并补齐 native non-x86 运行证据、checker 和最终 closeout。

**Architecture:** 本阶段只审实现，不再回到 public API 或 ownership 讨论。先把 `Task 4` 在 native non-x86 环境上补齐运行证据，然后按语义族分批推进 `compare/mask`、`shift/bitwise`、`minmax/arithmetic/mul`，每批都坚持 `red -> minimal fix -> targeted green -> gate green`。最后把 checker、grouped 测试 helper 和 checklist 收口成低维护成本结构。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, Python3 source/runtime checker, `ripgrep`, existing `BuildOrTest.sh` / `buildOrTest.bat` gate flow, QEMU multi-arch runtime evidence, optional native AArch64/RISCV host.

---

## Status Snapshot (2026-04-13 / x86_64 host)

- 当前 `x86_64` 主机上，`Task 1` 到 `Task 5` 的 host-local 收口已完成：
  - grouped wiring helper 已收敛到 `AssertNonX86DispatchTableWiringGroupsAssigned`
  - `check_nonx86_helper_semantics.py` 已扩到 helper/native-evidence、compare/mask、shift/bitwise、arithmetic/minmax
  - `check_nonx86_wiring_sync.py` 已要求 legacy/grouped 两个入口都委托共享 helper
  - `verify_nonx86_native_evidence.py` + `BuildOrTest.sh verify-nonx86-native-evidence` 已落地，可在 `x86_64` 上对归档 native evidence 做 fail-close 校验
  - `check_riscvv_abi_shape.py` 已收进 `BuildOrTest.sh check`，宽向量 direct-return asm 的 hidden-result-pointer ABI 已 source-side 封边
  - `BuildOrTest.sh impl-audit-nonx86` / `buildOrTest.bat impl-audit-nonx86` 已落地，当前 implementation-side 审计有正式聚合入口
  - `Task 2 / shift-bitwise` 已补上更硬的 boundary semantics probe：`I32x8 / I32x16 / I64x4` 的 `c=-1 / 31 / 32 / 63 / 64 / 95` 关键点现在不再只做 backend-vs-scalar parity，还会对当前 contract 的精确 lane 结果做 source-side 断言
  - `BuildOrTest.sh closeout-host-local` / `buildOrTest.bat closeout-host-local` 已落地，host-local strict closeout 不再依赖手写命令串
  - `BuildOrTest.sh import-nonx86-native-evidence` / `closeout-host-local-from-import` 已落地，external native evidence 回灌与本机 strict closeout 有正式一键入口
  - `collect_nonx86_native_evidence.sh` 现在会落 `impl_audit_nonx86.log`，不再只记录裸 `check`
  - `DispatchAPI / DirectDispatch / DataPlane` 的 release targeted suite 已 fresh 通过
  - `compare / mask` 已补入 one-hot lane-order 矩阵（signed/unsigned wide families），fresh `DispatchAPI` targeted suite 与 `qemu-nonx86-evidence` 仍通过，当前未打出新的实现语义红点
  - full `gate` 已 fresh 通过
- 当前 `Task 0` 的 closeout 口径已经切到 QEMU-sufficient：
  - `qemu-nonx86-evidence` 已在 `linux/arm64` / `linux/riscv64` fresh 通过；runner 现在固定使用隔离输出根 + 单次 build 复用 binary 跑 `TTestCase_NonX86IEEE754` / `TTestCase_NonX86BackendParity` / backend bench，已规避旧链路里 `arm64` 重复 full rebuild 触发的 `ppca64` `FIRSTCALLPARAN` ICE
  - 没有真实硬件时，`qemu-nonx86-evidence` 就作为当前 arm64/riscv64 runtime closeout 的充分证明
  - `x86_64` 上的 `--list-suites` / compile-only 结果不能当成 runtime 证据
- 因此本计划当前应按下面口径理解：
  - **host-local implementation audit:** `impl-audit-nonx86` 已 complete
  - **host-local strict closeout:** `closeout-host-local` 已 complete；当前默认以 QEMU non-x86 runtime evidence 作为充分证明
  - **external native evidence import:** `import-nonx86-native-evidence` / `closeout-host-local-from-import` 仍可用，但已从必需项降为可选附加证据
  - **qemu non-x86 runtime evidence:** complete
  - **fresh native host runtime evidence:** optional extra, not a blocker

## Documentation Handoff Note (2026-04-14)

这份 plan 现在还要承担一个职责：给 docs/evidence 回填留稳定落点。

- `Task 2 / shift-bitwise`：
  - 文档层只在 fresh evidence 已落盘时写成“已收口”。
  - 最小 evidence 组合固定为：
    - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
    - `SIMD_QEMU_BUILD_POLICY=if-missing SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-evidence`
    - `SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local`
- `Task 3 / arithmetic-minmax-mul`：
  - 2026-04-14 fresh 已落盘：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
    - `SIMD_QEMU_BUILD_POLICY=if-missing SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-evidence`
    - `SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local`
  - 文档现在可以写成 closeout fact，但仍只允许引用已落盘 summary 路径和命令结果。
- 因此 docs write-set 当前推荐口径是：
  - `Task 2`: ready to write as closeout fact once fresh evidence is copied in
  - `Task 3`: ready to write as closeout fact

## Baseline Snapshot

- 已完成：
  - `Task 1` `NEON` register truthfulness
  - `Task 2` truthfulness checker 接入
  - `Task 3` `RISCVV` register truthfulness
  - `Task 4` helper correctness 收口
- 当前新增证据：
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
  - `src/fafafa.core.simd.riscvv.pas`
  - `tests/fafafa.core.simd/logs/qemu-multiarch-20260414-022837-725894/summary.md`
  - `tests/fafafa.core.simd/logs/qemu-multiarch-20260414-024142-773008/summary.md`
- 当前限制：
  - 主机仍是 `x86_64`；`NEON/RISCVV` 的 runtime closeout 当前依赖 QEMU `linux/arm64 + linux/riscv64` 证据，而不是原生硬件。

## Scope And Constraints

- 不改 `fafafa.core.simd` public API / public ABI。
- 只改实现层、测试层、checker、文档。
- 默认验证命令统一使用 release 路径：
  - `FAFAFA_BUILD_MODE=Release`
  - 非 x86 opt-in 用：
    - `SIMD_ENABLE_NEON_BACKEND=1`
    - `SIMD_ENABLE_RISCVV_BACKEND=1`
- `check` / `gate` 必须串行执行。
- `git diff --check` 必须作为每个批次末尾验证。
- 每个 family 独立提交，禁止多语义类混改。

## Phase Order

1. Task 0: native non-x86 运行证据补齐
2. Task 1: `compare / mask` 语义主审
3. Task 2: `shift / bitwise` 语义主审
4. Task 3: `min / max / add / sub / mul` 语义主审
5. Task 4: checker 与 grouped helper 收尾
6. Task 5: 最终 closeout / freeze-ready evidence

---

### Task 0: 补齐 native non-x86 运行时证据

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Log/Evidence: `tests/fafafa.core.simd/logs/`

**Step 1: 固化 Task 4 runtime 验证命令**

Run:

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity

SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity
```

Expected:

- QEMU 或 native host 环境下真实执行
- 新增 `Task 4` case 被跑到，不只是 `--list-suites`

**Step 2: 对现有 x86_64 主机保留 source checker 兜底**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
```

Expected:

- `NONX86_HELPER_SEMANTICS_SUMMARY ... status=ok`

**Step 3: 把 native 运行命令加入 checklist**

要求在 `docs/fafafa.core.simd.checklist.md` 中写清：

- `x86_64` 主机只能跑 source checker
- 没有真实硬件时，`qemu-nonx86-evidence` 就是当前 `AArch64/RISCV` runtime parity 的充分证明

**Step 4: Commit**

```bash
git add tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/check_nonx86_helper_semantics.py \
  docs/fafafa.core.simd.checklist.md
git commit -m "simd: wire native nonx86 helper evidence"
```

---

### Task 1: Compare / Mask 语义主审

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Modify: `src/fafafa.core.simd.neon.compare.inc`
- Modify: `src/fafafa.core.simd.riscvv.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Target Families:**

```text
I32x8 / U32x8
I64x4 / U64x4
I32x16
I64x8
Eq / Ne / Lt / Gt / Le / Ge
Mask lane order / popcount / all / any / first-set
```

**Step 1: 先写 failing test matrix**

覆盖：

- `0`
- `-1`
- `High(Int32/Int64)`
- `Low(Int32/Int64)`
- 交替位模式：`$AAAAAAAA / $55555555`
- 全相等 / 单 lane 不等 / 高半区不等 / 低半区不等

**Step 2: 跑 red**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

Expected:

- 如果 compare/mask 有 lane 顺序、符号或 mask bit 排布错误，这里先红

**Step 3: 最小修复实现**

规则：

- 一次只修一个 family
- 不顺手改 shift / arithmetic / minmax
- 优先修 raw asm 或最外层 wrapper，不做 backend 大重构

**Step 4: 跑 targeted green**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

Expected:

- `BUILD OK`
- `TEST OK`
- `LEAK OK`

**Step 5: 跑 gate**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check -- src/fafafa.core.simd.neon.pas src/fafafa.core.simd.neon.compare.inc src/fafafa.core.simd.riscvv.pas tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
```

**Step 6: Commit**

```bash
git add src/fafafa.core.simd.neon.pas \
  src/fafafa.core.simd.neon.compare.inc \
  src/fafafa.core.simd.riscvv.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
git commit -m "simd: validate nonx86 compare mask semantics"
```

---

### Task 2: Shift / Bitwise 语义主审

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Modify: `src/fafafa.core.simd.riscvv.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Target Families:**

```text
Shl / Shr / Sar
And / Or / Xor / Not / AndNot
I32x8 / I64x4 / I32x16 / I64x8
```

**Step 1: 先写 failing shift-count matrix**

覆盖：

- `-1`
- `0`
- `1`
- `7`
- `31`
- `32`
- `63`
- `64`
- 大于位宽的任意值

**Step 2: 再写 bitwise edge matrix**

覆盖：

- 全 0
- 全 1
- 交替位
- 单 lane 高位为 1
- 负数的算术右移

**Step 3: 跑 red**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

**Step 4: family-by-family 最小修复**

顺序建议：

1. `I32x8`
2. `I64x4`
3. `I32x16`
4. `I64x8`

**Step 5: 跑 green**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check -- src/fafafa.core.simd.neon.pas src/fafafa.core.simd.riscvv.pas tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
```

**Step 6: Commit**

```bash
git add src/fafafa.core.simd.neon.pas \
  src/fafafa.core.simd.riscvv.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
git commit -m "simd: validate nonx86 shift bitwise semantics"
```

---

### Task 3: Min / Max / Arithmetic / Mul 语义主审

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Modify: `src/fafafa.core.simd.riscvv.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Target Families:**

```text
Add / Sub / Mul
signed min/max
unsigned min/max
I32x8 / U32x8 / I64x4 / U64x4 / I32x16 / U32x16 / I64x8 / U64x8
```

**Step 1: 先写 failing arithmetic matrix**

覆盖：

- 溢出边缘值
- 正负混合
- 高半区 / 低半区不对称
- `mul` 的符号位和高位截断行为

**Step 2: 跑 red**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
```

**Step 3: 分 family 最小修复**

建议顺序：

1. `I32x8 / U32x8`
2. `I64x4 / U64x4`
3. `I32x16 / U32x16`
4. `I64x8 / U64x8`

**Step 4: 跑 green**

Run:

```bash
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check -- src/fafafa.core.simd.neon.pas src/fafafa.core.simd.riscvv.pas tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
```

**Step 5: Commit**

```bash
git add src/fafafa.core.simd.neon.pas \
  src/fafafa.core.simd.riscvv.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas
git commit -m "simd: validate nonx86 integer arithmetic semantics"
```

---

### Task 4: Checker / grouped helper / checklist 收尾

**Files:**
- Modify: `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
- Modify: `tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
- Modify: `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Modify: `docs/fafafa.core.simd.checklist.md`

**Step 1: 扩 checker**

新增两类检查：

- `compare-mask semantics checker`
- `shift/minmax/mul semantics checker`

目标：

- 在 `x86_64` 主机上也能提前拦截明显语义问题

**Step 2: 抽 grouped slot list / assert helper**

要求：

- slot 名单只维护一处
- direct / parity / checker 的 family 名单一致
- 新增一个 family 只改一处

**Step 3: 跑结构回归**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check
```

**Step 4: Commit**

```bash
git add tests/fafafa.core.simd/check_nonx86_helper_semantics.py \
  tests/fafafa.core.simd/check_nonx86_wiring_sync.py \
  tests/fafafa.core.simd/check_nonx86_register_truthfulness.py \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas \
  docs/fafafa.core.simd.checklist.md
git commit -m "simd: consolidate nonx86 implementation audits"
```

---

### Task 5: 最终 closeout / freeze-ready evidence

**Files:**
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Log/Evidence: `tests/fafafa.core.simd/logs/`

**Step 1: 汇总 fresh evidence**

必须至少包含：

- helper semantics checker
- truthfulness checker
- wiring sync
- targeted parity suite
- full gate
- native non-x86 runtime evidence（如环境可用）

**Step 2: 把“当前已证实 / 尚待 native 证实”写清楚**

必须明确区分：

- `source/runtime checker` 证据
- `native execution` 证据

**Step 3: 跑最终命令**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_NonX86BackendParity
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check
```

**Step 4: Commit**

```bash
git add docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.checklist.md \
  tests/fafafa.core.simd/logs
git commit -m "simd: finalize implementation closeout evidence"
```

---

## Done Criteria

必须同时满足：

- `Task 4` 的 helper correctness 在 source checker 和 native non-x86 runtime 两侧都有证据。
- `compare / mask / shift / bitwise / minmax / arithmetic / mul` 都有 scalar parity 复验。
- `DispatchAPI / DirectDispatch / DataPlane` 三层对同一 family 的断言不互相矛盾。
- `check_nonx86_helper_semantics.py`、`check_nonx86_wiring_sync.py`、`check_nonx86_register_truthfulness.py` 三者不冲突。
- 以下命令全部 fresh 通过：

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
git diff --check
```

### Current Interpretation On This Host

- 在当前 `x86_64` worktree 上，如果上面的 checker / targeted suite / full gate fresh 通过，可以认定 **实现层审计已完成**。
- 如果要宣称 **cross-arch native runtime evidence 已完成**，则必须另补：

```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity
```

- 上面两条必须在原生 `arm64` / `riscv64` 主机上 fresh 执行；否则只能宣称 host-local closeout，不应宣称 native non-x86 runtime closeout。

## Not In Scope

- 不回到 public API 设计讨论
- 不做 backend 大重构
- 不做性能 benchmark 优化轮
- 不把 experimental backend 提升为默认 stable surface
