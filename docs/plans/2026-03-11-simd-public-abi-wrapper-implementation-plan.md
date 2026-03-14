# SIMD Public ABI Wrapper Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 `fafafa.core.simd` 单元内实现 public ABI wrapper 的第一阶段落地：提供 POD metadata、ABI signature、backend query，以及“绑定后直调”的 public function table，不把当前 `TSimdDispatchTable` 直接公开为 public binary ABI。

**Architecture:** 公开入口仍然放在 `src/fafafa.core.simd.pas`，通过新的 public-ABI include 挂入类型与 getter。内部仍复用现有 `dispatch/cpuinfo` 与 façade 函数，但 public 数据面不做“每次 wrapper 再查 `TSimdDispatchTable`”；而是通过 dispatch-changed hook 维护一份已绑定的 POD-only public API table。`TSimdDispatchTable` 继续只做仓库内 dispatch contract。

**Tech Stack:** FreePascal/Lazarus, existing SIMD dispatch system, FPCUnit, bash BuildOrTest runners, machine-readable signature guard.

---

### Task 1: 定义 public ABI POD 类型与 getter 入口

**Files:**
- Modify: `src/fafafa.core.simd.pas`
- Create: `src/fafafa.core.simd.public_abi.intf.inc`
- Create: `src/fafafa.core.simd.public_abi.impl.inc`
- Modify: `src/fafafa.core.simd.STABLE`
- Modify: `docs/fafafa.core.simd.api.md`

**Step 1: 在公开接口层声明 POD-only ABI 类型**

新增到 `src/fafafa.core.simd.public_abi.intf.inc`：

```pascal
type
  TFafafaSimdAbiFlags = type UInt32;

const
  FAF_SIMD_ABI_FLAG_SUPPORTED_ON_CPU = UInt32(1) shl 0;
  FAF_SIMD_ABI_FLAG_REGISTERED       = UInt32(1) shl 1;
  FAF_SIMD_ABI_FLAG_DISPATCHABLE     = UInt32(1) shl 2;
  FAF_SIMD_ABI_FLAG_ACTIVE           = UInt32(1) shl 3;
  FAF_SIMD_ABI_FLAG_EXPERIMENTAL     = UInt32(1) shl 4;

type
  TFafafaSimdBackendPodInfo = packed record
    StructSize: UInt32;
    BackendId: UInt32;
    CapabilityBits: UInt64;
    Flags: TFafafaSimdAbiFlags;
    Priority: Int32;
  end;

  TFafafaSimdMemEqualFunc = function(aA, aB: Pointer; aLen: SizeUInt): LongBool;
  TFafafaSimdMemFindByteFunc = function(aP: Pointer; aLen: SizeUInt; aValue: Byte): PtrInt;
  TFafafaSimdSumBytesFunc = function(aP: Pointer; aLen: SizeUInt): UInt64;
  TFafafaSimdCountByteFunc = function(aP: Pointer; aLen: SizeUInt; aValue: Byte): SizeUInt;
  TFafafaSimdBitsetPopCountFunc = function(aP: Pointer; aByteLen: SizeUInt): SizeUInt;
  TFafafaSimdUtf8ValidateFunc = function(aP: Pointer; aLen: SizeUInt): LongBool;
  TFafafaSimdAsciiIEqualFunc = function(aA, aB: Pointer; aLen: SizeUInt): LongBool;

  TFafafaSimdPublicApi = packed record
    StructSize: UInt32;
    AbiVersionMajor: UInt16;
    AbiVersionMinor: UInt16;
    AbiSignatureHi: UInt64;
    AbiSignatureLo: UInt64;
    ActiveBackendId: UInt32;
    Reserved0: UInt32;
    MemEqual: TFafafaSimdMemEqualFunc;
    MemFindByte: TFafafaSimdMemFindByteFunc;
    SumBytes: TFafafaSimdSumBytesFunc;
    CountByte: TFafafaSimdCountByteFunc;
    BitsetPopCount: TFafafaSimdBitsetPopCountFunc;
    Utf8Validate: TFafafaSimdUtf8ValidateFunc;
    AsciiIEqual: TFafafaSimdAsciiIEqualFunc;
  end;

function GetSimdAbiVersionMajor: UInt16;
function GetSimdAbiVersionMinor: UInt16;
procedure GetSimdAbiSignature(out aHi, aLo: UInt64);
function TryGetSimdBackendPodInfo(aBackend: TSimdBackend; out aInfo: TFafafaSimdBackendPodInfo): Boolean;
function GetSimdBackendNamePtr(aBackend: TSimdBackend): PAnsiChar;
function GetSimdBackendDescriptionPtr(aBackend: TSimdBackend): PAnsiChar;
function GetSimdPublicApi: PFafafaSimdPublicApi;
```

**Step 2: 在 `src/fafafa.core.simd.pas` 接入新 include**

在 `{$I fafafa.core.simd.framework.intf.inc}` 前后选择合适位置接入：

```pascal
{$I fafafa.core.simd.public_abi.intf.inc}
...
{$I fafafa.core.simd.public_abi.impl.inc}
```

原则：
- 对外只新增，不重命名现有 API
- 不改 `TSimdDispatchTable`
- 不引入 managed string 到 public ABI POD struct

**Step 3: 文档写死边界**

更新：
- `src/fafafa.core.simd.STABLE`
- `docs/fafafa.core.simd.api.md`

明确：
- public ABI wrapper 的公开入口在 `fafafa.core.simd`
- 公开的是新的 POD-only `TFafafaSimdPublicApi`
- 当前 `TSimdDispatchTable` 仍然只是 in-repo dispatch contract

**Step 4: 构建验证**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:
- PASS
- 无新增 stable-path warning/hint

### Task 2: 实现“绑定后直调”的 public API table

**Files:**
- Modify: `src/fafafa.core.simd.pas`
- Modify: `src/fafafa.core.simd.public_abi.impl.inc`

**Step 1: 定义 ABI 常量与 capability bit 映射**

在 `public_abi.impl.inc` 中实现：

```pascal
const
  FAFAFA_SIMD_ABI_VERSION_MAJOR = 1;
  FAFAFA_SIMD_ABI_VERSION_MINOR = 0;
  FAFAFA_SIMD_ABI_SIGNATURE_HI = <const>;
  FAFAFA_SIMD_ABI_SIGNATURE_LO = <const>;
```

并新增最小 helper：

```pascal
function SimdCapabilitiesToAbiBits(const aCaps: TSimdCapabilities): UInt64;
function SimdBackendToAbiFlags(aBackend: TSimdBackend): TFafafaSimdAbiFlags;
```

要求：
- `supported_on_cpu / registered / dispatchable / active / experimental` 都映射进 `Flags`
- `CapabilityBits` 只做位图化，不暴露 Pascal `set` layout

**Step 2: 维护一份全局绑定后的 public API table**

在 `src/fafafa.core.simd.pas` 实现：

```pascal
var
  g_SimdPublicApi: TFafafaSimdPublicApi;

procedure RebindSimdPublicApi;
```

要求：
- 从当前 façade 语义绑定，而不是每次通过 wrapper 再去 `GetDispatchTable`
- 绑定结果放到 `g_SimdPublicApi`
- `GetSimdPublicApi` 只返回 `@g_SimdPublicApi`

禁止实现：
- `GetSimdPublicApi` 内部每次重查 `GetDispatchTable`
- 每个 public API 函数再转一层 `TSimdDispatchTable`

**Step 3: 与现有 dispatch-changed hook 接线**

在 `initialization/finalization` 中挂接：

```pascal
AddDispatchChangedHook(@RebindSimdPublicApi);
RemoveDispatchChangedHook(@RebindSimdPublicApi);
```

要求：
- 与现有 `RebindSimdFacadeFastPaths` 并存
- 初始化时显式先 bind 一次

**Step 4: 实现 metadata query**

实现：

```pascal
function TryGetSimdBackendPodInfo(...): Boolean;
function GetSimdBackendNamePtr(...): PAnsiChar;
function GetSimdBackendDescriptionPtr(...): PAnsiChar;
```

要求：
- POD info 不带 string
- 名称/描述单独返回静态 `PAnsiChar`
- 先只支持进程内静态生命周期，不做分配/释放协议

**Step 5: 构建验证**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Expected:
- PASS

### Task 3: 添加 public ABI wrapper 测试

**Files:**
- Create: `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`

**Step 1: 写 POD 布局与元数据测试**

新增测试：

```pascal
procedure Test_PublicAbi_PodStructSizes_AreStable;
procedure Test_PublicAbi_BackendPodInfo_Flags_AreSelfConsistent;
procedure Test_PublicAbi_NameAndDescription_AreNonNil_ForRegisteredBackends;
```

重点断言：
- `StructSize = SizeOf(record)`
- `TryGetSimdBackendPodInfo(sbScalar, ...) = True`
- `Flags` 与现有四层视图一致

**Step 2: 写 function table 绑定测试**

新增测试：

```pascal
procedure Test_PublicAbi_GetSimdPublicApi_ReturnsBoundTable;
procedure Test_PublicAbi_Table_Refreshes_AfterBackendSwitch;
procedure Test_PublicAbi_Table_DoesNotExposeNilCoreFacadeFns;
```

断言：
- `GetSimdPublicApi <> nil`
- `MemEqual/SumBytes/Utf8Validate` 等函数指针非 nil
- `SetActiveBackend/ResetToAutomaticBackend` 后 `ActiveBackendId` 刷新

**Step 3: 写 façade 语义一致性测试**

新增测试：

```pascal
procedure Test_PublicAbi_MemEqual_Parity;
procedure Test_PublicAbi_MemFindByte_Parity;
procedure Test_PublicAbi_SumBytes_Parity;
procedure Test_PublicAbi_CountByte_Parity;
procedure Test_PublicAbi_BitsetPopCount_Parity;
procedure Test_PublicAbi_Utf8Validate_Parity;
procedure Test_PublicAbi_AsciiIEqual_Parity;
```

测试策略：
- 直接调用 `GetSimdPublicApi^.<Fn>`
- 与现有 façade 返回值逐项对比

**Step 4: 注册 suite**

在 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 增加：

```pascal
fafafa.core.simd.publicabi.testcase,
```

**Step 5: 定向验证**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --list-suites
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi
```

Expected:
- suite 可见
- PASS

### Task 4: 把 public ABI wrapper 纳入门禁与文档

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Modify: `docs/fafafa.core.simd.api.md`
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/fafafa.core.simd.handoff.md`
- Modify: `progress.md`

**Step 1: 日常 gate 继续沿用现有 contract guard**

说明：
- 不新增新的 machine signature checker
- 继续沿用现有 `contract-signature` 守住内部 contract
- public ABI wrapper 通过测试 suite 守语义

**Step 2: 文档补充 public ABI wrapper 规则**

明确：
- 入口仍在 `fafafa.core.simd`
- data-plane 是绑定后直调
- `GetSimdPublicApi` 返回新的 POD-only public function table
- `TSimdDispatchTable` 仍不是 public binary ABI

**Step 3: 更新 progress / handoff**

记录：
- 新增 public ABI POD wrapper
- 新增 public API table
- 当前仅覆盖高 ROI façade

### Task 5: 全量回归

**Files:**
- Verify only

**Step 1: 日常门禁**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:
- 全 PASS

**Step 2: closeout 口径**

Run:
```bash
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 \
SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
SIMD_GATE_EXPERIMENTAL_TESTS=0 \
SIMD_GATE_PERF_SMOKE=1 \
SIMD_PERF_VECTOR_ASM=auto \
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

Expected:
- PASS

**Step 3: 更新设计文档状态**

在：
- `docs/plans/2026-03-11-simd-public-abi-wrapper-signature-design.md`

补一行实现状态，例如：

```md
> **Status:** phase-a implemented
```

**Step 4: Commit**

建议提交信息：

```bash
git add src/fafafa.core.simd.pas \
        src/fafafa.core.simd.public_abi.intf.inc \
        src/fafafa.core.simd.public_abi.impl.inc \
        tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas \
        tests/fafafa.core.simd.publicabi/fafafa.core.simd.publicabi.lpr \
        tests/fafafa.core.simd.publicabi/publicabi_smoke.h \
        tests/fafafa.core.simd.publicabi/publicabi_smoke.c \
        tests/fafafa.core.simd.publicabi/BuildOrTest.sh \
        tests/fafafa.core.simd.publicabi/BuildOrTest.bat \
        tests/fafafa.core.simd/fafafa.core.simd.test.lpr \
        docs/fafafa.core.simd.api.md \
        docs/fafafa.core.simd.closeout.md \
        docs/fafafa.core.simd.handoff.md \
        progress.md
git commit -m "simd: add public abi wrapper surface"
```

## Current Implementation Status (2026-03-14)

- Task 1: done
- Task 2: done
- Task 3: done
- Task 4: done
  - 已补齐 public ABI wrapper 用法与稳定性文档页
  - `gate` / `gate-strict` 已默认包含 `publicabi-signature` 与 `publicabi-smoke`
- Task 5: done (verification)
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
  - `SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
  - `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_EXPERIMENTAL_TESTS=0 SIMD_GATE_PERF_SMOKE=1 SIMD_PERF_VECTOR_ASM=auto bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`：PASS
- Pending (optional closeout): Commit/push 后刷新 Windows B07 evidence（用于 `freeze-status` 的 `cross-ready=True`）
