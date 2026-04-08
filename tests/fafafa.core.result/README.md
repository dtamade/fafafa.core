# fafafa.core.result Tests

这个目录是 `fafafa.core.result` 当前测试入口。它负责锁定 strict non-SIMD L0 `result` 模块的 today contract，不再把历史 Windows wrapper/alias 分层误当成额外语义。

## 当前 source-of-truth

1. `docs/fafafa.core.result.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.result/BuildOrTest.sh`
6. `tests/fafafa.core.result/BuildOrTest.bat`
7. `tests/fafafa.core.result/fafafa.core.result.test.lpi`
8. `tests/fafafa.core.result/tests_result.lpi`
9. `tests/fafafa.core.result/fafafa.core.result.testcase.pas`

## 当前测试集合

当前目录主要分成三组：

- 主测试工程
  - `fafafa.core.result.test.lpi` / `.lpr`
  - `tests_result.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.result.testcase.pas`
- 辅助最小程序
  - `test_basic_result.pas`
  - `test_option_basic.pas`
  - `test_option_init_debug.pas`

补充说明：

- `fafafa.core.result.testcase.pas` 当前会继续覆盖 `AndResult` / `OrResult` 这组 deprecated compatibility API，确保平滑迁移路径不会被误伤。
- 兼容 API 的 deprecated warning 只在对应 legacy 调用点附近做局部抑制，避免 build log 噪音掩盖真正的当前合同回归。

## 当前推荐入口

- Windows：`tests\\fafafa.core.result\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.result/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.result/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.result.test.lpi`
- 产物：`bin/fafafa.core.result.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.result.test.lpi`
- 产物：`bin\\fafafa.core.result.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 当前 shell / Windows root runner 都围绕 `fafafa.core.result.test.lpi -> bin/fafafa.core.result.test[.exe]` 这一条 today contract。
- `tests_result.lpi` / `.lpr` 仍是同目录 sidecar 测试工程，不应被误读为仓库级默认入口。
- 根测试目录代表今天的主验证入口，不再让辅助最小程序或产物目录冒充当前合同。
- 新代码仍应优先使用 `And_` / `Or_`；README 提到的 `AndResult` / `OrResult` 兼容覆盖，不等于把它们恢复成 today contract。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
