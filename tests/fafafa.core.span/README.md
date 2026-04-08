# fafafa.core.span Tests

这个目录是 `fafafa.core.span` 当前测试入口。它负责锁定 strict non-SIMD L0 `span` 模块的 today contract，而不是替代 collections 域的容器 `SliceView` 语义测试。

## 当前 source-of-truth

1. `docs/fafafa.core.span.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.span/BuildOrTest.sh`
6. `tests/fafafa.core.span/BuildOrTest.bat`
7. `tests/fafafa.core.span/fafafa.core.span.test.lpi`
8. `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

## 当前测试集合

- 主测试工程
  - `fafafa.core.span.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.span.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.span\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.span/BuildOrTest.sh test`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.span.test.lpi`
- 产物：`bin/fafafa.core.span.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.span.test.lpi`
- 产物：`bin\\fafafa.core.span.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`

## 当前边界

- 这里锁定的是最小只读 `span` / `span2` contract，不替代 `collections.slice` 的 today semantics。
- `collections.slice` 里的容器 `SliceView`、裁剪行为和更宽的 collections 语义仍属于 Layer 1，不在当前 L0 `span` 入口里。
- `platform` 虽然也是 strict L0 模块，但有自己的独立测试入口，不属于这里的测试职责。
