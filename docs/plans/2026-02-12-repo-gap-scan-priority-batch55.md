# Repo Gap Scan Priority Batch-55 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 先完成全仓缺口复扫并形成优先级，再以严格 TDD 一次性替换 `vecdeque` 的独立占位程序 `test_strategy_pow2_rounding.pas` 为真实可执行断言测试。

**Architecture:** 采用单文件最小改动策略：保持 `src` 不改，只替换独立程序逻辑，直接调用 `TVecDeque<Integer>.Create(aCapacity)` 验证容量 2 的幂归一语义。执行顺序严格为 Baseline（占位真通过）→ RED（显式失败）→ GREEN（真实断言通过）→ Regression（复跑稳定）。

**Tech Stack:** FreePascal (fpc), Pascal 独立程序测试, `src/fafafa.core.collections.vecdeque.pas`, `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`。

---

## 全仓复扫快照（2026-02-12）

- `rg --files src tests examples benchmarks docs | wc -l` => `4821`
- `rg -n --glob 'src/**/*.pas' 'TODO|FIXME|未实现|待实现|暂未|placeholder' | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `54`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

### 热点（Top）
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas` (`34`)：非活跃入口（不在当前 `.lpr` uses）。
- `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` (`6`)：以注释文案型占位为主。
- `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas` (`2`)：活跃脚本直接编译执行，当前为 placeholder 真通过。

### 优先级
- `P0`（本批执行）：`tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`
- `P1`（后续）：`tests/fafafa.core.socket/Test_fafafa_core_socket.pas`
- `P2`（后续）：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`

---

### Task 1: Baseline（占位现状确认）

**Files:**
- Verify: `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`

**Step 1: Build 当前 placeholder 程序**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -Mobjfpc -Sh -O1 -g -gl -l -vewnhibq -I./src -Fu./src -FUtests/fafafa.core.collections/vecdeque/lib -FEtests/fafafa.core.collections/vecdeque/bin tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`
Expected:
- 编译成功，生成 `tests/fafafa.core.collections/vecdeque/bin/test_strategy_pow2_rounding`

**Step 2: 运行 placeholder**
Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.collections/vecdeque/bin/test_strategy_pow2_rounding`
Expected:
- 输出 placeholder 文案，退出码 `0`（证明当前是“真通过占位”）

---

### Task 2: RED（先让测试失败）

**Files:**
- Modify: `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`

**Step 1: 改为显式失败断言（最小 RED）**
- 实现最小断言函数并故意失败（例如比较 `Create(10)` 容量与错误预期）。

**Step 2: Build + Run 验证 RED**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -Mobjfpc -Sh -O1 -g -gl -l -vewnhibq -I./src -Fu./src -FUtests/fafafa.core.collections/vecdeque/lib -FEtests/fafafa.core.collections/vecdeque/bin tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.collections/vecdeque/bin/test_strategy_pow2_rounding`
Expected:
- 程序输出 `RED` 失败信息，退出码非 `0`

---

### Task 3: GREEN（最小真实实现）

**Files:**
- Modify: `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`
- Reference: `src/fafafa.core.collections.vecdeque.pas`

**Step 1: 写入真实断言逻辑**
- 断言 `Create(0)` 容量为 `1`（由 `NextPowerOfTwo(Max(aCapacity,1))`）。
- 断言 `Create(10)` 容量为 `16`。
- 断言 `Create(16)` 容量为 `16`。
- 断言 `Create(17)` 容量为 `32`。
- 增加通用 `IsPowerOfTwo` 验证，确保所有目标容量均满足 2 的幂。

**Step 2: Build + Run 验证 GREEN**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -Mobjfpc -Sh -O1 -g -gl -l -vewnhibq -I./src -Fu./src -FUtests/fafafa.core.collections/vecdeque/lib -FEtests/fafafa.core.collections/vecdeque/bin tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.collections/vecdeque/bin/test_strategy_pow2_rounding`
Expected:
- 输出全部断言通过信息，退出码 `0`

---

### Task 4: Regression（稳定性复跑）

**Files:**
- Verify: `tests/fafafa.core.collections/vecdeque/test_strategy_pow2_rounding.pas`

**Step 1: 再次运行同一程序**
Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.collections/vecdeque/bin/test_strategy_pow2_rounding`
Expected:
- 结果稳定通过，退出码 `0`

**Step 2: 记录到 planning-with-files 三件套**
- 更新 `task_plan.md` / `findings.md` / `progress.md`，写入本批命令与输出。

---

## 执行记录（2026-02-12 Batch-55）

### Phase-1 Baseline
- Build：`BUILD_RC=0`
- Run：`RUN_RC=0`
- 输出：
  - `test_strategy_pow2_rounding - placeholder for missing test file`
  - `This file is a placeholder to allow compilation to proceed`

### Phase-2 RED
- 改动：将目标文件改为最小显式失败断言（错误预期 `Create(10)=8`）。
- Build：`BUILD_RC=0`
- Run：`RUN_RC=1`
- 输出：`[RED] Create(10) expected=8 actual=16`

### Phase-3 GREEN
- 改动：替换为真实断言（`Create(0/10/16/17)` 与 2 的幂校验）。
- Build：`BUILD_RC=0`
- Run：`RUN_RC=0`
- 输出：
  - `[PASS] Create(0) => Capacity=1`
  - `[PASS] Create(10) => Capacity=16`
  - `[PASS] Create(16) => Capacity=16`
  - `[PASS] Create(17) => Capacity=32`
  - `[PASS] test_strategy_pow2_rounding all checks passed`

### Phase-4 Regression
- Re-run：`RUN_RC=0`
- 结果：与 GREEN 输出一致，稳定通过。
