# fafafa.core.mem.allocator.foundation Tests

这个目录是 `fafafa.core.mem.allocator.foundation` 的当前测试入口。它负责说明 mem 域低层 allocator facade 的 root runner、Windows wrapper，以及它和 `tests/fafafa.core.mem/`、`tests/fafafa.core.mem.manager.rtl/` 之间的边界。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `docs/fafafa.core.mem.md`
4. `src/fafafa.core.mem.allocator.base.pas`
5. `src/fafafa.core.mem.allocator.foundation.pas`
6. `tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh`
7. `tests/fafafa.core.mem.allocator.foundation/BuildOrTest.bat`
8. `tests/fafafa.core.mem.allocator.foundation/buildOrTest.bat`
9. `tests/fafafa.core.mem.allocator.foundation/fafafa.core.mem.allocator.foundation.test.lpi`

## 当前测试集合

当前目录主要分成两组：

- 主测试工程
  - `fafafa.core.mem.allocator.foundation.test.lpi` / `.lpr`
- 常规 testcase
  - `test_allocator_foundation_contract.pas`
  - `test_allocator_foundation_runtime.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.mem.allocator.foundation\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test`

如果你要验证关闭 contracts 开关后的 smoke：

- Windows：`tests\\fafafa.core.mem.allocator.foundation\\BuildOrTest.bat test-no-contracts`
- Linux/macOS：`bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test-no-contracts`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 默认以 `Debug` build mode 构建 `fafafa.core.mem.allocator.foundation.test.lpi`
- `test-no-contracts` / `check-no-contracts` 会切到 `NoContracts` build mode
- 产物：`bin/fafafa.core.mem.allocator.foundation.test_debug[.exe]` 或 `bin/fafafa.core.mem.allocator.foundation.test_nocontracts[.exe]`
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts`
- `check` / `test` 会检查 strict L0 allocator 相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 当前是 Windows root wrapper
- 会委托给 `buildOrTest.bat`
- 目的是让 `tests/run_all_tests.bat` 可以发现 strict L0 allocator 当前入口

### buildOrTest.bat

- 支持 `Debug` / `NoContracts` 两个 build mode
- 产物：`bin\\fafafa.core.mem.allocator.foundation.test_debug[.exe]` 或 `bin\\fafafa.core.mem.allocator.foundation.test_nocontracts[.exe]`
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts` / `clean` / `rebuild`

## 当前边界

- `fafafa.core.mem.allocator.base` 才是 strict L0 allocator contract 的 source-of-truth；这个目录负责验证该 contract 在 mem 域低层 facade 中的可用形态。
- 这个目录只覆盖 allocator contract + 小型 concrete backend 的 mem 域低层 facade，不负责 `mimalloc` / `crtAllocator` 这类可选后端集成测试。
- `tests/fafafa.core.mem/` 仍负责 broader mem 域入口；`tests/fafafa.core.mem.manager.rtl/` 仍负责 RTL allocator manager 的专项验证。
- callback allocator 的 nil callback 行为跟随 `fafafa.core.contracts`：默认构建抛 `EArgumentNil`，`NoContracts` 下只保证 smoke 可运行，不再承诺 friendly exception。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
