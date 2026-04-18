# 2026-04-19 L0 Closeout/Rescue Final 10-Path Stale-Skip Audit

这份审计只处理 `closeout/rescue` fresh shortlist 里最后一簇真实候选，并继续坚持三条纪律：

- 不 broad absorb retained refs
- 不删除 retained refs
- 不碰 SIMD lane

## Scope

这轮 fresh `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 暴露出来的两条 retained ref 候选完全相同，都是下面这 10 个路径：

- `src/fafafa.core.env.pas`
- `src/fafafa.core.os.unix.inc`
- `src/fafafa.core.sync.mutex.pas`
- `examples/fafafa.core.json/example_json.lpi`
- `examples/fafafa.core.json/example_json.lpr`
- `examples/fafafa.core.json/example_reader_flags.lpi`
- `examples/fafafa.core.json/example_stop_when_done.lpi`
- `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpi`
- `examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr`
- `examples/fafafa.core.sync.mutex/example_basic_usage.lpi`

## Decision

这 10 个路径全部下沉到 `review_skip_paths=`，不做 absorb。

## Why these paths are stale or no-absorb

### Keep the older-FPC conditional-compile subset

`src/fafafa.core.env.pas`、`src/fafafa.core.os.unix.inc` 和 `src/fafafa.core.sync.mutex.pas` 的 retained diff，都会把当前主线刻意保留的嵌套 `{$IFDEF}` / `{$ELSE}` / `{$ENDIF}` 结构改回 `{$ELSEIF}`。

这不是 today contract 的增强，而是对 strict L0 older-FPC compatibility 的回退。当前主线已经用下面这条 contract 明确锁住这个约束：

```bash
bash tests/test_os_unix_ifdef_elseif_compat_contract.sh
```

### Keep the sync.mutex advanced example on explicit thread classes

`examples/fafafa.core.sync.mutex/example_advanced_patterns.lpr` 的 retained diff 会把当前显式 `TQueueProducerThread` / `TQueueConsumerThread` worker 类改回 `CreateAnonymousThread` 版本。

这同样不是 today contract 的增强。当前主线已经用下面这条 contract 固定：`sync.mutex` advanced example 继续保留显式线程类，避免 older-FPC compatibility 回退。

```bash
bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh
```

同时，`examples/fafafa.core.sync.mutex/example_advanced_patterns.lpi` 与 `examples/fafafa.core.sync.mutex/example_basic_usage.lpi` 的 retained diff 还会把 `<Units>` 里的主单元条目写成 `bin/example_*`，而不是 `.lpr` 源文件。这是 project entry 的结构性回退，不应吸收。

### Keep JSON and sync.mutex examples on the current smoke-verified entry

这 7 个 example diff 当前都落在 strict L0 examples smoke 的守门范围内：

```bash
bash tests/test_strict_l0_examples_smoke_contract.sh
```

这意味着 examples current-entry 已经由主线 `BuildOrRun*`、`.lpr` 和 `.lpi` 组合在持续守住，不需要再从 retained refs 回灌旧版本。

具体来说：

- `examples/fafafa.core.json/example_reader_flags.lpi`
- `examples/fafafa.core.json/example_stop_when_done.lpi`

它们的 retained diff 只是把当前跨平台可用的 `../../src` / `lib/$(TargetCPU)-$(TargetOS)` 写回 Windows 反斜杠路径。这对当前 Linux x64 current-entry 是直接回退。

- `examples/fafafa.core.json/example_json.lpr`

  retained diff 会把当前 example source 改回较旧的 API/ownership 写法，不构成 current-entry 增量。

- `examples/fafafa.core.json/example_json.lpi`

  retained diff 会把当前项目结构改回 older layout，不能证明 today contract 更正确。

## Fresh result after reclassification

fresh 命令：

```bash
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
```

这轮之后，fresh 输出已经再次回到：

- `closeout.review_candidate_paths=0`
- `rescue.review_candidate_paths=0`

但 current-entry 仍继续以 fresh 输出为准，而不是把任何历史 clearout 审计当成永久真值。

## Verification

Run:

```bash
bash tests/test_os_unix_ifdef_elseif_compat_contract.sh
bash tests/test_strict_l0_sync_mutex_example_older_fpc_contract.sh
bash tests/test_strict_l0_examples_smoke_contract.sh
bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
git diff --check
```
