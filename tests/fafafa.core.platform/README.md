# fafafa.core.platform Tests

这个目录是 `fafafa.core.platform` 的当前测试入口。它锁定最小静态 platform contract，只验证 target OS / arch / pointer width / endianness 这组编译期事实。

## 当前 source-of-truth

1. `docs/fafafa.core.platform.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/ARCHITECTURE_LAYERS.md`
5. `src/fafafa.core.platform.pas`
6. `tests/fafafa.core.platform/BuildOrTest.sh`
7. `tests/fafafa.core.platform/BuildOrTest.bat`
8. `tests/fafafa.core.platform/fafafa.core.platform.test.lpi`
9. `tests/fafafa.core.platform/fafafa.core.platform.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.platform\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.platform/BuildOrTest.sh test`

如果你只想复核 Windows `.bat` runtime-only parity：

- Linux/macOS：`bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`

## 当前脚本行为

### BuildOrTest.sh

- 使用 `tools/lazbuild.sh` 或 PATH 中的 `lazbuild`
- 构建目标：`fafafa.core.platform.test.lpi`
- 产物：`bin/fafafa.core.platform.test[.exe]`
- 支持 `build` / `check` / `test`
- `check` / `test` 会检查 build log 中当前模块相关 `src/` 的 warning / hint；`test` 还会检查 heaptrc 泄漏输出

### BuildOrTest.bat

- 构建目标：`fafafa.core.platform.test.lpi`
- 产物：`bin\\fafafa.core.platform.test[.exe]`
- 支持 `build` / `check` / `test` / `clean` / `rebuild`
- `test` 当前会优先执行 `bin\\fafafa.core.platform.test.exe`；只有 `.exe` 不存在时才回退到无扩展名产物
- 在 `FAFAFA_SKIP_BUILD=1` 且 `ACTION=test` 时会跳过构建，直接进入 runtime 路径；这个入口当前主要供 Windows `.bat` runtime-only parity smoke 使用

## 当前边界

- 这里只承认静态 target facts：OS、arch、pointer width、endianness、`Is64Bit`。
- `fafafa.core.os` 里的 hostname、user、path、cpu count、page size、capability probe 不属于这里。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
