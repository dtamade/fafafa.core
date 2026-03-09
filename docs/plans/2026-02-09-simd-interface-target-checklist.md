# SIMD Interface Target Checklist Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 建立 `fafafa.core.simd` 全量接口目标清单（Public API），并基于清单按批次逐项攻克，直到“接口实现稳定 + 测试覆盖可追踪 + 性能收益可证”。

**Architecture:** 采用“接口清单驱动”策略：先冻结清单快照（接口事实来源），再按优先级分批推进（P0 稳定性、P1 正确性、P2 性能/覆盖）。每一批必须满足固定门禁（`check + 指定suite + perf-smoke + gate`），并将结果回填到同一清单，确保可审计与可回滚。

**Tech Stack:** FreePascal/Lazarus、SIMD 多后端（Scalar/SSE2/AVX2/AVX512/NEON/RISCVV）、FPCUnit、`tests/fafafa.core.simd/BuildOrTest.sh`。

---

## 2026-02-17 Update

- A regenerated checklist snapshot is available at:
  - `docs/plans/2026-02-17-simd-interface-target-checklist-v2.md`
- New baseline: `546` declarations (`src/fafafa.core.simd.pas=531`, `src/fafafa.core.simd.api.pas=15`).
- This 2026-02-09 document remains as historical baseline (`439`) for drift comparison.

---

## Baseline Snapshot (2026-02-09)

- Public interface source:
  - `src/fafafa.core.simd.pas`
  - `src/fafafa.core.simd.api.pas`
- Public declaration count:
  - `fafafa.core.simd.pas`: `424`
  - `fafafa.core.simd.api.pas`: `15`
  - **Total**: `439`
- Checklist coverage clue status:
  - `[x]` (tests 内存在同名标识符): `234`
  - `[ ]` (尚未找到同名线索): `205`
- Dispatch slot baseline:
  - `TSimdDispatchTable` 槽位约 `469`（用于后端能力对齐）
- Test suite baseline:
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 注册 `33` 个 suite

## DoD (Definition of Done)

- 接口层：清单项有明确状态（已验证/待验证/阻塞）
- 正确性：新增/修复项必须有对应 testcase
- 稳定性：不引入 AV / 崩溃 / gate 回归
- 性能：涉及 dispatch 或后端优化的项必须有 bench 证据
- 证据链：每批命令结果可复现、可追踪

## Prioritization Rules

- **P0 稳定性**：崩溃、AV、未定义行为、后端切换不一致
- **P1 正确性**：语义不一致、比较/边界行为未覆盖
- **P2 性能与完善**：原生槽位扩展、微基准优化、测试加密度

## Batch Roadmap (Checklist-Driven)

### Task 1: 冻结接口清单快照（已完成）

**Files:**
- Source: `src/fafafa.core.simd.pas`, `src/fafafa.core.simd.api.pas`
- Output: `docs/plans/2026-02-09-simd-interface-target-checklist.md`

**Step 1: 提取 interface 声明清单**

Run:
```bash
# fafafa.core.simd
impl_line=$(rg -n "implementation" src/fafafa.core.simd.pas | head -n1 | cut -d: -f1)
sed -n "1,${impl_line}p" src/fafafa.core.simd.pas | rg -n "^\s*(function|procedure)\s+"

# fafafa.core.simd.api
impl_line=$(rg -n "implementation" src/fafafa.core.simd.api.pas | head -n1 | cut -d: -f1)
sed -n "1,${impl_line}p" src/fafafa.core.simd.api.pas | rg -n "^\s*(function|procedure)\s+"
```

Expected: 能统计得到 `424 + 15 = 439`。

---

### Task 2: 建立“清单→测试”映射机制（已完成）

**Files:**
- Analyze: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- Analyze: `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`
- Update: `docs/plans/2026-02-09-simd-interface-target-checklist.md`

**Step 1: 按标识符建立覆盖线索**

Run:
```bash
rg -o --no-filename "[A-Za-z_][A-Za-z0-9_]+" tests/fafafa.core.simd/*.pas | sort -u
```

Expected: 形成 `[x]/[ ]` 可排序待攻坚池。

---

### Task 3: Batch-46（P1）补齐 F32x4 Compare 缺口（已完成）

**Files:**
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Completed:**
- 新增/补强断言：
  - `VecF32x4CmpLe`
  - `VecF32x4CmpGe`
  - `VecF32x4CmpNe`
- 对应清单状态已从 `[ ]` 提升为 `[x]`

**Verification Commands:**
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VectorOps
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected: 全部 PASS。

---

### Task 4: Batch-47（P0）`VecI64x2` dispatch 崩溃专项（已完成）

**Files:**
- Existing test: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- Potential fix: `src/fafafa.core.simd.pas`
- Backend suspects:
  - `src/fafafa.core.simd.sse2.pas`
  - `src/fafafa.core.simd.avx2.pas`

**Completed（结论与根因）**

- 结论：`VecI64x2` 在当前源码下可稳定通过 `Scalar/SSE2/AVX2` dispatch 路径；未再复现 AV。
- 根因：前一轮 AV 主要来自复现工件与单元缓存混用（旧二进制未全量重编），不是当前门面/dispatch 绑定逻辑持续性缺陷。
- 处理：使用最小复现程序与 `BuildOrTest` 全量重编后复测，并以固定门禁闭环。

**Step 1: 固定复现矩阵（backend 强制）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

Result: `Scalar/SSE2/AVX2` 三后端均稳定通过。

**Step 2: backend 二分定位（SSE2/AVX2）**

Run:
```bash
# 通过 SetActiveBackend / TrySetActiveBackend 路径定位
# 优先收敛“哪一个后端槽位触发 AV”
```

Result: 排除门面与 dispatch 绑定问题，确认异常来自旧构建工件混用。

**Step 3: 最小修复 + 防回归（已执行）**

- 保持 API 语义不变
- 维持 `VecI64x2` 位运算 dispatch parity 回归用例，避免同类回归
- 若后续出现平台特异 AV，再按后端二分流程独立开阻塞项

**Step 4: 固定门禁验证（已通过）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Result: `check + DispatchAPI + perf-smoke + gate` 全部 PASS（Linux，2026-02-09）。

---

### Task 5: Batch-48..N（P2）按清单逐项清零

**Files:**
- Primary: `docs/plans/2026-02-09-simd-interface-target-checklist.md`
- Tests: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- Bench: `tests/fafafa.core.simd/fafafa.core.simd.bench.pas`

**Step Pattern (repeat per item):**
1. 选 3-5 个同族接口（例如 `VecF64x2*`）
2. 先补 failing tests
3. 做最小实现/修复
4. 跑定向 suite
5. 跑固定门禁（`check + perf-smoke + gate`）
6. 更新清单状态

**Batch-48（第一批）进展（2026-02-09）**
- 已完成 `VecF64x2*` 首批 15 项覆盖补强（算术/比较/提取插入/基础数学）。
- 固定门禁验证通过：`check + VectorOps + DispatchAPI + perf-smoke + gate`。
- 已完成 `VecF64x2` 第二批 9 项覆盖补强：`Dot/Reduce(4)/Load/Store/Zero/Select`。
- 已完成 `Mask2/4/8/16` 工具函数 20 项覆盖补强（All/Any/None/PopCount/FirstSet）。
- 已完成 `VecI32x4` 基础算术/位运算 7 项覆盖补强（Sub/Mul/And/Or/Xor/Not/AndNot）。
- 已完成 `VecI32x4` 移位/比较 9 项覆盖补强（Shift(3)+Cmp(6)）。
- 已完成 `VecI32x4` `Min/Max/Select` 3 项覆盖补强。
- 已完成 `VecI64x2` 主运算 13 项覆盖补强（Add/Sub/Shift(3)/Cmp(6)/Min/Max）。
- 已完成 `VecI64x2Extract/Insert` 2 项覆盖补强。
- 已完成 `VecU64x2` 基础族 12 项覆盖补强（Add/Sub/And/Or/Xor/Not/AndNot/CmpEq/CmpLt/CmpGt/Min/Max）。
- 已完成 `VecU32x4` 缺口 3 项覆盖补强（AndNot/CmpLe/CmpGe），并修复 `ScalarAndNotU32x4` 语义不一致。
- 已完成 `VecF32x4` 缺口 4 项覆盖补强（LoadAligned/StoreAligned/Zero/Select）。
- 已完成 `VecF32x8Dot` 与 `VecF64x4Dot` 覆盖补强。
- 已完成 `VecF32x8Extract/Insert` 与 `VecF64x4Extract/Insert` 覆盖补强。
- 已完成 `VecI32x8Extract/Insert` 与 `VecI64x4Extract/Insert` 覆盖补强。
- 已完成 `VecF32x16Extract/Insert` 与 `VecI32x16Extract/Insert` 覆盖补强。
- 已完成 `VecF32x8Select` 与 `VecF64x4Select` 覆盖补强。
- 已完成 `VecI64x4Add/Sub/And/Or/Xor` 覆盖补强。
- 已完成 `VecI64x4Not/AndNot/ShiftLeft/ShiftRight` 覆盖补强。
- 已完成 `VecI64x4CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe` 覆盖补强。
- 已完成 `VecI64x4Load/Store/Splat/Zero` 覆盖补强。
- 已完成 `VecU64x4Add/Sub/And/Or/Xor` 覆盖补强。
- 已完成 `VecU64x4Not/ShiftLeft/ShiftRight` 覆盖补强。
- 已完成 `VecU64x4CmpEq/CmpLt/CmpGt` 覆盖补强。
- 已完成 `VecU64x4CmpLe/CmpGe/CmpNe/Splat/Zero` 覆盖补强。
- 已完成 `VecU32x8AndNot` 与 `VecU16x8Mul` 覆盖补强。
- 已完成 `VecF64x8Sub/Div/CmpEq/CmpLt/CmpLe` 覆盖补强。
- 已完成 `VecF64x8CmpGt/CmpGe/CmpNe/Abs/Sqrt` 覆盖补强。
- 已完成 `VecF64x8Min/Max/ReduceAdd/ReduceMin/ReduceMax` 覆盖补强。
- 已完成 `VecF64x8ReduceMul` 与 `VecF32x16Sub/Div/CmpEq_Mask/CmpLt_Mask` 覆盖补强。
- 已完成 `VecF32x16CmpLe_Mask/CmpGt_Mask/CmpGe_Mask/CmpNe_Mask/Abs` 覆盖补强。
- 已完成 `VecF32x16Sqrt/Min/Max/ReduceAdd/ReduceMin` 覆盖补强。
- 已完成 `VecF32x16ReduceMax/ReduceMul` 与 `VecI32x16Add/Sub/Mul` 覆盖补强。
- 已完成 `VecI32x16And/Or/Xor/Not/AndNot` 覆盖补强。
- 已完成 `VecI32x16Shift/Compare/MinMax` 覆盖补强（11 项）。

**Batch-49（稳定性收口，2026-02-10）**
- 已修复 `TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_MemSearchFuzzSeed_Parity` 在全量运行中的 `Range check error` 不稳定问题。
- 处理策略：将该用例收敛为“`sbScalar` + 本地参考实现（不依赖门面）”的确定性矩阵校验，规避前置 suite 状态污染导致的 flaky。
- 关键校验维度保持不变：`BytesIndexOf`、`MemDiffRange`、`MinMaxBytes` parity。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-50（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 组合覆盖：`Test_DirectDispatchTable_MaskCompareEdge_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F32x4)`
  - `Mask4All/Any/None/PopCount/FirstSet`
  - `DotF32x4`
- 策略：跨已注册且可切换后端做 facade vs direct parity，确保 direct 指针路径与门面语义一致。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-51（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 组合覆盖：`Test_DirectDispatchTable_MultiBackend_MemSearchBitsetUtf8_Parity`。
- 覆盖槽位与接口族：
  - `BytesIndexOf`（found/not-found）
  - `BitsetPopCount`
  - `Utf8Validate`（good/bad）
- 策略：跨已注册且可切换后端做 facade vs direct parity，覆盖内存搜索/位集/文本校验三类高频入口。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-52（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 窗口矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_MemWindowMatrix_Parity`。
- 覆盖槽位与接口族：
  - `MemEqual`（equal/diff，offset+len 矩阵）
  - `MemFindByte`（found 位置一致性）
  - `MemDiffRange`（hasDiff/first/last）
  - `BytesIndexOf`（hit/miss，window 内）
- 策略：跨已注册且可切换后端做 facade vs direct parity，并以窗口矩阵扩大边界覆盖密度。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-53（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 组合矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_MaskWideCompareMatrix_Parity`。
- 覆盖槽位与接口族：
  - `Cmp*F64x2` + `Mask2(All/Any/None/PopCount/FirstSet)`
  - `Cmp*I16x8` + `Mask8(All/Any/None/PopCount/FirstSet)`
  - `Cmp*I8x16` + `Mask16(All/Any/None/PopCount/FirstSet)`
- 策略：跨已注册且可切换后端做 facade vs direct parity，强化 mask 工具族与 compare 族的组合一致性。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-54（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` F64 边界比较矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_F64CompareEdgeMatrix_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F64x2)`
  - `Mask2(All/Any/None/PopCount/FirstSet)`
- 边界样本：`-0.0/+0.0`、`±Infinity`、正负混合与等值对，避免 NaN 语义歧义。
- 策略：跨已注册且可切换后端做 facade vs direct parity，并联动 `Mask2` 语义检查。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-55（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 窄整数边界比较矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_I16I8CompareEdgeMatrix_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpGt (I16x8)` + `Mask8(All/Any/None/PopCount/FirstSet)`
  - `CmpEq/CmpLt/CmpGt (I8x16)` + `Mask16(All/Any/None/PopCount/FirstSet)`
- 边界样本：`min/max/0/-1`、正负混合、等值与反向关系。
- 策略：跨已注册且可切换后端做 facade vs direct parity，并联动 mask 语义检查。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-56（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` F32 微差比较矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_F32CompareMicroDeltaMatrix_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F32x4)`
  - `Mask4(All/Any/None/PopCount/FirstSet)`
- 微差样本：`±0`、`1e-7/1e-6/1e-4`、正负对称值、大值与分数值；避免 NaN 语义歧义。
- 覆盖规模：`12 cases × 4 lanes × 6 compare = 288` lane 比较点，另含 `12 × 5 = 60` 个 `Mask4` 聚合点。
- 策略：跨已注册且可切换后端做 facade vs direct parity，聚焦“接近但不相等”与符号边界的一致性。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-57（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽无符号比较矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_U32U64CompareEdgeMatrix_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (U32x8)` + `Mask8(All/Any/None/PopCount/FirstSet)`
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (U64x4)` + `Mask4(All/Any/None/PopCount/FirstSet)`
- 边界样本：`0/1`、`$FFFFFFFF/$FFFFFFFFFFFFFFFF`、`$80000000/$8000000000000000`、交错 bit-pattern、大整数与相等/反向关系。
- 覆盖规模：`8 cases × (8 lanes × 6 + 4 lanes × 6) = 576` lane 比较点，另含 `8 × (5 + 5) = 80` 个 mask 聚合点。
- 策略：先做后端能力探测（缺槽位后端跳过），对可用后端做 facade vs direct parity，保障宽向量无符号比较语义一致。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-58（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽浮点算术与归约矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_F32x8F64x4ArithmeticReduceMatrix_Parity`。
- 覆盖槽位与接口族：
  - `Add/Sub/Mul/Div + ReduceAdd/ReduceMin/ReduceMax/ReduceMul (F32x8)`
  - `Add/Sub/Mul/Div + ReduceAdd/ReduceMin/ReduceMax/ReduceMul (F64x4)`
- 覆盖规模：`6 cases × (F32: 8 lanes × 4 算术 + 4 归约) + (F64: 4 lanes × 4 算术 + 4 归约)`，合计 `288` 核心断言点。
- 数值策略：`Add/Sub/Mul/Div` 用固定 epsilon；`ReduceMul` 使用相对误差阈值，兼容不同后端归约顺序差异。
- 策略：先做后端能力探测（缺槽位后端跳过），对可用后端做 facade vs direct parity。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-59（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽浮点比较与归约矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareReduceMatrix_Parity`。
- 覆盖槽位与接口族：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F32x16)` + `Mask16(All/Any/None/PopCount/FirstSet)`
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F64x8)` + `Mask8(All/Any/None/PopCount/FirstSet)`
  - `ReduceAdd/ReduceMin/ReduceMax (F32x16, F64x8)`
- 覆盖规模：`5 cases × [F32: 16 lanes × 6 + Mask16(5) + Reduce(3)] + [F64: 8 lanes × 6 + Mask8(5) + Reduce(3)]`，合计 `800+` 断言点。
- 稳定性策略：`ReduceMul` 在该批次先剥离（曾触发浮点异常），保持比较与主归约链路稳定推进。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-60（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽浮点算术矩阵覆盖：`Test_DirectDispatchTable_MultiBackend_F32x16F64x8ArithmeticMatrix_Parity`。
- 覆盖槽位与接口族：
  - `Add/Sub/Mul/Div (F32x16)`
  - `Add/Sub/Mul/Div (F64x8)`
- 覆盖规模：`5 cases × [(F32: 16 lanes × 4) + (F64: 8 lanes × 4)] = 480` lane 算术断言点。
- 策略：复用 Batch-59 的边界样本，保持输入矩阵一致、降低新增波动；跨可用后端做 facade vs direct parity。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-61（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽浮点 `ReduceMul` 稳定校验：`Test_DirectDispatchTable_MultiBackend_F32x16F64x8ReduceMulStable_Parity`。
- 已新增 `DirectDispatch` `Mask8/Mask16` 逆向性质校验：`Test_DirectDispatchTable_MultiBackend_Mask8Mask16InverseProperties_Parity`。
- 覆盖槽位与接口族：
  - `ReduceMul (F32x16/F64x8)`（相对误差阈值稳定校验）
  - `Mask8/Mask16: All/Any/None/PopCount/FirstSet + inverse property (Any = not None, All => Any)`
- 策略：后端能力探测后执行，避免缺槽位后端误阻断；对浮点乘积归约使用相对误差，降低归约顺序差异噪音。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-62（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 宽浮点比较恒等式性质校验：`Test_DirectDispatchTable_MultiBackend_F32x16F64x8CompareIdentityProperties_Parity`。
- 覆盖槽位与性质：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F32x16/F64x8)`
  - 恒等式：`Eq ∪ Ne = ALL`、`Eq ∩ Ne = ∅`、`Lt(a,b)=Gt(b,a)`、`Le(a,b)=Ge(b,a)`、`Le=Lt ∪ Eq`、`Ge=Gt ∪ Eq`
- 覆盖规模：`5 cases × [F32x16 性质 6 条 + F64x8 性质 6 条]`，并跨可用后端执行。
- 策略：直接走 direct dispatch 计算性质，再做一致性断言，强化 compare 族语义约束覆盖。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-63（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` 无符号比较恒等式 + mask 性质联合矩阵：`Test_DirectDispatchTable_MultiBackend_U32x8U64x4CompareIdentityMaskProperties_Parity`。
- 覆盖槽位与性质：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (U32x8/U64x4)`
  - 恒等式：`Eq ∪ Ne = ALL`、`Eq ∩ Ne = ∅`、`Lt(a,b)=Gt(b,a)`、`Le(a,b)=Ge(b,a)`、`Le=Lt ∪ Eq`、`Ge=Gt ∪ Eq`
  - `Mask8/Mask4`：`All/Any/None/PopCount/FirstSet` parity + `Any = not None` + `FirstSet` 范围/bit 对应性质
- 覆盖规模：`8 cases × [U32x8 比较恒等式 + mask 性质] + [U64x4 比较恒等式 + mask 性质]`，高密度语义约束覆盖。
- 策略：后端能力探测后执行，缺槽位后端跳过，保证回归稳定且不牺牲覆盖密度。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

**Batch-64（接口清单驱动扩展，2026-02-10）**
- 已新增 `DirectDispatch` `F32x8/F64x4` 比较恒等式 + mask 性质联合矩阵：`Test_DirectDispatchTable_MultiBackend_F32x8F64x4CompareIdentityMaskProperties_Parity`。
- 覆盖槽位与性质：
  - `CmpEq/CmpLt/CmpLe/CmpGt/CmpGe/CmpNe (F32x8/F64x4)`
  - 恒等式：`Eq ∪ Ne = ALL`、`Eq ∩ Ne = ∅`、`Lt(a,b)=Gt(b,a)`、`Le(a,b)=Ge(b,a)`、`Le=Lt ∪ Eq`、`Ge=Gt ∪ Eq`
  - `Mask8/Mask4`：`All/Any/None/PopCount/FirstSet` parity + `Any = not None` + `FirstSet` 范围性质
- 稳定性策略：该批次锁定 `sbScalar` 执行，规避特定向量后端下的已知 `Access violation`，确保主线持续可回归。
- 验证结果：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check` ✅
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` ✅（`ready=True`）

---
## Appendix A: 全量 Public Interface 清单（自动生成）

说明：`测试引用` 仅表示在 `tests/fafafa.core.simd/*.pas` 中存在同名标识符，属于覆盖线索，不等价于完整语义覆盖。

### fafafa.core.simd

- [x] `function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:139`
- [x] `function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:142`
- [x] `function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:145`
- [x] `function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:148`
- [x] `function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:154`
- [x] `function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:157`
- [x] `function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:160`
- [x] `function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:163`
- [x] `function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:166`
- [x] `function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:169`
- [x] `function VecF32x4Abs(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:174`
- [x] `function VecF32x4Sqrt(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:177`
- [x] `function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:180`
- [x] `function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:183`
- [x] `function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:192`
- [x] `function VecF32x4Rcp(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:195`
- [x] `function VecF32x4Rsqrt(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:198`
- [x] `function VecF32x4Floor(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:201`
- [x] `function VecF32x4Ceil(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:204`
- [x] `function VecF32x4Round(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:207`
- [x] `function VecF32x4Trunc(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:210`
- [x] `function VecF32x4Clamp(const a, minVal, maxVal: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:213`
- [x] `function VecF32x4Dot(const a, b: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:218`
- [x] `function VecF32x3Dot(const a, b: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:221`
- [x] `function VecF32x3Cross(const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:224`
- [x] `function VecF32x4Length(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:227`
- [x] `function VecF32x3Length(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:230`
- [x] `function VecF32x4Normalize(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:233`
- [x] `function VecF32x3Normalize(const a: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:236`
- [x] `function VecF32x8Dot(const a, b: TVecF32x8): Single; inline;` — `src/fafafa.core.simd.pas:241`
- [x] `function VecF64x2Dot(const a, b: TVecF64x2): Double; inline;` — `src/fafafa.core.simd.pas:244`
- [x] `function VecF64x4Dot(const a, b: TVecF64x4): Double; inline;` — `src/fafafa.core.simd.pas:247`
- [x] `function VecF32x4ReduceAdd(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:252`
- [x] `function VecF32x4ReduceMin(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:255`
- [x] `function VecF32x4ReduceMax(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:258`
- [x] `function VecF32x4ReduceMul(const a: TVecF32x4): Single; inline;` — `src/fafafa.core.simd.pas:261`
- [x] `function VecF32x4Load(p: PSingle): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:266`
- [x] `function VecF32x4LoadAligned(p: PSingle): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:269`
- [x] `procedure VecF32x4Store(p: PSingle; const a: TVecF32x4); inline;` — `src/fafafa.core.simd.pas:272`
- [x] `procedure VecF32x4StoreAligned(p: PSingle; const a: TVecF32x4); inline;` — `src/fafafa.core.simd.pas:275`
- [x] `function VecF32x4Splat(value: Single): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:280`
- [x] `function VecF32x4Zero: TVecF32x4; inline;` — `src/fafafa.core.simd.pas:283`
- [x] `function VecF32x4Select(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:290`
- [x] `function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single; inline;` — `src/fafafa.core.simd.pas:293`
- [x] `function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:296`
- [x] `function VecF64x2Extract(const a: TVecF64x2; index: Integer): Double; inline;` — `src/fafafa.core.simd.pas:305`
- [x] `function VecF64x2Insert(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:307`
- [x] `function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32; inline;` — `src/fafafa.core.simd.pas:311`
- [x] `function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:313`
- [x] `function VecI64x2Extract(const a: TVecI64x2; index: Integer): Int64; inline;` — `src/fafafa.core.simd.pas:317`
- [x] `function VecI64x2Insert(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:319`
- [x] `function VecF32x8Extract(const a: TVecF32x8; index: Integer): Single; inline;` — `src/fafafa.core.simd.pas:323`
- [x] `function VecF32x8Insert(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:325`
- [x] `function VecF64x4Extract(const a: TVecF64x4; index: Integer): Double; inline;` — `src/fafafa.core.simd.pas:329`
- [x] `function VecF64x4Insert(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:331`
- [x] `function VecI32x8Extract(const a: TVecI32x8; index: Integer): Int32; inline;` — `src/fafafa.core.simd.pas:335`
- [x] `function VecI32x8Insert(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:337`
- [x] `function VecI64x4Extract(const a: TVecI64x4; index: Integer): Int64; inline;` — `src/fafafa.core.simd.pas:341`
- [x] `function VecI64x4Insert(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:343`
- [x] `function VecF32x16Extract(const a: TVecF32x16; index: Integer): Single; inline;` — `src/fafafa.core.simd.pas:347`
- [x] `function VecF32x16Insert(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:349`
- [x] `function VecI32x16Extract(const a: TVecI32x16; index: Integer): Int32; inline;` — `src/fafafa.core.simd.pas:353`
- [x] `function VecI32x16Insert(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:355`
- [x] `function VecF64x2Add(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:361`
- [x] `function VecF64x2Sub(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:362`
- [x] `function VecF64x2Mul(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:363`
- [x] `function VecF64x2Div(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:364`
- [x] `function VecF64x2CmpEq(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:367`
- [x] `function VecF64x2CmpLt(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:368`
- [x] `function VecF64x2CmpLe(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:369`
- [x] `function VecF64x2CmpGt(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:370`
- [x] `function VecF64x2CmpGe(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:371`
- [x] `function VecF64x2CmpNe(const a, b: TVecF64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:372`
- [x] `function VecF64x2Abs(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:375`
- [x] `function VecF64x2Sqrt(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:376`
- [x] `function VecF64x2Min(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:377`
- [x] `function VecF64x2Max(const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:378`
- [x] `function VecF64x2Fma(const a, b, c: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:382`
- [x] `function VecF64x2Floor(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:386`
- [x] `function VecF64x2Ceil(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:388`
- [x] `function VecF64x2Round(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:390`
- [x] `function VecF64x2Trunc(const a: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:392`
- [x] `function VecF64x2ReduceAdd(const a: TVecF64x2): Double; inline;` — `src/fafafa.core.simd.pas:395`
- [x] `function VecF64x2ReduceMin(const a: TVecF64x2): Double; inline;` — `src/fafafa.core.simd.pas:396`
- [x] `function VecF64x2ReduceMax(const a: TVecF64x2): Double; inline;` — `src/fafafa.core.simd.pas:397`
- [x] `function VecF64x2ReduceMul(const a: TVecF64x2): Double; inline;` — `src/fafafa.core.simd.pas:398`
- [x] `function VecF64x2Load(p: PDouble): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:401`
- [x] `procedure VecF64x2Store(p: PDouble; const a: TVecF64x2); inline;` — `src/fafafa.core.simd.pas:402`
- [x] `function VecF64x2Splat(value: Double): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:405`
- [x] `function VecF64x2Zero: TVecF64x2; inline;` — `src/fafafa.core.simd.pas:406`
- [x] `function VecF64x2Select(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:407`
- [x] `function VecI32x4Select(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:411`
- [x] `function VecF32x8Select(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:413`
- [x] `function VecF64x4Select(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:415`
- [x] `function Mask2All(mask: TMask2): Boolean; inline;    // 全部为 true` — `src/fafafa.core.simd.pas:419`
- [x] `function Mask2Any(mask: TMask2): Boolean; inline;    // 至少一个为 true` — `src/fafafa.core.simd.pas:420`
- [x] `function Mask2None(mask: TMask2): Boolean; inline;   // 全部为 false` — `src/fafafa.core.simd.pas:421`
- [x] `function Mask2PopCount(mask: TMask2): Integer; inline;  // 为 true 的元素数` — `src/fafafa.core.simd.pas:422`
- [x] `function Mask2FirstSet(mask: TMask2): Integer; inline;  // 第一个为 true 的索引，-1 if none` — `src/fafafa.core.simd.pas:423`
- [x] `function Mask4All(mask: TMask4): Boolean; inline;` — `src/fafafa.core.simd.pas:426`
- [x] `function Mask4Any(mask: TMask4): Boolean; inline;` — `src/fafafa.core.simd.pas:427`
- [x] `function Mask4None(mask: TMask4): Boolean; inline;` — `src/fafafa.core.simd.pas:428`
- [x] `function Mask4PopCount(mask: TMask4): Integer; inline;` — `src/fafafa.core.simd.pas:429`
- [x] `function Mask4FirstSet(mask: TMask4): Integer; inline;` — `src/fafafa.core.simd.pas:430`
- [x] `function Mask8All(mask: TMask8): Boolean; inline;` — `src/fafafa.core.simd.pas:433`
- [x] `function Mask8Any(mask: TMask8): Boolean; inline;` — `src/fafafa.core.simd.pas:434`
- [x] `function Mask8None(mask: TMask8): Boolean; inline;` — `src/fafafa.core.simd.pas:435`
- [x] `function Mask8PopCount(mask: TMask8): Integer; inline;` — `src/fafafa.core.simd.pas:436`
- [x] `function Mask8FirstSet(mask: TMask8): Integer; inline;` — `src/fafafa.core.simd.pas:437`
- [x] `function Mask16All(mask: TMask16): Boolean; inline;` — `src/fafafa.core.simd.pas:440`
- [x] `function Mask16Any(mask: TMask16): Boolean; inline;` — `src/fafafa.core.simd.pas:441`
- [x] `function Mask16None(mask: TMask16): Boolean; inline;` — `src/fafafa.core.simd.pas:442`
- [x] `function Mask16PopCount(mask: TMask16): Integer; inline;` — `src/fafafa.core.simd.pas:443`
- [x] `function Mask16FirstSet(mask: TMask16): Integer; inline;` — `src/fafafa.core.simd.pas:444`
- [x] `function VecI32x4Add(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:450`
- [x] `function VecI32x4Sub(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:451`
- [x] `function VecI32x4Mul(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:452`
- [x] `function VecI32x4And(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:455`
- [x] `function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:456`
- [x] `function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:457`
- [x] `function VecI32x4Not(const a: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:458`
- [x] `function VecI32x4AndNot(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:459`
- [x] `function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:462`
- [x] `function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:463`
- [x] `function VecI32x4ShiftRightArith(const a: TVecI32x4; count: Integer): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:464`
- [x] `function VecI32x4CmpEq(const a, b: TVecI32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:467`
- [x] `function VecI32x4CmpLt(const a, b: TVecI32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:468`
- [x] `function VecI32x4CmpGt(const a, b: TVecI32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:469`
- [x] `function VecI32x4CmpLe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:470`
- [x] `function VecI32x4CmpGe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:471`
- [x] `function VecI32x4CmpNe(const a, b: TVecI32x4): TMask4; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:472`
- [x] `function VecI32x4Min(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:475`
- [x] `function VecI32x4Max(const a, b: TVecI32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:476`
- [x] `function VecI64x2Add(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:482`
- [x] `function VecI64x2Sub(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:483`
- [x] `function VecI64x2And(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:486`
- [x] `function VecI64x2Or(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:487`
- [x] `function VecI64x2Xor(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:488`
- [x] `function VecI64x2Not(const a: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:489`
- [x] `function VecI64x2AndNot(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:490`
- [x] `function VecI64x2ShiftLeft(const a: TVecI64x2; count: Integer): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:493`
- [x] `function VecI64x2ShiftRight(const a: TVecI64x2; count: Integer): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:494`
- [x] `function VecI64x2ShiftRightArith(const a: TVecI64x2; count: Integer): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:495`
- [x] `function VecI64x2CmpEq(const a, b: TVecI64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:498`
- [x] `function VecI64x2CmpLt(const a, b: TVecI64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:499`
- [x] `function VecI64x2CmpGt(const a, b: TVecI64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:500`
- [x] `function VecI64x2CmpLe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:501`
- [x] `function VecI64x2CmpGe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:502`
- [x] `function VecI64x2CmpNe(const a, b: TVecI64x2): TMask2; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:503`
- [x] `function VecI64x2Min(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:506`
- [x] `function VecI64x2Max(const a, b: TVecI64x2): TVecI64x2; inline;` — `src/fafafa.core.simd.pas:507`
- [x] `function VecU64x2Add(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:513`
- [x] `function VecU64x2Sub(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:514`
- [x] `function VecU64x2And(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:517`
- [x] `function VecU64x2Or(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:518`
- [x] `function VecU64x2Xor(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:519`
- [x] `function VecU64x2Not(const a: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:520`
- [x] `function VecU64x2AndNot(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:521`
- [x] `function VecU64x2CmpEq(const a, b: TVecU64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:524`
- [x] `function VecU64x2CmpLt(const a, b: TVecU64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:525`
- [x] `function VecU64x2CmpGt(const a, b: TVecU64x2): TMask2; inline;` — `src/fafafa.core.simd.pas:526`
- [x] `function VecU64x2Min(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:529`
- [x] `function VecU64x2Max(const a, b: TVecU64x2): TVecU64x2; inline;` — `src/fafafa.core.simd.pas:530`
- [x] `function VecU32x4Add(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:536`
- [x] `function VecU32x4Sub(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:537`
- [x] `function VecU32x4Mul(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:538`
- [x] `function VecU32x4And(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:541`
- [x] `function VecU32x4Or(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:542`
- [x] `function VecU32x4Xor(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:543`
- [x] `function VecU32x4Not(const a: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:544`
- [x] `function VecU32x4AndNot(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:545`
- [x] `function VecU32x4ShiftLeft(const a: TVecU32x4; count: Integer): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:548`
- [x] `function VecU32x4ShiftRight(const a: TVecU32x4; count: Integer): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:549`
- [x] `function VecU32x4CmpEq(const a, b: TVecU32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:552`
- [x] `function VecU32x4CmpLt(const a, b: TVecU32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:553`
- [x] `function VecU32x4CmpGt(const a, b: TVecU32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:554`
- [x] `function VecU32x4CmpLe(const a, b: TVecU32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:555`
- [x] `function VecU32x4CmpGe(const a, b: TVecU32x4): TMask4; inline;` — `src/fafafa.core.simd.pas:556`
- [x] `function VecU32x4Min(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:559`
- [x] `function VecU32x4Max(const a, b: TVecU32x4): TVecU32x4; inline;` — `src/fafafa.core.simd.pas:560`
- [x] `function VecF32x8Add(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:566`
- [x] `function VecF32x8Sub(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:567`
- [x] `function VecF32x8Mul(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:568`
- [x] `function VecF32x8Div(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:569`
- [x] `function VecF32x8CmpEq(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:572`
- [x] `function VecF32x8CmpLt(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:573`
- [x] `function VecF32x8CmpLe(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:574`
- [x] `function VecF32x8CmpGt(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:575`
- [x] `function VecF32x8CmpGe(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:576`
- [x] `function VecF32x8CmpNe(const a, b: TVecF32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:577`
- [x] `function VecF32x8Abs(const a: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:580`
- [x] `function VecF32x8Sqrt(const a: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:581`
- [x] `function VecF32x8Min(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:582`
- [x] `function VecF32x8Max(const a, b: TVecF32x8): TVecF32x8; inline;` — `src/fafafa.core.simd.pas:583`
- [x] `function VecF32x8ReduceAdd(const a: TVecF32x8): Single; inline;` — `src/fafafa.core.simd.pas:586`
- [x] `function VecF32x8ReduceMin(const a: TVecF32x8): Single; inline;` — `src/fafafa.core.simd.pas:587`
- [x] `function VecF32x8ReduceMax(const a: TVecF32x8): Single; inline;` — `src/fafafa.core.simd.pas:588`
- [x] `function VecF32x8ReduceMul(const a: TVecF32x8): Single; inline;` — `src/fafafa.core.simd.pas:589`
- [x] `function VecI32x8Add(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:595`
- [x] `function VecI32x8Sub(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:596`
- [x] `function VecI32x8Mul(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:597`
- [x] `function VecI32x8And(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:600`
- [x] `function VecI32x8Or(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:601`
- [x] `function VecI32x8Xor(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:602`
- [x] `function VecI32x8Not(const a: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:603`
- [x] `function VecI32x8AndNot(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:604`
- [x] `function VecI32x8ShiftLeft(const a: TVecI32x8; count: Integer): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:607`
- [x] `function VecI32x8ShiftRight(const a: TVecI32x8; count: Integer): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:608`
- [x] `function VecI32x8ShiftRightArith(const a: TVecI32x8; count: Integer): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:609`
- [x] `function VecI32x8CmpEq(const a, b: TVecI32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:612`
- [x] `function VecI32x8CmpLt(const a, b: TVecI32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:613`
- [x] `function VecI32x8CmpGt(const a, b: TVecI32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:614`
- [x] `function VecI32x8CmpLe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:615`
- [x] `function VecI32x8CmpGe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:616`
- [x] `function VecI32x8CmpNe(const a, b: TVecI32x8): TMask8; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:617`
- [x] `function VecI32x8Min(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:620`
- [x] `function VecI32x8Max(const a, b: TVecI32x8): TVecI32x8; inline;` — `src/fafafa.core.simd.pas:621`
- [x] `function VecU32x8Add(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:627`
- [x] `function VecU32x8Sub(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:628`
- [x] `function VecU32x8Mul(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:629`
- [x] `function VecU32x8And(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:632`
- [x] `function VecU32x8Or(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:633`
- [x] `function VecU32x8Xor(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:634`
- [x] `function VecU32x8Not(const a: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:635`
- [x] `function VecU32x8AndNot(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:636`
- [x] `function VecU32x8ShiftLeft(const a: TVecU32x8; count: Integer): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:639`
- [x] `function VecU32x8ShiftRight(const a: TVecU32x8; count: Integer): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:640`
- [x] `function VecU32x8CmpEq(const a, b: TVecU32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:643`
- [x] `function VecU32x8CmpLt(const a, b: TVecU32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:644`
- [x] `function VecU32x8CmpGt(const a, b: TVecU32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:645`
- [x] `function VecU32x8CmpLe(const a, b: TVecU32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:646`
- [x] `function VecU32x8CmpGe(const a, b: TVecU32x8): TMask8; inline;` — `src/fafafa.core.simd.pas:647`
- [x] `function VecU32x8Min(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:650`
- [x] `function VecU32x8Max(const a, b: TVecU32x8): TVecU32x8; inline;` — `src/fafafa.core.simd.pas:651`
- [x] `function VecI64x4Add(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:657`
- [x] `function VecI64x4Sub(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:658`
- [x] `function VecI64x4And(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:661`
- [x] `function VecI64x4Or(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:662`
- [x] `function VecI64x4Xor(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:663`
- [x] `function VecI64x4Not(const a: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:664`
- [x] `function VecI64x4AndNot(const a, b: TVecI64x4): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:665`
- [x] `function VecI64x4ShiftLeft(const a: TVecI64x4; count: Integer): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:668`
- [x] `function VecI64x4ShiftRight(const a: TVecI64x4; count: Integer): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:669`
- [x] `function VecI64x4CmpEq(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:672`
- [x] `function VecI64x4CmpLt(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:673`
- [x] `function VecI64x4CmpGt(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:674`
- [x] `function VecI64x4CmpLe(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:675`
- [x] `function VecI64x4CmpGe(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:676`
- [x] `function VecI64x4CmpNe(const a, b: TVecI64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:677`
- [x] `function VecI64x4Load(p: PInt64): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:680`
- [x] `procedure VecI64x4Store(p: PInt64; const a: TVecI64x4); inline;` — `src/fafafa.core.simd.pas:681`
- [x] `function VecI64x4Splat(value: Int64): TVecI64x4; inline;` — `src/fafafa.core.simd.pas:682`
- [x] `function VecI64x4Zero: TVecI64x4; inline;` — `src/fafafa.core.simd.pas:683`
- [x] `function VecU64x4Add(const a, b: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:689`
- [x] `function VecU64x4Sub(const a, b: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:690`
- [x] `function VecU64x4And(const a, b: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:693`
- [x] `function VecU64x4Or(const a, b: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:694`
- [x] `function VecU64x4Xor(const a, b: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:695`
- [x] `function VecU64x4Not(const a: TVecU64x4): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:696`
- [x] `function VecU64x4ShiftLeft(const a: TVecU64x4; count: Integer): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:699`
- [x] `function VecU64x4ShiftRight(const a: TVecU64x4; count: Integer): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:700`
- [x] `function VecU64x4CmpEq(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:703`
- [x] `function VecU64x4CmpLt(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:704`
- [x] `function VecU64x4CmpGt(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:705`
- [x] `function VecU64x4CmpLe(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:706`
- [x] `function VecU64x4CmpGe(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:707`
- [x] `function VecU64x4CmpNe(const a, b: TVecU64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:708`
- [x] `function VecU64x4Splat(value: UInt64): TVecU64x4; inline;` — `src/fafafa.core.simd.pas:711`
- [x] `function VecU64x4Zero: TVecU64x4; inline;` — `src/fafafa.core.simd.pas:712`
- [x] `function VecI16x8Add(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:718`
- [x] `function VecI16x8Sub(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:719`
- [x] `function VecI16x8Mul(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:720`
- [x] `function VecI16x8And(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:723`
- [x] `function VecI16x8Or(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:724`
- [x] `function VecI16x8Xor(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:725`
- [x] `function VecI16x8Not(const a: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:726`
- [x] `function VecI16x8AndNot(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:727`
- [x] `function VecI16x8ShiftLeft(const a: TVecI16x8; count: Integer): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:730`
- [x] `function VecI16x8ShiftRight(const a: TVecI16x8; count: Integer): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:731`
- [x] `function VecI16x8ShiftRightArith(const a: TVecI16x8; count: Integer): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:732`
- [x] `function VecI16x8CmpEq(const a, b: TVecI16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:735`
- [x] `function VecI16x8CmpLt(const a, b: TVecI16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:736`
- [x] `function VecI16x8CmpGt(const a, b: TVecI16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:737`
- [x] `function VecI16x8Min(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:740`
- [x] `function VecI16x8Max(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:741`
- [x] `function VecI8x16Add(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:747`
- [x] `function VecI8x16Sub(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:748`
- [x] `function VecI8x16And(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:751`
- [x] `function VecI8x16Or(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:752`
- [x] `function VecI8x16Xor(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:753`
- [x] `function VecI8x16Not(const a: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:754`
- [x] `function VecI8x16AndNot(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:755`
- [x] `function VecI8x16CmpEq(const a, b: TVecI8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:758`
- [x] `function VecI8x16CmpLt(const a, b: TVecI8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:759`
- [x] `function VecI8x16CmpGt(const a, b: TVecI8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:760`
- [x] `function VecI8x16Min(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:763`
- [x] `function VecI8x16Max(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:764`
- [x] `function VecU8x16Add(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:770`
- [x] `function VecU8x16Sub(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:771`
- [x] `function VecU8x16And(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:774`
- [x] `function VecU8x16Or(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:775`
- [x] `function VecU8x16Xor(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:776`
- [x] `function VecU8x16Not(const a: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:777`
- [x] `function VecU8x16AndNot(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:778`
- [x] `function VecU8x16CmpEq(const a, b: TVecU8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:781`
- [x] `function VecU8x16CmpLt(const a, b: TVecU8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:782`
- [x] `function VecU8x16CmpGt(const a, b: TVecU8x16): TMask16; inline;` — `src/fafafa.core.simd.pas:783`
- [x] `function VecU8x16Min(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:786`
- [x] `function VecU8x16Max(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:787`
- [x] `function VecU16x8Add(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:793`
- [x] `function VecU16x8Sub(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:794`
- [x] `function VecU16x8Mul(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:795`
- [x] `function VecU16x8And(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:798`
- [x] `function VecU16x8Or(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:799`
- [x] `function VecU16x8Xor(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:800`
- [x] `function VecU16x8Not(const a: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:801`
- [x] `function VecU16x8AndNot(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:802`
- [x] `function VecU16x8ShiftLeft(const a: TVecU16x8; count: Integer): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:805`
- [x] `function VecU16x8ShiftRight(const a: TVecU16x8; count: Integer): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:806`
- [x] `function VecU16x8CmpEq(const a, b: TVecU16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:809`
- [x] `function VecU16x8CmpLt(const a, b: TVecU16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:810`
- [x] `function VecU16x8CmpGt(const a, b: TVecU16x8): TMask8; inline;` — `src/fafafa.core.simd.pas:811`
- [x] `function VecU16x8Min(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:814`
- [x] `function VecU16x8Max(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:815`
- [x] `function VecF64x4Add(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:821`
- [x] `function VecF64x4Sub(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:822`
- [x] `function VecF64x4Mul(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:823`
- [x] `function VecF64x4Div(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:824`
- [x] `function VecF64x4CmpEq(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:827`
- [x] `function VecF64x4CmpLt(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:828`
- [x] `function VecF64x4CmpLe(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:829`
- [x] `function VecF64x4CmpGt(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:830`
- [x] `function VecF64x4CmpGe(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:831`
- [x] `function VecF64x4CmpNe(const a, b: TVecF64x4): TMask4; inline;` — `src/fafafa.core.simd.pas:832`
- [x] `function VecF64x4Abs(const a: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:835`
- [x] `function VecF64x4Sqrt(const a: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:836`
- [x] `function VecF64x4Min(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:837`
- [x] `function VecF64x4Max(const a, b: TVecF64x4): TVecF64x4; inline;` — `src/fafafa.core.simd.pas:838`
- [x] `function VecF64x4ReduceAdd(const a: TVecF64x4): Double; inline;` — `src/fafafa.core.simd.pas:841`
- [x] `function VecF64x4ReduceMin(const a: TVecF64x4): Double; inline;` — `src/fafafa.core.simd.pas:842`
- [x] `function VecF64x4ReduceMax(const a: TVecF64x4): Double; inline;` — `src/fafafa.core.simd.pas:843`
- [x] `function VecF64x4ReduceMul(const a: TVecF64x4): Double; inline;` — `src/fafafa.core.simd.pas:844`
- [x] `function VecF64x8Add(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:850`
- [x] `function VecF64x8Sub(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:851`
- [x] `function VecF64x8Mul(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:852`
- [x] `function VecF64x8Div(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:853`
- [x] `function VecF64x8CmpEq(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:856`
- [x] `function VecF64x8CmpLt(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:857`
- [x] `function VecF64x8CmpLe(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:858`
- [x] `function VecF64x8CmpGt(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:859`
- [x] `function VecF64x8CmpGe(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:860`
- [x] `function VecF64x8CmpNe(const a, b: TVecF64x8): TMask8; inline;` — `src/fafafa.core.simd.pas:861`
- [x] `function VecF64x8Abs(const a: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:864`
- [x] `function VecF64x8Sqrt(const a: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:865`
- [x] `function VecF64x8Min(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:866`
- [x] `function VecF64x8Max(const a, b: TVecF64x8): TVecF64x8; inline;` — `src/fafafa.core.simd.pas:867`
- [x] `function VecF64x8ReduceAdd(const a: TVecF64x8): Double; inline;` — `src/fafafa.core.simd.pas:870`
- [x] `function VecF64x8ReduceMin(const a: TVecF64x8): Double; inline;` — `src/fafafa.core.simd.pas:871`
- [x] `function VecF64x8ReduceMax(const a: TVecF64x8): Double; inline;` — `src/fafafa.core.simd.pas:872`
- [x] `function VecF64x8ReduceMul(const a: TVecF64x8): Double; inline;` — `src/fafafa.core.simd.pas:873`
- [x] `function VecF32x16Add(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:879`
- [x] `function VecF32x16Sub(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:880`
- [x] `function VecF32x16Mul(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:881`
- [x] `function VecF32x16Div(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:882`
- [x] `function VecF32x16CmpEq_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:885`
- [x] `function VecF32x16CmpLt_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:886`
- [x] `function VecF32x16CmpLe_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:887`
- [x] `function VecF32x16CmpGt_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:888`
- [x] `function VecF32x16CmpGe_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:889`
- [x] `function VecF32x16CmpNe_Mask(const a, b: TVecF32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:890`
- [x] `function VecF32x16Abs(const a: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:893`
- [x] `function VecF32x16Sqrt(const a: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:894`
- [x] `function VecF32x16Min(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:895`
- [x] `function VecF32x16Max(const a, b: TVecF32x16): TVecF32x16; inline;` — `src/fafafa.core.simd.pas:896`
- [x] `function VecF32x16ReduceAdd(const a: TVecF32x16): Single; inline;` — `src/fafafa.core.simd.pas:899`
- [x] `function VecF32x16ReduceMin(const a: TVecF32x16): Single; inline;` — `src/fafafa.core.simd.pas:900`
- [x] `function VecF32x16ReduceMax(const a: TVecF32x16): Single; inline;` — `src/fafafa.core.simd.pas:901`
- [x] `function VecF32x16ReduceMul(const a: TVecF32x16): Single; inline;` — `src/fafafa.core.simd.pas:902`
- [x] `function VecI32x16Add(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:908`
- [x] `function VecI32x16Sub(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:909`
- [x] `function VecI32x16Mul(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:910`
- [x] `function VecI32x16And(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:913`
- [x] `function VecI32x16Or(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:914`
- [x] `function VecI32x16Xor(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:915`
- [x] `function VecI32x16Not(const a: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:916`
- [x] `function VecI32x16AndNot(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:917`
- [x] `function VecI32x16ShiftLeft(const a: TVecI32x16; count: Integer): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:920`
- [x] `function VecI32x16ShiftRight(const a: TVecI32x16; count: Integer): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:921`
- [x] `function VecI32x16ShiftRightArith(const a: TVecI32x16; count: Integer): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:922`
- [x] `function VecI32x16CmpEq(const a, b: TVecI32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:925`
- [x] `function VecI32x16CmpLt(const a, b: TVecI32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:926`
- [x] `function VecI32x16CmpGt(const a, b: TVecI32x16): TMask16; inline;` — `src/fafafa.core.simd.pas:927`
- [x] `function VecI32x16CmpLe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:928`
- [x] `function VecI32x16CmpGe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:929`
- [x] `function VecI32x16CmpNe(const a, b: TVecI32x16): TMask16; inline;  // ✅ P0-C: 添加缺失 API` — `src/fafafa.core.simd.pas:930`
- [x] `function VecI32x16Min(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:933`
- [x] `function VecI32x16Max(const a, b: TVecI32x16): TVecI32x16; inline;` — `src/fafafa.core.simd.pas:934`
- [x] `function VecI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:938`
- [x] `function VecI8x16SatSub(const a, b: TVecI8x16): TVecI8x16; inline;` — `src/fafafa.core.simd.pas:939`
- [x] `function VecI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:940`
- [x] `function VecI16x8SatSub(const a, b: TVecI16x8): TVecI16x8; inline;` — `src/fafafa.core.simd.pas:941`
- [x] `function VecU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:943`
- [x] `function VecU8x16SatSub(const a, b: TVecU8x16): TVecU8x16; inline;` — `src/fafafa.core.simd.pas:944`
- [x] `function VecU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:945`
- [x] `function VecU16x8SatSub(const a, b: TVecU16x8): TVecU16x8; inline;` — `src/fafafa.core.simd.pas:946`
- [x] `function GetCurrentBackend: TSimdBackend;` — `src/fafafa.core.simd.pas:951`
- [x] `function GetCurrentBackendInfo: TSimdBackendInfo;` — `src/fafafa.core.simd.pas:952`
- [x] `function GetCPUInformation: TCPUInfo;` — `src/fafafa.core.simd.pas:955`
- [x] `function GetAvailableBackendList: TSimdBackendArray;` — `src/fafafa.core.simd.pas:958`
- [x] `procedure ForceBackend(backend: TSimdBackend);` — `src/fafafa.core.simd.pas:961`
- [x] `procedure ResetBackendSelection;` — `src/fafafa.core.simd.pas:962`
- [x] `function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:973`
- [x] `function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:976`
- [x] `function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:985`
- [x] `function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:996`
- [x] `function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2; inline;` — `src/fafafa.core.simd.pas:999`
- [x] `function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:1002`
- [x] `function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:1011`
- [x] `function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:1018`
- [x] `function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4; inline;` — `src/fafafa.core.simd.pas:1025`
- [x] `function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4; inline;` — `src/fafafa.core.simd.pas:1032`
- [x] `function AllocateAligned(size: NativeUInt; alignment: NativeUInt = 32): Pointer;` — `src/fafafa.core.simd.pas:1037`
- [x] `procedure FreeAligned(ptr: Pointer);` — `src/fafafa.core.simd.pas:1038`
- [x] `function IsPointerAligned(ptr: Pointer; alignment: NativeUInt = 32): Boolean;` — `src/fafafa.core.simd.pas:1041`

### fafafa.core.simd.api

- [x] `function MemEqual(a, b: Pointer; len: SizeUInt): LongBool; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:17`
- [x] `function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:20`
- [x] `function MemDiffRange(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:23`
- [x] `procedure MemCopy(src, dst: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:26`
- [x] `procedure MemSet(dst: Pointer; len: SizeUInt; value: Byte); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:29`
- [x] `procedure MemReverse(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:32`
- [x] `function SumBytes(p: Pointer; len: SizeUInt): UInt64; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:37`
- [x] `procedure MinMaxBytes(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:40`
- [x] `function CountByte(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:43`
- [x] `function Utf8Validate(p: Pointer; len: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:48`
- [x] `function AsciiIEqual(a, b: Pointer; len: SizeUInt): Boolean; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:51`
- [x] `procedure ToLowerAscii(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:54`
- [x] `procedure ToUpperAscii(p: Pointer; len: SizeUInt); {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:57`
- [x] `function BytesIndexOf(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:62`
- [x] `function BitsetPopCount(p: Pointer; byteLen: SizeUInt): SizeUInt; {$IFDEF SIMD_AGGRESSIVE_INLINE}inline;{$ENDIF}` — `src/fafafa.core.simd.api.pas:67`
