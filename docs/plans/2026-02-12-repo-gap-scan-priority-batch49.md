# Repo Gap Scan Priority Batch-49 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于 2026-02-12 最新全仓扫描结果，优先收敛 `yaml` 文档/发射器真实能力缺口（从 stub 返回 `nil` 提升到最小可用句柄），并以严格 TDD 完成可验证闭环。

**Architecture:** 先做全仓缺口分级，锁定 `yaml` 可执行 P0（测试已有 TODO 注释且实现为 stub）；执行时按 RED -> GREEN -> 回归，采用“最小实现”策略：仅保证 `yaml_document_create/build_from_string` 与 `yaml_emitter_create` 返回非空句柄，`destroy` 可安全释放，`emit_document(nil,...)` 语义保持不变。

**Tech Stack:** FreePascal 3.3.x、FPCUnit、`tests/fafafa.core.yaml/fafafa.core.yaml.test.lpr`、`src/fafafa.core.yaml.impl.pas`。

---

## 全仓扫描快照（2026-02-12）
- `rg --files src tests examples benchmarks docs | wc -l` => `4814`
- `rg -n --glob 'src/**/*.pas' "TODO|FIXME|未实现|待实现|暂未|placeholder" | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `64`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

## 优先级
- `P0` `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`：Document/Emitter 两处 TODO（现有实现为 stub，能形成短链 TDD）。
- `P1` `tests/fafafa.core.sync.sem`：增强测试可编译性被 `fafafa.core.sync.sem.testcase.pas` 非法字符阻塞。
- `P2` `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`：历史旧文件占位密集但非主执行入口。

---

### Task 1: YamlDocument 句柄能力（RED -> GREEN）

**Files:**
- Modify: `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`
- Modify: `src/fafafa.core.yaml.impl.pas`

**Step 1: Write the failing test**
- 将以下断言从 TODO/stub 语义切换到真实语义：
  - `TTestCase_YamlDocument.Test_yaml_document_create_destroy` 断言 `yaml_document_create(@cfg)` 非空。
  - `TTestCase_YamlDocument.Test_yaml_document_build_from_string` 断言非空。
  - `TTestCase_YamlNode.Test_yaml_node_basic_operations` 对上述两条路径改为非空断言。

**Step 2: Run test to verify it fails**
Run:
- `cd tests/fafafa.core.yaml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. -Fuhelpers fafafa.core.yaml.test.lpr`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlDocument`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlNode.Test_yaml_node_basic_operations`

Expected:
- `TTestCase_YamlDocument` / `TTestCase_YamlNode...basic...` 至少 1 个失败（文档句柄仍为 `nil`）。

**Step 3: Write minimal implementation**
- 在 `src/fafafa.core.yaml.impl.pas` 实现最小可用：
  - `yaml_impl_document_create`：分配并零初始化 `TFyDocument`。
  - `yaml_impl_document_build_from_string`：对非空输入返回新分配文档。
  - `yaml_impl_document_build_from_file`：文件存在时返回新分配文档。
  - `yaml_impl_document_destroy`：安全释放（允许 `nil`）。

**Step 4: Run test to verify it passes**
Run:
- `cd tests/fafafa.core.yaml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. -Fuhelpers fafafa.core.yaml.test.lpr`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlDocument`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlNode.Test_yaml_node_basic_operations`

Expected:
- 上述 suite 全部 `E:0 F:0`。

### Task 2: YamlEmitter 句柄能力（RED -> GREEN）

**Files:**
- Modify: `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`
- Modify: `src/fafafa.core.yaml.impl.pas`

**Step 1: Write the failing test**
- `TTestCase_YamlEmitter.Test_yaml_emitter_create_destroy` 改为断言 `yaml_emitter_create(@cfg)` 非空。
- `TTestCase_YamlEmitter.Test_yaml_emit_document` 的 emitter 创建断言改为非空（保留 `yaml_emit_document(nil,...)` 返回 `nil` 且 `len=0`）。

**Step 2: Run test to verify it fails**
Run:
- `cd tests/fafafa.core.yaml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. -Fuhelpers fafafa.core.yaml.test.lpr`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlEmitter`

Expected:
- `TTestCase_YamlEmitter` 至少 1 个失败（emitter 仍为 `nil`）。

**Step 3: Write minimal implementation**
- 在 `src/fafafa.core.yaml.impl.pas` 实现最小可用：
  - `yaml_impl_emitter_create`：分配并零初始化 `TFyEmitter`。
  - `yaml_impl_emitter_destroy`：安全释放（允许 `nil`）。
  - `yaml_impl_emit_document`：保持当前 nil 输出语义。

**Step 4: Run test to verify it passes**
Run:
- `cd tests/fafafa.core.yaml && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. -Fuhelpers fafafa.core.yaml.test.lpr`
- `./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlEmitter`

Expected:
- `TTestCase_YamlEmitter` => `E:0 F:0`。

### Task 3: 回归与证据归档

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: Run targeted regression**
Run:
- `cd tests/fafafa.core.yaml && ./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlDocument`
- `cd tests/fafafa.core.yaml && ./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlNode`
- `cd tests/fafafa.core.yaml && ./bin/fafafa.core.yaml.test --format=plain --suite=TTestCase_YamlEmitter`

**Step 2: Run module smoke snapshot**
Run:
- `cd tests/fafafa.core.yaml && ./bin/fafafa.core.yaml.test --all --format=plain --sparse`

**Step 3: Update planning files with outputs**
- 在 `task_plan.md/findings.md/progress.md` 记录：扫描结果、RED/GREEN 命令、关键输出、剩余风险。
