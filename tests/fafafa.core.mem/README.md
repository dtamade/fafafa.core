# fafafa.core.mem Tests

这个目录是 mem 域当前测试入口。它负责告诉你应该跑哪套工程、脚本实际做了什么，以及哪些文件只是辅助 runner 或历史残留。
strict L0 allocator contract 的权威边界和推进顺序仍以 `docs/fafafa.core.l0.foundation.md`、`docs/fafafa.core.l0.roadmap.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；这里不替代那组三份稳定文档。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `docs/fafafa.core.mem.md`
5. `tests/fafafa.core.mem.allocator.foundation/README.md`
6. `tests/fafafa.core.mem/tests_mem.lpi`
7. `tests/fafafa.core.mem/tests_mem_allocator_only.lpi`
8. `tests/fafafa.core.mem/BuildOrTest.bat`
9. `tests/fafafa.core.mem/BuildOrTest.sh`

## 当前测试集合

当前目录主要分成四类：

- Lazarus/FPCUnit 工程
  - `tests_mem.lpi` / `tests_mem.lpr`
  - `tests_mem_allocator_only.lpi` / `.lpr`
  - `tests_mem_new.lpr`
- 常规 testcase
  - `test_mem_*`
  - `test_stack*`
  - `test_slab*`
  - `test_blockpool*`
  - `test_mimalloc*`
  - `test_stats.pas`
  - `test_interfaces.pas`
- 辅助 runner
  - `test_*_runner.lpr`
  - `tests_mem_minimal.lpr`
  - `syntax_validation.pas`
- 历史 sidecar
  - `COMPLETION_REPORT.md`
  - `FINAL_STATUS_REPORT.md`

## 当前推荐入口

- Windows：`tests\\fafafa.core.mem\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.mem/BuildOrTest.sh`

如果你要验证关闭 contracts 开关后的 allocator smoke：

- Windows：`tests\\fafafa.core.mem\\BuildOrTest.bat test-no-contracts`
- Linux/macOS：`bash tests/fafafa.core.mem/BuildOrTest.sh test-no-contracts`

如果你需要精确选择工程：

- shell / bat 当前都以 `tests_mem_allocator_only.lpi` 为主入口
- `NoContracts` 模式会把 runner 收窄为 allocator smoke，不再承诺 broader mem 套件全量语义

## 当前脚本行为

### BuildOrTest.bat

- 构建目标：`tests_mem_allocator_only.lpi`
- 支持 `Debug` / `NoContracts` 两个 build mode
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts`
- `NoContracts` 模式当前只锁定 allocator smoke，不替代 full mem regression
- `test` / `test-no-contracts` 当前会优先执行显式 `.exe`，再回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 时，`test` / `test-no-contracts` 会跳过构建，直接消费预构建 Win64 `.exe`；这个入口当前主要供 Windows `.bat` runtime-only parity smoke / matrix 使用

### BuildOrTest.sh

- 构建目标：`tests_mem_allocator_only.lpi`
- 默认以 `Debug` 模式构建；`test-no-contracts` / `check-no-contracts` 会切到 `NoContracts`
- 支持 `build` / `check` / `test` / `build-no-contracts` / `check-no-contracts` / `test-no-contracts`
- `NoContracts` 模式当前只跑 allocator smoke，避免把 contract-sensitive 的 broader mem case 混进来

### 其他脚本

- `BuildAndTest.bat`、`RunAllTests.bat`、`VerifyImprovements.bat` 仍可用于专项验证，但不应替代上面的主入口说明。

## 当前边界

- 这个目录描述的是“现在怎么验证”，不是历史成果展板。
- strict L0 allocator facade 现在有独立入口：`tests/fafafa.core.mem.allocator.foundation/`；这里不再单独承担那部分回归职责。
- callback allocator 的 nil callback 行为跟随 `fafafa.core.contracts`：默认构建抛 `EArgumentNil`，`NoContracts` 只保留 smoke。
- `COMPLETION_REPORT.md` 和 `FINAL_STATUS_REPORT.md` 已退回历史快照，不再代表今天的放行结论。
- 如果测试 README、根文档和源码冲突，以源码和实际脚本行为为准。
