# fafafa.core.endian Tests

这个目录是 `fafafa.core.endian` 当前测试入口。它负责锁定 strict non-SIMD L0 `endian` 模块的 today contract，而不是替代 `bytes` 域更高层的读写与集成测试。

## 当前 source-of-truth

1. `docs/fafafa.core.endian.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `tests/fafafa.core.endian/BuildOrTest.sh`
5. `tests/fafafa.core.endian/BuildOrTest.bat`
6. `tests/fafafa.core.endian/fafafa.core.endian.test.lpi`
7. `tests/fafafa.core.endian/fafafa.core.endian.testcase.pas`

## 当前测试集合

- 主测试工程
  - `fafafa.core.endian.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.endian.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.endian\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.endian/BuildOrTest.sh test`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.endian/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.endian.test.lpi`
- 产物：`bin/fafafa.core.endian.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.endian.test.lpi`
- 产物：`bin\\fafafa.core.endian.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 这个目录只锁定 `endian` 的基础契约，不替代 `bytes` 模块对端序读写接口的集成测试。
- `src/fafafa.core.bytes.pas` 当前会消费 `fafafa.core.endian` 并保留兼容别名，但 `endian` 的 today contract 以 `docs/fafafa.core.endian.md` 和当前测试入口为准。
- 这里不承载 `platform` 或其他 L0 准入讨论；那不属于 `endian` 当前测试职责。
- `bin/`、`lib/`、`logs/` 是产物目录，不属于合同本体。
