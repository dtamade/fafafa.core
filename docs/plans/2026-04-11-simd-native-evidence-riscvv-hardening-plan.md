# SIMD Native Evidence And RISCVV Hardening Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `simd` 的 native non-x86 evidence 变成正式 verifier/gate，并补强 `RISCVV` ABI 敏感实现的 source-side 护栏。

**Architecture:** 本批次不再扩 public API，也不假装在 `x86_64` 上完成原生 `arm64/riscv64` 证据。实现重点是三层：1) native evidence verifier + fixture，2) `BuildOrTest.sh` 的 fail-close gate 接线，3) `RISCVV` 复合返回 / hidden-result-pointer 形状的 source checker。外部主机只保留为最后一步 evidence 采集。

**Tech Stack:** Bash, Python3, FreePascal/Lazarus, existing SIMD gate/checker/doc flow.

---

### Task 1: 落 native evidence verifier 计划与 fixture

**Files:**
- Create: `tests/fafafa.core.simd/verify_nonx86_native_evidence.py`
- Create: `tests/fafafa.core.simd/fixtures/native-evidence/native-evidence-neon-20260411-000000/summary.md`
- Create: `tests/fafafa.core.simd/fixtures/native-evidence/native-evidence-neon-20260411-000000/environment.txt`
- Create: `tests/fafafa.core.simd/fixtures/native-evidence/native-evidence-riscvv-20260411-000000/summary.md`
- Create: `tests/fafafa.core.simd/fixtures/native-evidence/native-evidence-riscvv-20260411-000000/environment.txt`

**Step 1: Red**

Run:
```bash
python3 tests/fafafa.core.simd/verify_nonx86_native_evidence.py --root tests/fafafa.core.simd/fixtures/native-evidence --backend neon
```

Expected:
- 失败，原因是 verifier 还不存在

**Step 2: Green**

实现 verifier：
- 支持 `--root` / `--backend`
- 自动发现最新 `native-evidence-neon-*` / `native-evidence-riscvv-*`
- 校验 `summary.md` / `environment.txt`
- 要求 `Runtime Parity`、`DispatchAPI + PublicAbi`、`list-suites`
- 要求 `fa_build_mode=Release`
- 要求 `host_arch=arm64` 对应 `neon`，`host_arch=riscv64` 对应 `riscvv`

**Step 3: Verify**

Run:
```bash
python3 tests/fafafa.core.simd/verify_nonx86_native_evidence.py --root tests/fafafa.core.simd/fixtures/native-evidence --backend neon --summary-line
python3 tests/fafafa.core.simd/verify_nonx86_native_evidence.py --root tests/fafafa.core.simd/fixtures/native-evidence --backend riscvv --summary-line
```

Expected:
- 两条都 `status=ok`

### Task 2: 接入 BuildOrTest gate

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: Red**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh verify-nonx86-native-evidence
```

Expected:
- 失败，action 尚不存在

**Step 2: Green**

实现：
- 新增 `verify-nonx86-native-evidence` action
- 新增 `SIMD_NONX86_NATIVE_EVIDENCE_ROOT`
- 新增 gate step：`nonx86-native-evidence-verify`
- `gate` 默认可选
- `gate-strict` 默认 `SIMD_GATE_REQUIRE_NONX86_NATIVE_EVIDENCE=1`

**Step 3: Verify**

Run:
```bash
SIMD_NONX86_NATIVE_EVIDENCE_ROOT=tests/fafafa.core.simd/fixtures/native-evidence bash tests/fafafa.core.simd/BuildOrTest.sh verify-nonx86-native-evidence
```

Expected:
- action 通过

### Task 3: 增加 RISCVV ABI shape checker

**Files:**
- Create: `tests/fafafa.core.simd/check_riscvv_abi_shape.py`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: Red**

Run:
```bash
python3 tests/fafafa.core.simd/check_riscvv_abi_shape.py --summary-line
```

Expected:
- 失败，checker 尚不存在

**Step 2: Green**

实现 checker：
- 扫描 `src/fafafa.core.simd.riscvv.pas`
- 针对 direct vector-return assembler function 检查 hidden-result-pointer 形状
- 至少保证：
  - 结果写回 `(a0)`
  - 有输入参数时，不允许把 `(a0)` 当成输入向量/指针源
  - 对 `RISCVVLoadI64x4Asm` / `RISCVVSplatI64x4Asm` / `RISCVVZeroI64x4Asm` / `RISCVVInsert*` / `RISCVVExtract*` 保留显式片段检查

**Step 3: Verify**

Run:
```bash
python3 tests/fafafa.core.simd/check_riscvv_abi_shape.py --summary-line
```

Expected:
- `status=ok`

### Task 4: 文档与 closeout 同步

**Files:**
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/plans/2026-04-11-simd-implementation-phase2-plan.md`

**Step 1: Update**

要求：
- 把 `verify-nonx86-native-evidence` 命令写入 checklist
- 明确 `gate-strict` 默认对 native evidence fail-close
- 继续明确 `x86_64` 只能完成 host-local closeout，不能宣称 native runtime closeout

**Step 2: Verify**

Run:
```bash
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
python3 tests/fafafa.core.simd/check_riscvv_abi_shape.py --summary-line
SIMD_NONX86_NATIVE_EVIDENCE_ROOT=tests/fafafa.core.simd/fixtures/native-evidence bash tests/fafafa.core.simd/BuildOrTest.sh verify-nonx86-native-evidence
```

### Task 5: Final verification

**Files:**
- Verify only

**Step 1: Fresh commands**

Run:
```bash
FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_ENABLE_RISCVV_BACKEND=1 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane

SIMD_NONX86_NATIVE_EVIDENCE_ROOT=tests/fafafa.core.simd/fixtures/native-evidence FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_NONX86_NATIVE_EVIDENCE=1 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict

git diff --check
```

**Step 2: External host handoff**

必须保留最后一步：
```bash
SIMD_ENABLE_NEON_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence neon
SIMD_ENABLE_RISCVV_BACKEND=1 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence riscvv
```

Expected:
- 这两条只能在原生 `arm64` / `riscv64` 主机上执行
- 本机只负责把 verifier / gate / docs 准备好
