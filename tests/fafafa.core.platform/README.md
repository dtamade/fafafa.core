# fafafa.core.platform Tests

这个目录是 `fafafa.core.platform` 的当前测试入口。它锁定最小静态 platform contract，只验证 target OS / arch / pointer width / endianness 这组编译期事实。

## 当前 source-of-truth

1. `docs/fafafa.core.platform.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.platform.pas`
5. `tests/fafafa.core.platform/BuildOrTest.sh`
6. `tests/fafafa.core.platform/BuildOrTest.bat`
7. `tests/fafafa.core.platform/fafafa.core.platform.test.lpi`
8. `tests/fafafa.core.platform/fafafa.core.platform.testcase.pas`

## 当前推荐入口

- Windows：`tests\\fafafa.core.platform\\BuildOrTest.bat test`
- Linux/macOS：`bash tests/fafafa.core.platform/BuildOrTest.sh test`

## 当前边界

- 这里只承认静态 target facts：OS、arch、pointer width、endianness、`Is64Bit`。
- `fafafa.core.os` 里的 hostname、user、path、cpu count、page size、capability probe 不属于这里。
- 如果 README、脚本和工程文件冲突，以脚本与工程文件现状为准。
