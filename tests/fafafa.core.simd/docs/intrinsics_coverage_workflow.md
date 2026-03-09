# SIMD Intrinsics 覆盖检查工作流

## 目标

为 `sse/mmx` intrinsics 建立“接口声明 ↔ 测试用例”直接映射检查，避免后续迭代出现新增接口未补测试的情况。

## 检查脚本

- 脚本：`tests/fafafa.core.simd/check_intrinsics_coverage.py`
- 检查范围：
  - `src/fafafa.core.simd.intrinsics.sse.pas`
  - `src/fafafa.core.simd.intrinsics.mmx.pas`
  - 对应 `tests/*intrinsics*.testcase.pas` 中的 `Test_<intrinsic>`

脚本输出字段：

- `declared`：接口声明数
- `tested`：测试名覆盖数
- `missing`：声明存在但缺少同名测试
- `extra`：测试存在但无同名声明（通常是组合/别名测试）

> 判定规则：`missing > 0` 时返回非零（失败）。

## 运行方式

### Linux/macOS

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh coverage
```

### Windows

```bat
tests\fafafa.core.simd\buildOrTest.bat coverage
```

## 与 gate 的关系

当前默认 `gate` 已启用基础覆盖检查（`SIMD_GATE_COVERAGE=1`）。

如需临时关闭或调整 gate 内覆盖行为，可使用开关：

### Linux/macOS

```bash
SIMD_GATE_COVERAGE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

### Windows

```bat
set SIMD_GATE_COVERAGE=0 && tests\fafafa.core.simd\buildOrTest.bat gate
```

## 建议的长期执行顺序

1. `coverage`（接口-测试映射）
2. `test --suite=TTestCase_AdvancedAlgorithms`（关键正确性）
3. `perf-smoke`（性能烟测）
4. `gate`（全链路门禁）

这样可以在“结构完整性 → 正确性 → 性能 → 门禁”顺序上尽早发现问题。


## `strict-extra` 模式

默认模式仅要求 `missing=0`。

如需把 `extra`（测试名无同名声明）也作为失败条件，可启用 strict 模式。

当前基线（2026-02-08）：`sse/mmx` 已达到 `missing=0, extra=0`，可按需要在 CI 默认启用 strict-extra。

### Linux/macOS

```bash
SIMD_COVERAGE_STRICT_EXTRA=1 bash tests/fafafa.core.simd/BuildOrTest.sh coverage
```

### Windows

```bat
set SIMD_COVERAGE_STRICT_EXTRA=1 && tests\fafafa.core.simd\buildOrTest.bat coverage
```




## Linux 证据一键收集

可通过 `evidence-linux` action 串行收集一批完整证据（coverage/strict/advanced/perf/gate）：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

输出目录：`tests/fafafa.core.simd/logs/evidence-<timestamp>/`
摘要文件：`summary.md`



## Wiring 对账与门禁摘要

`non-x86` 的 wiring 对账支持独立运行与门禁内可选强约束。

### Linux/macOS

```bash
# 独立对账（strict）
SIMD_WIRING_SYNC_STRICT_EXTRA=1 bash tests/fafafa.core.simd/BuildOrTest.sh wiring-sync

# check 阶段附加对账
SIMD_CHECK_WIRING_SYNC=1 SIMD_WIRING_SYNC_STRICT_EXTRA=1 bash tests/fafafa.core.simd/BuildOrTest.sh check

# gate 阶段附加对账并生成摘要
SIMD_GATE_WIRING_SYNC=1 SIMD_WIRING_SYNC_STRICT_EXTRA=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate

# 查看 gate 摘要
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary
```

默认产物：
- 文本日志：`tests/fafafa.core.simd/logs/wiring_sync.txt`
- JSON 快照：`tests/fafafa.core.simd/logs/wiring_sync.json`
- gate 摘要：`tests/fafafa.core.simd/logs/gate_summary.md`
- `gate_summary.md` 列：`Time / Step / Status / DurationMs / Event / Detail / Artifacts`
- 事件标记：`NORMAL / SLOW_WARN / SLOW_FAIL / FAILED / SKIP`
- 阈值：`SIMD_GATE_STEP_WARN_MS`（默认 20000）与 `SIMD_GATE_STEP_FAIL_MS`（默认 120000）

### Windows

```bat
tests\fafafa.core.simd\buildOrTest.bat wiring-sync
set SIMD_CHECK_WIRING_SYNC=1 && tests\fafafa.core.simd\buildOrTest.bat check
set SIMD_GATE_WIRING_SYNC=1 && tests\fafafa.core.simd\buildOrTest.bat gate
tests\fafafa.core.simd\buildOrTest.bat gate-summary
```


### gate 失败链路记录（Linux）

`BuildOrTest.sh gate` 会将关键步骤写入 `gate_summary.md`，包含 `PASS/FAIL/SKIP`。当某一步失败时，会记录失败步骤与错误码，便于快速定位。

可选参数：
- `SIMD_GATE_SUMMARY_FILE`：自定义摘要文件路径
- `SIMD_GATE_SUMMARY_APPEND=1`：追加到已有摘要（默认每次 gate 重置摘要）
- `SIMD_GATE_SUMMARY_TAIL=120`：`gate-summary` 查看尾部行数
- `SIMD_WIRING_SYNC_JSON=0`：关闭 wiring-sync JSON 快照生成
- `SIMD_GATE_SUMMARY_FILTER=ALL|FAIL|SLOW`：`gate-summary` 视图过滤（默认 `ALL`）
- `SIMD_GATE_SUMMARY_JSON=1`：导出 machine-readable 摘要 JSON
- `SIMD_GATE_SUMMARY_JSON_FILE`：自定义摘要 JSON 路径（默认 `tests/fafafa.core.simd/logs/gate_summary.json`）
- `BuildOrTest.sh gate-summary-selfcheck`：快速自检 gate-summary 过滤/导出能力
- 共享导出器：`tests/fafafa.core.simd/export_gate_summary_json.py`
- `SIMD_GATE_SUMMARY_MAX_DETAIL=260`：限制 detail 长度，避免超长表格
- `SIMD_GATE_SUMMARY_APPLY=1`：`gate-summary-inject` 将样本覆盖到当前摘要（默认非侵入 shadow）
- `SIMD_GATE_SUMMARY_BACKUP_FILE=<path>`：`gate-summary-rollback` 指定回滚备份文件
- 失败传播语义：`gate` 对步骤采用 fail-fast，首个失败 step 会立即终止 gate 并写入 `failed-step=<step>`
- 强制失败演练：`LAZBUILD=/nonexistent bash tests/fafafa.core.simd/BuildOrTest.sh gate`（用于验证失败链路记录）


## gate-summary 诊断手册（Linux）

### 快速查看失败步骤

```bash
SIMD_GATE_SUMMARY_FILTER=FAIL bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary
```

### 快速查看慢步骤

```bash
SIMD_GATE_SUMMARY_FILTER=SLOW bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary
```

### 导出 JSON 给脚本消费

```bash
SIMD_GATE_SUMMARY_FILTER=FAIL SIMD_GATE_SUMMARY_JSON=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary
```

输出：`tests/fafafa.core.simd/logs/gate_summary.json`

### 排障建议

1. 先看 `FAIL` 视图定位首个失败 step。  
2. 再看 `SLOW` 视图识别慢链路（`SLOW_WARN/SLOW_FAIL`）。  
3. 用 `Artifacts` 列直接跳转相关日志（`build.txt/test.txt/wiring_sync*.txt/json`、`run_all_tests_summary_sh.txt`）。  
4. 如 detail 过长，用 `SIMD_GATE_SUMMARY_MAX_DETAIL` 控制摘要长度。  


### gate-summary 自检（Linux）

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck
```

用途：在不跑全量 gate 的情况下，快速验证 `ALL/FAIL/SLOW` 过滤与 JSON 导出链路是否可用。

### freeze-status 自检（Linux）

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal
```

用途：在本地构造“NOT READY/READY”双场景，验证冻结判定逻辑不会回归。


### gate-summary 样本与阈值演练（Linux）

```bash
# 生成可控 FAIL 样本
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-sample fail

# 生成可控 SLOW 样本
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-sample slow

# 执行阈值回归演练（FAIL/SLOW/JSON）
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-rehearsal
```

可选阈值参数（演练脚本）：
- `SIMD_REHEARSAL_WARN_MS`（默认 `10000`）
- `SIMD_REHEARSAL_FAIL_MS`（默认 `15000`）

演练产物目录：`tests/fafafa.core.simd/logs/rehearsal/`


### gate-summary 样本与阈值演练（Windows 脚本层）

```bat
:: 生成样本
set SIMD_GATE_STEP_WARN_MS=10000 && set SIMD_GATE_STEP_FAIL_MS=15000 && tests\fafafa.core.simd\buildOrTest.bat gate-summary-sample slow

:: 运行演练（依赖 bash）
tests\fafafa.core.simd\buildOrTest.bat gate-summary-rehearsal
```


### 非侵入式注入与一键回滚（Linux）

```bash
# 1) 非侵入式注入（默认只生成样本，不改当前 gate_summary.md）
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-inject fail

# 2) 应用注入（先备份再覆盖）
SIMD_GATE_SUMMARY_APPLY=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-inject slow

# 3) 查看备份列表
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-backups

# 4) 一键回滚（默认恢复最新备份）
bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-rollback
```

脚本：
- `tests/fafafa.core.simd/inject_gate_summary_sample.sh`
- `tests/fafafa.core.simd/rollback_gate_summary_sample.sh`
- `tests/fafafa.core.simd/list_gate_summary_backups.sh`


### 非侵入式注入与一键回滚（Windows 脚本层）

```bat
:: 非侵入式注入（默认）
tests\fafafa.core.simd\buildOrTest.bat gate-summary-inject fail

:: 应用注入（覆盖前自动备份）
set SIMD_GATE_SUMMARY_APPLY=1 && tests\fafafa.core.simd\buildOrTest.bat gate-summary-inject slow

:: 查看备份
tests\fafafa.core.simd\buildOrTest.bat gate-summary-backups

:: 回滚最近备份
tests\fafafa.core.simd\buildOrTest.bat gate-summary-rollback
```
