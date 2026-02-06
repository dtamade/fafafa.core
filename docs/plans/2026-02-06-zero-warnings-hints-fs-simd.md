# 0 Warnings/Hints：FS + SIMD 构建洁净化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 `tests/fafafa.core.fs/BuildOrTest.sh` 与 `tests/fafafa.core.simd/BuildOrTest.sh check` 在当前工具链下达到 **0 Warning/Hint** 并通过；随后继续推进全量回归。

**Architecture:** 以“消除告警”为驱动：优先修复真实初始化与可移植性问题；对已知无害且难以结构性消除的低层告警做局部抑制；每批修复后回跑模块级 `check` 验证。

**Tech Stack:** FreePascal (FPC), Lazarus `lazbuild`, Bash test runners

---

### Task 1: 复现基线失败（FS + SIMD）

**Files:** (none)

**Step 1: FS check 失败复现**
- Run: `bash tests/fafafa.core.fs/BuildOrTest.sh check`
- Expected: FAIL，build log 中出现 `src/.*(Warning|Hint)` 列表

**Step 2: SIMD check 失败复现**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- Expected: FAIL，列出 `fafafa.core.simd.avx2/sse2` 的 7121/5060

---

### Task 2: SIMD（AVX2）消除 7121/5060

**Files:**
- Modify: `src/fafafa.core.simd.avx2.pas`

**Step 1: 修复 5060（Result 初始化分析不通过）**
- 将 out-of-range 分支 `FillChar(Result, ...)` 改为显式 `Result := Default(TVecI32x4); Exit;`

**Step 2: 消除 7121（movsd operand-size 检查）**
- 将点积函数的标量写回改为 `vmovsd [result], xmm0`（避免本地 `res` + `movsd`）
- 将 splat 中 `movsd xmm0, value` 改为等价且不触发 7121 的写法（优先 `vmovsd`）

**Step 3: 验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- Expected: PASS（无 Warning/Hint）

---

### Task 3: SIMD（SSE2）消除 7121

**Files:**
- Modify: `src/fafafa.core.simd.sse2.pas`

**Step 1: 将 `movsd` 改为 SSE2 等价且更符合 operand-size 的指令**
- `movsd xmm0, value` → `movlpd xmm0, value`
- `movsd res, xmm0` → `movlpd res, xmm0`

**Step 2: 验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- Expected: PASS

---

### Task 4: atomic/memutils 消除未使用参数/常量 Hint

**Files:**
- Modify: `src/fafafa.core.atomic.pas`
- Modify: `src/fafafa.core.simd.memutils.pas`

**Step 1: atomic：禁用 5024 并消除 5028**
- 在单元顶部添加 `{$WARN 5024 OFF}`（memory_order 参数在部分实现中用于 API 对齐但不参与逻辑）
- x86_64 分支让 `TAG_SHIFT` 由 `TAG_BITS` 推导，确保 `TAG_BITS` 被使用

**Step 2: memutils：保证 alignment 在非 debug 情况也被引用**
- 在 `AlignedMemCopy/AlignedMemFill` 中添加无副作用引用（如 `if alignment = 0 then ;`）

**Step 3: 验证**
- Run: `bash tests/fafafa.core.fs/BuildOrTest.sh check`
- Expected: atomic/memutils 不再出现在 warning/hint 列表中

---

### Task 5: math/os/env 消除 flow-analysis Hint

**Files:**
- Modify: `src/fafafa.core.math.internal.pas`
- Modify: `src/fafafa.core.math.dispatch.pas`
- Modify: `src/fafafa.core.os.unix.inc`
- Modify: `src/fafafa.core.env.pas`

**Step 1: math.internal**
- `F64FromBits/F32FromBits`：先显式初始化 `Result` 再 `Move`
- `IsNaNF64/IsNaNF32`：先显式初始化 `bits` 再 `Move`

**Step 2: math.dispatch**
- 移除未使用的 `uses fafafa.core.math.arrays`

**Step 3: os.unix.inc**
- `uts/un` 在 `fpUname` 前 `FillChar(...,0)`，消除 “does not seem initialized”

**Step 4: env**
- 在单元顶部局部关闭 `{$WARN 3124 OFF}`（Inlining disabled）

**Step 5: 验证**
- Run: `bash tests/fafafa.core.fs/BuildOrTest.sh check`
- Expected: 不再出现上述单元的 Hint

---

### Task 6: fs 子系统消除 5093/4055/4082/5023/5026/5091

**Files:**
- Modify: `src/fafafa.core.fs.pathobj.pas`
- Modify: `src/fafafa.core.fs.dir.pas`
- Modify: `src/fafafa.core.fs.fileobj.pas`
- Modify: `src/fafafa.core.fs.bufio.pas`
- Modify: `src/fafafa.core.fs.std.pas`
- Modify: `src/fafafa.core.fs.copyaccel.pas`
- Modify: `src/fafafa.core.fs.fileio.pas`

**Step 1: managed Result 初始化**
- 在返回 `TBytes` / 动态数组 的函数开头显式 `Result := nil;`（再 `SetLength`）

**Step 2: fs.dir：移除 pointer/int hack**
- 将 `FTypes: TList` 改为 `FTypes: array of TfsDirEntType`（私有实现细节）并同步构造/析构/Next 逻辑

**Step 3: fs.std：移除未使用 uses**
- 删除未引用的 `fafafa.core.fs` / `fafafa.core.fs.path` / `fafafa.core.fs.options`（以编译通过为准）

**Step 4: copyaccel：局部抑制 syscall 参数转换 Hint**
- 在 syscall wrapper 周围 `{$PUSH}{$WARN 4055 OFF} ... {$POP}`

**Step 5: fileio：消除 ABuffer 5026**
- 在 `TFsFileNoExcept.Write/PWrite` 中显式引用 `@ABuffer`（无副作用）以避免编译器误判

**Step 6: 验证**
- Run: `bash tests/fafafa.core.fs/BuildOrTest.sh check`
- Expected: PASS（no src warnings/hints）

---

### Task 7: 全量回归推进

**Files:** (none)

**Step 1: 关键模块**
- Run: `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.fs fafafa.core.simd`
- Expected: exit 0

**Step 2: 全量（失败即停）**
- Run: `STOP_ON_FAIL=1 bash tests/run_all_tests.sh`
- Expected: 若失败，记录第一个失败模块并回到本流程新增 plan

**Step 3: 全量（完整）**
- Run: `bash tests/run_all_tests.sh`
- Expected: exit 0，summary Total>0

