# 2026-04-19 L0 Sync Current Example Build Repair Audit

## Scope

- 修复 `examples/fafafa.core.sync/example_sync.lpr` 对当前 `fafafa.core.sync` API 的兼容性
- 吸收一个最小 root-level verification：`bash tests/test_l0_sync_current_example_build.sh`
- 明确这不是 broad absorb `examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` runner cleanup

## Why this slice

fresh sidecar review 说明那 5 个 sync/condvar verification scripts 目前都不能独立吸收：

- `tests/test_l0_sync_current_example_build.sh` 暴露出 `example_sync.lpr` 仍引用已不存在的 `IsLocked` / `TSpinLock` / `TAutoLock` / `TReadWriteLock`
- 其余 4 个脚本则会把旧 runner alias、CRLF shell、不存在的 `Release` build mode 与错误的 condvar `.lpi` source entry 一起拉进来

因此这轮只做一个真实 current-entry 修复：让 `example_sync.lpi` 再次可编译，并用独立脚本守住它。

## What changed

- `examples/fafafa.core.sync/example_sync.lpr`
  - 改写为当前 API 示例
  - 使用 `MakeMutex` / `MakeSpin` / `MakeRWLock` / `ScopedLock2`
  - 去掉对旧类名和旧状态查询接口的依赖
  - 移除交互式 `ReadLn`
- `tests/test_l0_sync_current_example_build.sh`
  - 固定验证 `lazbuild example_sync.lpi`
  - 要求产出仓库根 `bin/example_sync[.exe]`

## Explicit non-goals

- 不吸收 `tests/test_l0_sync_condvar_current_example_build.sh`
- 不吸收 `tests/test_l0_sync_condvar_example_runner_hygiene.sh`
- 不吸收 `tests/test_l0_sync_example_runner_hygiene.sh`
- 不吸收 `tests/test_l0_sync_test_runner_hygiene.sh`
- 不回灌 `examples/fafafa.core.sync*` / `examples/fafafa.core.sync.condvar*` 的旧 runner cleanup 批次

## Verification

```bash
bash tests/test_l0_sync_current_example_build.sh
bash tests/test_strict_l0_examples_smoke_contract.sh
bash tests/check_strict_l0_docs_consistency.sh
git diff --check
```

## Current conclusion

`example_sync` 这条 current-entry 已经从“示例源码落后于 API”恢复为可编译状态，并有了独立验证脚本。`sync/condvar` 其余 retained slice 继续 defer，后续若要推进，应按 runner/example 专题单独处理，而不是从 sidecar 旧大包直接吸收。
