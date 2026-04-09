# fafafa.core.contracts Tests

这个目录是 `fafafa.core.contracts` 当前测试入口。它负责锁定 strict L0 `contracts` helper 的 today contract，而不是替代各模块自己的业务/状态语义测试。

## 当前 source-of-truth

1. `docs/fafafa.core.contracts.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.contracts/BuildOrTest.sh`
6. `tests/fafafa.core.contracts/BuildOrTest.bat`
7. `tests/fafafa.core.contracts/fafafa.core.contracts.test.lpi`
8. `tests/fafafa.core.contracts/fafafa.core.contracts.testcase.pas`

## 当前测试集合

- 主测试工程
  - `fafafa.core.contracts.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.contracts.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.contracts\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.contracts/BuildOrTest.sh test`

如果你要验证关闭 contracts 开关后的 smoke：

- Linux/macOS：`bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts`
- Windows：`tests\\fafafa.core.contracts\\BuildOrTest.bat test-no-contracts`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 默认以 `Debug` build mode 构建并运行 `fafafa.core.contracts.test.lpi`
- `test-no-contracts` / `check-no-contracts` 会切到 `NoContracts` build mode
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts`
- `check` / `test` 系列都会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 系列还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.contracts.test.lpi`
- 支持 `Debug` / `NoContracts` 两个 build mode
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts` / `clean` / `rebuild`
- `test` / `test-no-contracts` 当前会优先执行显式 `.exe`；只有 `.exe` 不存在时才回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 时，`test` / `test-no-contracts` 会跳过构建，直接进入 runtime 路径；这个入口当前主要供 Windows `.bat` runtime-only parity smoke / matrix 使用

## 当前边界

- 这里锁定的是 strict L0 的前置条件 helper，只负责 `EArgumentNil` / `EInvalidArgument` 这一层的统一入口。
- 这里不替代 `atomic` / `result` 中的内部 invariant `Assert`。
- 这里不承载 `platform` 或其他 L0 模块边界讨论；`span` 已经是同层 L0 模块，但不属于本目录职责。
