# fafafa.core.atomic Tests

这个目录是 `fafafa.core.atomic` 当前测试入口。它负责锁定 strict non-SIMD L0 `atomic` 家族的 today contract，并说明 shell / Windows 两条 root runner与 compat surface 之间的边界。

## 当前 source-of-truth

1. `docs/fafafa.core.atomic.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.atomic/BuildOrTest.sh`
6. `tests/fafafa.core.atomic/BuildOrTest.bat`
7. `tests/fafafa.core.atomic/tests_atomic.lpi`

## 当前测试集合

当前目录主要分成三组：

- 主测试工程
  - `tests_atomic.lpi` / `.lpr`
- 常规 testcase
  - `Test_fafafa.core.atomic.pas`
  - `Test_fafafa.core.atomic.base.pas`
  - `Test_fafafa.core.atomic.core.contract.pas`
  - `Test_fafafa.core.atomic.contract.pas`
  - `Test_fafafa.core.atomic.compat.contract.pas`
- 支持材料
  - `VerifyMultiArchDocker.sh`
  - `atomic_heaptrc_full_output.txt`

## 当前推荐入口

- Windows：`tests\\fafafa.core.atomic\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.atomic/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.atomic/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`tests_atomic.lpi`
- 产物：`bin/tests_atomic[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`tests_atomic.lpi`
- 产物：`bin\\tests_atomic[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`
- `test` 当前会优先执行 `bin\\tests_atomic.exe`；只有 `.exe` 不存在时才回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 且 `ACTION=test` 时会跳过构建，直接进入 runtime 路径；这个入口当前主要供 Windows `.bat` runtime-only parity smoke / matrix 使用

## 当前边界

- `Test_fafafa.core.atomic.core.contract.pas` 锁定 `fafafa.core.atomic.core` 的最小 L0 contract，不覆盖 raw RMW 语义。
- `Test_fafafa.core.atomic.compat.contract.pas` 只负责锁定 legacy pointer/tagged-pointer helper 仍可用，不代表 `fafafa.core.atomic.compat` 是新代码推荐入口。
- 当前仓库主线 `src/` 已经迁到 `atomic_load/atomic_store/atomic_compare_exchange_strong` 的 Pointer 重载；compat 主要由 legacy bridge 和合同测试覆盖。
- `VerifyMultiArchDocker.sh` 是多架构辅助脚本，不是仓库级 current entry。
- 这个目录只覆盖 `atomic` 域当前根测试入口，不负责更高层模块的聚合 gate。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
