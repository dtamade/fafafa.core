# fafafa.core.bits Tests

这个目录是 `fafafa.core.bits` 当前测试入口。它负责锁定 strict non-SIMD L0 `bits` 模块的 today contract，而不是替代 compat 或上层 consumer 测试。

## 当前 source-of-truth

1. `docs/fafafa.core.bits.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `tests/fafafa.core.bits/BuildOrTest.sh`
5. `tests/fafafa.core.bits/BuildOrTest.bat`
6. `tests/fafafa.core.bits/fafafa.core.bits.test.lpi`
7. `tests/fafafa.core.bits/fafafa.core.bits.testcase.pas`

## 当前测试集合

- 主测试工程
  - `fafafa.core.bits.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.bits.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.bits\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.bits/BuildOrTest.sh test`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.bits.test.lpi`
- 产物：`bin/fafafa.core.bits.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.bits.test.lpi`
- 产物：`bin\\fafafa.core.bits.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 这个目录只覆盖 `bits` 的 L0 契约，不替代 `math` 或 `mem` 的兼容层测试。
- `src/fafafa.core.math.intutil.pas` 继续承担 compat 角色，但 `bits` 的 today contract 以 `docs/fafafa.core.bits.md` 和当前测试入口为准。
- 这里不承载 `platform` / `span` 的候选讨论；那是后续 L0 准入问题，不属于 `bits` 当前测试入口。
- `bin/`、`lib/`、`logs/` 是产物目录，不属于合同本体。
