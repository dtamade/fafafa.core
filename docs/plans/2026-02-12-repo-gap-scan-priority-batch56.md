# Repo Gap Scan Priority Batch-56 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于全仓缺口复扫，优先修复 `src/fafafa.core.os.pas` 的 `os_cpu_info_ex` “cache size detection” TODO，并补齐 Linux 下可验证的测试，按严格 TDD（Baseline→RED→GREEN→Regression）闭环。

**Architecture:**
- 仅在 `{$IFDEF LINUX}` 下实现 sysfs (`/sys/devices/system/cpu/cpu0/cache/index*/{level,size}`) 的 best-effort 解析，将结果写入 `TCPUInfo.CacheL1/CacheL2/CacheL3`。
- 测试侧同样读取 sysfs 计算期望值；若 sysfs 不存在则 soft skip；否则断言 `os_cpu_info_ex` 返回的 cache 字段与期望一致。

**Tech Stack:** FreePascal/FPCUnit、`src/fafafa.core.os.pas`、`tests/fafafa.core.os/fafafa.core.os.testcase.pas`、`tests/fafafa.core.os/fafafa.core.os.test.lpr`。

---

## 全仓复扫快照（2026-02-12）

- `rg --files src tests examples benchmarks docs | wc -l` => `4822`
- `rg -n --glob 'src/**/*.pas' 'TODO|FIXME|未实现|待实现|暂未|placeholder' | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `52`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

### 热点（摘要）
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas` (`34`)：非活跃单元名（文件名不匹配 unit），属于噪声来源，建议后续归档处理。
- `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` (`6`)：多为“未实现”文案，不是占位断言。
- `src/fafafa.core.toml.pas` (`7`)：字符串/Unicode 转义与 writer emit TODO，规模偏大。
- `src/fafafa.core.os.pas`：`os_cpu_info_ex` 缓存探测 TODO（本批 P0）。

### 优先级
- `P0`（本批执行）：Linux `os_cpu_info_ex` cache size detection（填充 `CacheL1/CacheL2/CacheL3`）
- `P1`：`src/fafafa.core.toml.pas` 字符串/Unicode 转义（需更多用例与边界）
- `P2`：`tests/fafafa.core.sync.barrier/*testcase.old.pas` 归档/清理策略（避免误导扫描）

---

## Task 1: Baseline（现状验证）

**Files:**
- Verify: `src/fafafa.core.os.pas`
- Verify: `tests/fafafa.core.os/fafafa.core.os.testcase.pas`

**Step 1: 编译 os 测试二进制**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEtests/fafafa.core.os/bin -FUtests/fafafa.core.os/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.os tests/fafafa.core.os/fafafa.core.os.test.lpr`
Expected:
- 编译成功，生成 `tests/fafafa.core.os/bin/fafafa.core.os.test`

**Step 2: 运行已有用例（确保链路可用）**
Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.os/bin/fafafa.core.os.test --format=plain --suite=TTestCase_Global.Test_os_cpu_info_ex`
Expected:
- `Number of failures: 0`

---

## Task 2: RED（新增 failing test）

**Files:**
- Modify: `tests/fafafa.core.os/fafafa.core.os.testcase.pas`

**Step 1: 添加 Linux cache sizes 测试声明与实现**
- 新增 `Test_os_cpu_info_ex_cache_sizes_linux`（仅 Linux 编译）。
- 若 `/sys/devices/system/cpu/cpu0/cache` 不存在则 soft skip。
- 否则读取 `index*/level` 与 `index*/size` 计算期望：L1 累加、L2/L3 取最大。
- 断言 `os_cpu_info_ex` 返回值与期望一致（至少 Expected>0 时必须匹配）。

**Step 2: 编译 + 运行新用例验证失败**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEtests/fafafa.core.os/bin -FUtests/fafafa.core.os/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.os tests/fafafa.core.os/fafafa.core.os.test.lpr`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.os/bin/fafafa.core.os.test --format=plain --suite=TTestCase_Global.Test_os_cpu_info_ex_cache_sizes_linux`
Expected:
- 失败：当前实现未填充 cache 字段，导致期望与实际不一致。

---

## Task 3: GREEN（最小实现）

**Files:**
- Modify: `src/fafafa.core.os.pas`

**Step 1: 在 `{$IFDEF LINUX}` 下实现 sysfs cache 探测**
- 读取 `/sys/devices/system/cpu/cpu0/cache/index*/level` 与 `size`。
- `size` 支持 `K/M/G` 单位（例如 `32K`）。
- 写入：`Info.CacheL1`（累加）、`Info.CacheL2/CacheL3`（取最大）。
- best-effort：任何读取失败直接跳过，不影响 `os_cpu_info_ex` 返回 True。

**Step 2: 重新编译 + 复跑用例**
Run:
- 同 Task 2 的编译命令
- 同 Task 2 的运行命令
Expected:
- `Number of failures: 0`

---

## Task 4: Regression（回归）

**Files:**
- Verify: `tests/fafafa.core.os/fafafa.core.os.testcase.pas`

**Step 1: 回归相关用例子集**
Run:
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.os/bin/fafafa.core.os.test --format=plain --suite=TTestCase_Global.Test_os_cpu_info_ex`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.os/bin/fafafa.core.os.test --format=plain --suite=TTestCase_Global.Test_os_cpu_info_ex_features_frequency_linux`
- `cd /home/dtamade/projects/fafafa.core && tests/fafafa.core.os/bin/fafafa.core.os.test --format=plain --suite=TTestCase_Global.Test_os_cpu_info_usage_linux`
Expected:
- 子集全部 `Number of failures: 0`

**Step 2: 同步 planning-with-files**
- 更新 `task_plan.md` / `findings.md` / `progress.md`。

---

## 执行记录（2026-02-12 Batch-56）

### Phase-1 Baseline
- 编译：`BUILD_RC=0`（Linking `tests/fafafa.core.os/bin/fafafa.core.os.test`）
- 运行：`RUN_RC=0`
- 关键输出：
  - `Number of run tests: 1`
  - `Number of errors:    0`
  - `Number of failures:  0`

### Phase-2 RED
- 新增测试：`TTestCase_Global.Test_os_cpu_info_ex_cache_sizes_linux`
- 编译：`BUILD_RC=0`
- 运行：`RUN_RC=1`
- 失败输出（关键）：
  - `Failed: "CacheL1 mismatch" expected: <65536> but was: <0>`

### Phase-3 GREEN
- 实现：Linux sysfs cache 探测（填充 `CacheL1/CacheL2/CacheL3`）
- 编译：`BUILD_RC=0`
- 运行：`RUN_RC=0`

### Phase-4 Regression
- 子集回归：
  - `Test_os_cpu_info_ex`：`RUN_RC=0`
  - `Test_os_cpu_info_ex_features_frequency_linux`：`RUN_RC=0`
  - `Test_os_cpu_info_usage_linux`：`RUN_RC=0`
