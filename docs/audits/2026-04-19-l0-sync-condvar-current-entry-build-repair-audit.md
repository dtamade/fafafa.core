# 2026-04-19 L0 Sync Condvar Current-Entry Build Repair Audit

## Scope

- 修复 `examples/fafafa.core.sync.condvar` 的 current-entry build 链路
- 收口默认 `BuildOrRun.sh` 运行路径中的 `barrier` 线程生命周期错误
- 吸收一个最小 root-level verification：`bash tests/test_l0_sync_condvar_current_example_build.sh`
- 保持范围只在 `examples/fafafa.core.sync.condvar` current-entry，不打开 sidecar 那批 runner hygiene absorb

## Why this slice

fresh review 说明 `sync/condvar` 那组 sidecar scripts 目前不能独立吸收，但也同时暴露出 current-entry 自己确实是坏的：

- `BuildOrRun.sh` 带 CRLF，`bash -n` 直接报错
- current runner 强绑 `--build-mode=Release`，而这 7 个 condvar 子项目只有 `Default`
- 7 个 `.lpi` 都把主单元指到了 `bin/...`，导致 `lazbuild` 直接编译失败
- 部分示例源码还停留在 `IConditionVariable` / `MakeConditionVariable` / `MakeSemaphore` 这类旧命名

因此这轮不吸 sidecar 大包，只把 `examples/fafafa.core.sync.condvar` 自己修回 today current-entry。

## What changed

- `examples/fafafa.core.sync.condvar/BuildOrRun.sh`
  - 归一为 LF shell
  - 去掉不存在的 `Release` build mode 依赖
- `examples/fafafa.core.sync.condvar/BuildOrRun.bat`
  - 同步去掉 `Release` build mode 强绑
- `examples/fafafa.core.sync.condvar/*.lpi`
  - 修正 7 个子项目的主单元路径
- `examples/fafafa.core.sync.condvar/*/*.lpr`
  - 切到当前 `ICondVar` / `MakeCondVar` / `MakeSem`
  - Unix 下统一使用 `MakePthreadMutex`
  - 修正 `barrier` 示例里匿名线程的 `FreeOnTerminate` 所有权，避免默认 `run` 路径触发 double free
- `examples/fafafa.core.sync.condvar/README.md`
  - 改成 current-entry 叙事
- `tests/test_l0_sync_condvar_current_example_build.sh`
  - 固定验证 `bash examples/fafafa.core.sync.condvar/BuildOrRun.sh build`
  - 对齐 `example_sync` 守门脚本风格：缺少 `lazbuild` 时跳过，并显式校验 7 个可执行产物

## Explicit non-goals

- 不吸收 `tests/test_l0_sync_condvar_example_runner_hygiene.sh`
- 不吸收 `tests/test_l0_sync_example_runner_hygiene.sh`
- 不吸收 `tests/test_l0_sync_test_runner_hygiene.sh`
- 不删除子目录遗留 `buildOrTest.bat`
- 不把 `examples/fafafa.core.sync*` 整体转成 sidecar 那套 runner hygiene today contract

## Verification

```bash
bash tests/test_l0_sync_condvar_current_example_build.sh
bash examples/fafafa.core.sync.condvar/BuildOrRun.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

`examples/fafafa.core.sync.condvar` 这条 current-entry 已经从“runner / project / source 三层同时失配”恢复为可构建、可运行状态，并且有了独立 build 守门脚本。`sync/condvar` 的 sidecar runner hygiene residue 仍然 defer，后续要推进时应继续按专题切片，而不是 broad absorb。
