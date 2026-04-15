# fafafa.core.layout Tests

这个目录是 `fafafa.core.layout` 当前测试入口。它负责锁定 strict non-SIMD L0 `layout` 模块的 today contract，而不是替代更高层 allocator / arena / pool 测试。

## 当前 source-of-truth

1. `docs/fafafa.core.layout.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `tests/fafafa.core.layout/BuildOrTest.sh`
6. `tests/fafafa.core.layout/BuildOrTest.bat`
7. `tests/fafafa.core.layout/fafafa.core.layout.test.lpi`
8. `tests/fafafa.core.layout/fafafa.core.layout.testcase.pas`

## 当前测试集合

- 主测试工程
  - `fafafa.core.layout.test.lpi` / `.lpr`
- 常规 testcase
  - `fafafa.core.layout.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.layout\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.layout/BuildOrTest.sh test`
- Linux x64 strict L0 日常维护：`bash tests/run_strict_l0_maintenance_loop.sh`

如果你只想做构建检查：

- Linux/macOS：`bash tests/fafafa.core.layout/BuildOrTest.sh check`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.layout.test.lpi`
- 产物：`bin/fafafa.core.layout.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.layout.test.lpi`
- 产物：`bin\\fafafa.core.layout.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`
- `test` 当前会优先执行 `bin\\fafafa.core.layout.test.exe`；只有 `.exe` 不存在时才回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 且 `ACTION=test` 时会跳过构建，直接进入 runtime 路径；这个入口当前主要供 Windows `.bat` runtime-only parity smoke / matrix 使用

## 当前边界

- 这个目录只锁定 `layout` 的 L0 契约，不替代 `mem` 域更高层的 allocator、arena 和 pool 测试。
- `src/fafafa.core.mem.layout.pas` 继续承担 compat 角色，但布局合同的 today contract 以 `docs/fafafa.core.layout.md` 和当前测试入口为准。
- 这里不承载 `platform` 或其他 L0 准入讨论；那不是 `layout` 当前测试入口的责任边界。
- `bin/`、`lib/`、`logs/` 是产物目录，不属于合同本体。
- exact Windows native evidence 只接受 GitHub Actions 或真实 Windows runner 产物。
