# SIMD Implementation Efficiency Closeout Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把当前 SIMD 实现侧已存在的 non-x86 checker、strict gate 和 native-evidence 流程收束成低误用、低维护成本的统一入口，并明确 `x86_64` 主机与外部原生主机的收口边界。

**Architecture:** 不改 public API / public ABI，只增强 runner、collector 和文档。新增一个实现侧聚合审计入口，负责把 helper semantics、wiring truthfulness、RISCVV ABI 形状检查和 targeted runtime suite 固化为单条命令；再新增一个 host-local closeout 入口，把本机可证明的严格收口串起来，但不伪造 native `arm64/riscv64` runtime 完成。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, Python3 checker, existing `BuildOrTest.sh` / `buildOrTest.bat`, existing native-evidence fixtures and gate summary helpers.

---

### Task 1: 新增 non-x86 实现聚合审计入口

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`

**Step 1: 在 shell runner 增加 `impl-audit-nonx86` helper**

要求：

- 顺序固定为：
  1. `check_nonx86_helper_semantics.py --summary-line`
  2. `check_nonx86_wiring_sync.py --summary-line`
  3. `check_riscvv_abi_shape.py --summary-line`
  4. `check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  5. `check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  6. `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_ENABLE_RISCVV_BACKEND=1 ... test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane`
- 输出单独日志
- 支持在存在 native-evidence root 时附带 verifier；无 root 时可跳过但必须明确打印

**Step 2: 在 batch runner 增加同名入口**

要求：

- 若有 `bash`，直接桥接到 `BuildOrTest.sh impl-audit-nonx86`
- 若无 `bash`，明确报错，不要静默跳过

**Step 3: 验证聚合入口**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
```

Expected:

- 所有 checker 和 targeted suite 串行执行
- 失败时停在首个失败项
- 成功时打印统一 summary

---

### Task 2: 把 native-evidence collector 接入聚合审计入口

**Files:**
- Modify: `tests/fafafa.core.simd/collect_nonx86_native_evidence.sh`

**Step 1: 替换 collector 内部的实现侧审计调用**

要求：

- native host 采集时，不再只跑裸 `check`
- 改为显式调用 `BuildOrTest.sh impl-audit-nonx86`
- 保留 `list-suites`、`DispatchAPI/PublicAbi`、`Runtime Parity`

**Step 2: 验证 collector 语义不退化**

Run:

```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
```

Expected:

- 仍保持 `status=ok`
- 文档/collector 中仍明确写出 native runtime parity 是原生主机责任

---

### Task 3: 新增 host-local closeout 聚合入口

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/plans/2026-04-11-simd-implementation-phase2-plan.md`

**Step 1: 在 shell runner 增加 `closeout-host-local`**

要求：

- 固定顺序：
  1. `impl-audit-nonx86`
  2. `gate-strict`
- 语义必须写清：
  - 默认仍要求 `SIMD_GATE_REQUIRE_NONX86_NATIVE_EVIDENCE=1`
  - `x86_64` 上若无归档 evidence，strict gate 故意失败
  - 该动作只代表 host-local closeout，不代表 fresh native `arm64/riscv64` runtime closeout

**Step 2: 在 batch runner 增加同名桥接入口**

要求：

- 行为同 `impl-audit-nonx86`

**Step 3: 更新 checklist / closeout / phase2 plan**

要求：

- 让 `impl-audit-nonx86` 成为日常实现侧审计主入口
- 让 `closeout-host-local` 成为本机严格收口主入口
- 原生 `arm64/riscv64` 采集命令继续单列为外部步骤，不得改写成“已完成”

---

### Task 4: 全量验证

**Files:**
- Verify only

**Step 1: 运行实现聚合审计**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
```

**Step 2: 运行 native-evidence verifier**

Run:

```bash
SIMD_NONX86_NATIVE_EVIDENCE_ROOT=tests/fafafa.core.simd/fixtures/native-evidence \
bash tests/fafafa.core.simd/BuildOrTest.sh verify-nonx86-native-evidence
```

**Step 3: 运行 host-local closeout**

Run:

```bash
SIMD_NONX86_NATIVE_EVIDENCE_ROOT=tests/fafafa.core.simd/fixtures/native-evidence \
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 \
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

**Step 4: 运行格式/工作树检查**

Run:

```bash
git diff --check
```

Expected:

- 聚合入口、closeout 入口和文档口径一致
- host-local closeout fresh 通过
- 没有新的 whitespace / conflict 类问题
