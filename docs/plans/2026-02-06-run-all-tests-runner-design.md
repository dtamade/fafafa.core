# run_all_tests Runner 改进设计

## 背景 / 问题
- `tests/run_all_tests.sh` 当前用“脚本所在目录 basename”作为模块名（例如 `tests/fafafa.core.collections/vec` 会被识别为 `vec`）。
  - 结果：按文档/约定使用 `fafafa.core.collections.vec` 过滤时 **命中 0 个模块**，脚本却仍返回成功（Total=0 / Failed=0 / exit 0），存在“假绿”风险。
- `tests/run_all_tests.sh` 会同时执行 `BuildOrTest.sh` 与 `BuildAndTest.sh`。
  - 当前 `tests/fafafa.core.lockfree/BuildAndTest.sh` 末尾无条件 `read`，全量回归会阻塞。
  - Windows 侧 `tests/run_all_tests.bat` 同理会调用带无条件 `pause` 的 `BuildAndTest.bat`，存在阻塞风险。
- 同一模块目录同时存在 `BuildOrTest.*` 与 `BuildAndTest.*` 时，会重复执行并覆盖日志文件（同名 log）。

## 目标
1. **模块命名一致**：模块名 = `tests/` 下相对目录路径，将 `/` 或 `\\` 转换为 `.`。
   - 例：`tests/fafafa.core.collections/vec` → `fafafa.core.collections.vec`
2. **过滤可靠**：传了过滤参数但 0 命中时，脚本应返回非 0 并明确提示（避免假绿）。
3. **不阻塞**：全量回归默认不执行交互式 `BuildAndTest.*`；同目录优先执行 `BuildOrTest.*`。
4. **兼容旧用法**：仍允许用旧的 basename（如 `vec`）进行过滤（尽量不破坏现有习惯）。

## 方案选项
1. **只更新文档**：把过滤示例改成 `vec`/`vecdeque` 等（不推荐：仍有歧义与假绿风险，且无法解决 BuildAndTest 阻塞）。
2. **改进 run_all_tests 脚本（推荐）**
   - 统一模块名规则；过滤逻辑升级；脚本选择去重并规避 BuildAndTest 阻塞。
3. **增加 wrapper 模块目录**：补 `tests/fafafa.core.collections.arr` 等兼容目录（可选，后续再做；优先先把 runner 修好）。

## 推荐方案（落地）
- `run_all_tests.sh`
  - 枚举模块目录（去重）：若同目录同时存在 `BuildOrTest.sh` 与 `BuildAndTest.sh`，默认只选 `BuildOrTest.sh`。
  - 模块名：目录相对 `tests/` 的路径，`/` → `.`。
  - 过滤命中：支持
    - 精确匹配：`filter == module`
    - 组匹配：`module` 以 `filter.` 开头
    - 兼容匹配：`filter == basename`
  - 过滤但 0 命中：exit 2。
- `run_all_tests.bat`
  - 同样的模块名规则（相对目录 `\\` → `.`）。
  - 避免执行 `BuildAndTest.bat`（或仅在没有 `BuildOrTest.bat` 时作为 fallback）。
  - 过滤但 0 命中：exit /b 2。
- `docs/TESTING.md` 更新示例与模块名规则，避免继续传播错误过滤示例。

## 验证
- Linux/macOS：
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec`：Total=1，且执行 `tests/fafafa.core.collections/vec/BuildOrTest.sh`。
  - `bash tests/run_all_tests.sh __no_such_module__`：exit 2（过滤 0 命中应失败）。
  - `bash tests/run_all_tests.sh`：不因 `lockfree BuildAndTest.sh` 而阻塞。
- Windows：
  - `tests\\run_all_tests.bat fafafa.core.collections.vec`：应能命中并运行对应模块；不应触发 `BuildAndTest.bat` 的 `pause` 阻塞。

