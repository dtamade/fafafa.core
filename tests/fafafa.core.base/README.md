# fafafa.core.base Tests

这个目录是 `fafafa.core.base` 当前测试入口。它负责锁定 strict non-SIMD L0 `base` 模块的 today contract，而不是替代更高层 consumer 或 guide 示例验证。

## 当前 source-of-truth

1. `docs/fafafa.core.base.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.base/BuildOrTest.sh`
6. `tests/fafafa.core.base/BuildOrTest.bat`
7. `tests/fafafa.core.base/fafafa.core.base.test.lpi`
8. `tests/fafafa.core.base/fafafa.core.base.testcase.pas`

## 当前测试集合

当前目录主要分成两组：

- 主测试工程
  - `fafafa.core.base.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.base.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.base\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.base/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.base/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.base.test.lpi`
- 产物：`bin/fafafa.core.base.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.base.test.lpi`
- 产物：`bin\\fafafa.core.base.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`
- `test` 当前会优先执行 `bin\\fafafa.core.base.test.exe`；只有 `.exe` 不存在时才回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 且 `ACTION=test` 时会跳过构建，直接进入 runtime 路径；这个入口当前主要供 Windows `.bat` runtime-only parity smoke / matrix 使用

## 当前边界

- 这个目录只覆盖 `base` 模块根测试入口，不负责 `option` / `result` 等上层基础原语的测试入口。
- `bin/`、`lib/`、`logs/` 是产物目录，不应被当成当前合同。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
