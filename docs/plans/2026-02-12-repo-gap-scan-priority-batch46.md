# Repo Gap Scan Priority Batch-46 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于 2026-02-12 全仓扫描结果，先修复 TOML 默认解析路由缺口（默认走 V2 导致 Unicode 语义不稳定），用严格 TDD 一次性打通 Unicode 相关解析回归。  

**Architecture:** 保持 `trfUseV2` 显式路径不变，默认 `Parse` 收敛为 legacy 兼容语义（默认走 V1，仅显式 flag 走 V2）。并新增专门路由回归测试锁定行为，先把高频失败簇降下来，再在后续批次单独治理 V2 能力。  

**Tech Stack:** FreePascal/FPCUnit、`src/fafafa.core.toml.pas`、`tests/fafafa.core.toml/*`。

---

## 全仓扫描结论（2026-02-12）

### 结构与缺口基线
- 文件总量（`src tests examples benchmarks docs`）：`4811`
- `tests/fafafa.core*` 模块数：`151`
- `src` 中 TODO/未实现/占位命中：`47`（热点：`src/fafafa.core.toml.pas`=7，`src/fafafa.core.time.parse.pas`=6）
- `tests` 中 TODO/placeholder 相关命中：`64`（高密度历史文件：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`）
- 结构化脚本缺口：缺 `BuildOrTest.sh` 的 `fafafa.core*` 模块约 `40` 个，缺 `BuildOrTest.bat` 约 `83` 个

### 当前可复现高优先级失败（P0）
- `tests/fafafa.core.toml` 全量现状：`N:122 E:0 F:34`
- 失败簇集中在：Unicode 转义/Unicode key/部分 reader 错误前缀行为
- 关键可执行切入点：`src/fafafa.core.toml.pas:1155` 的默认 `Parse` 路由

### 优先级
1. **P0（本批执行）**：修复 TOML 默认 Parse 路由兼容性，收敛 Unicode 失败簇。  
2. **P1（下一批）**：`tests/fafafa.core.time/fafafa.core.time.test.lpr` 中禁用入口（文件缺失/API 不兼容）梳理与最小恢复。  
3. **P2（后续）**：补齐 `BuildOrTest.sh/.bat` 结构缺口（不改 CI，仅补模块入口）。

---

### Task 1: 新增路由回归测试并接入测试入口（RED）

**Files:**
- Create: `tests/fafafa.core.toml/Test_fafafa_core_toml_parse_router_fallback.pas`
- Modify: `tests/fafafa.core.toml/tests_toml.lpr`

**Step 1: Write the failing test**

```pascal
procedure TTestCase_Parse_Router_Fallback.Test_Default_Parse_Falls_Back_To_V1_For_Unicode;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('s = "a\u0061b"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
end;
```

**Step 2: Run test to verify it fails**

Run:
- `cd tests/fafafa.core.toml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. tests_toml.lpr`
- `./bin/tests_toml --format=plain --suite=TTestCase_Parse_Router_Fallback`

Expected:
- FAIL（默认 Parse 仍走 V2，不会回退到 V1）

---

### Task 2: 默认 Parse 路由最小修复（GREEN）

**Files:**
- Modify: `src/fafafa.core.toml.pas:1155`

**Step 1: Write minimal implementation**

```pascal
function Parse(...): Boolean;
begin
  if (trfUseV1 in AFlags) then Exit(_Parse_Internal_V1(...));
  if (trfUseV2 in AFlags) then Exit(TomlParseV2(...));
  Result := _Parse_Internal_V1(...);
end;
```

**Step 2: Run test to verify it passes**

Run:
- `cd tests/fafafa.core.toml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. tests_toml.lpr`
- `./bin/tests_toml --format=plain --suite=TTestCase_Parse_Router_Fallback`

Expected:
- PASS

---

### Task 3: 目标回归验证（GREEN）

**Files:**
- Test only: `tests/fafafa.core.toml/*`

**Step 1: Run targeted regressions**

Run:
- `cd tests/fafafa.core.toml && ./bin/tests_toml --format=plain --suite=TTestCase_Unicode_Escapes`
- `cd tests/fafafa.core.toml && ./bin/tests_toml --format=plain --suite=TTestCase_Unicode_Negatives`
- `cd tests/fafafa.core.toml && ./bin/tests_toml --format=plain --suite=TTestCase_Unicode_Negatives_Ext`
- `cd tests/fafafa.core.toml && ./bin/tests_toml --format=plain --suite=TTestCase_Unicode_Keys_Negatives`
- `cd tests/fafafa.core.toml && ./bin/tests_toml --format=plain --suite=TTestCase_Unicode_Keys_Regression`

Expected:
- 上述 suite 全部 PASS（`Number of failures: 0`）

**Step 2: Run module snapshot baseline**

Run:
- `cd tests/fafafa.core.toml && ./bin/tests_toml --all --format=plain --sparse`

Expected:
- 相比执行前，失败数显著下降且不新增错误。

---

## 执行记录（2026-02-12）

### Phase-1 RED
1) 新增 `Test_fafafa_core_toml_parse_router_fallback.pas` 并接入 `tests_toml.lpr`。  
2) 命令：
- `cd tests/fafafa.core.toml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. tests_toml.lpr`
- `./bin/tests_toml --format=plain --suite=TTestCase_Parse_Router_Fallback`
3) 输出：`N:3 E:0 F:3`（RED 命中）。

### Phase-2 GREEN
1) 修改 `src/fafafa.core.toml.pas` 的 `Parse` 路由：默认走 V1，`trfUseV2` 显式才走 V2。  
2) 复跑同 suite：
- 输出：`N:3 E:0 F:0`。

### Phase-3 回归
1) Unicode 目标簇回归：
- `TTestCase_Unicode_Escapes`: `N:2 E:0 F:0`
- `TTestCase_Unicode_Negatives`: `N:4 E:0 F:0`
- `TTestCase_Unicode_Negatives_Ext`: `N:2 E:0 F:0`
- `TTestCase_Unicode_Keys_Negatives`: `N:2 E:0 F:0`
- `TTestCase_Unicode_Keys_Regression`: `N:10 E:0 F:0`

2) 全量快照：
- `./bin/tests_toml --all --format=plain --sparse`
- 执行前：`N:122 E:0 F:34`
- 执行后：`N:125 E:0 F:5`
- 结论：失败数下降 `29`，且无新增 `E`（errors）。
