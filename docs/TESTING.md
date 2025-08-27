## 测试执行指南（Windows bat / Linux/macOS sh）

本仓库的各子模块在 tests/ 目录下提供独立的测试脚本。为提高可见性与一致性，新增了统一的“全仓测试”脚本，分别适配 Windows 与 Linux/macOS：

- Windows（批处理）：tests/run_all_tests.bat
- Linux/macOS（Shell）：tests/run_all_tests.sh

它们会递归扫描子模块测试脚本并执行，输出各模块日志与最终汇总。

---

### 先决条件
- Windows：
  - 安装并能通过命令行调用的 Lazarus/FPC（lazbuild/fpc 在 PATH 上，或通过 tests/tools/lazbuild.bat 间接调用）
  - 适配的目标工具链（x86_64-win64 等），与项目各 tests/*.lpi 配置一致
- Linux/macOS：
  - 可执行的 sh/bash 环境
  - 对应平台的 FPC/Lazarus 工具链（若运行依赖 .sh 的子模块）

提示：部分测试运行时间较长或涉及 I/O，请在本地机器先用“关键模块”快速回归，再做全量。

---

### 快速回归（建议每次提交前）
仅运行常用关键模块，并在第一个失败处停止：

- Windows（推荐）：
  - 在仓库根目录执行：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`

- Linux/macOS（推荐）：
  - 在仓库根目录执行：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`

说明：
- 参数为“模块目录名”（tests/ 下的二级目录名），用于过滤只跑这些模块
- 环境变量 STOP_ON_FAIL=1 代表“失败即停”，便于快速定位第一个失败点

---

### 全量回归（每日/版本发布前）
- Windows：`tests\run_all_tests.bat`
- Linux/macOS：`bash tests/run_all_tests.sh`

不传参时，脚本会递归扫描并尝试执行所有符合规范的测试脚本：
- Windows：`BuildOrTest.bat` / `BuildAndTest.bat`
- Linux/macOS：`BuildOrTest.sh` / `BuildAndTest.sh`

建议在 CI 或夜间任务中执行全量回归，便于收敛问题。

---

### 输出位置与返回码
- 汇总文件：
  - Windows：`tests/run_all_tests_summary.txt`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`
- 日志目录：
  - Windows：`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/_run_all_logs_sh/*.log`
- 返回码：
  - 0：所有选中模块执行成功
  - 非 0：存在失败模块（或 STOP_ON_FAIL 触发提前结束）

在控制台看不到明细时，请优先查看上述日志与汇总文件。

---

### 过滤与失败即停
- 仅运行指定模块（示例为 4 个关键模块）：
  - Windows：`tests\run_all_tests.bat fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`
  - Linux/macOS：`bash tests/run_all_tests.sh fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`
- 失败即停：
  - Windows：`set STOP_ON_FAIL=1 && tests\run_all_tests.bat ...`
  - Linux/macOS：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh ...`

---

### 常见问题（FAQ）
1) 控制台没有输出，但返回码为 0/非 0，如何查看详情？
- 查看汇总与日志：
  - Windows：`tests/run_all_tests_summary.txt`、`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`、`tests/_run_all_logs_sh/*.log`

2) 某些测试依赖 lazbuild 路径或工具链，构建失败？
- 确保 Lazarus/FPC 安装完备，并在 PATH 上；或按 tests/*/BuildOrTest.bat 脚本内的工具路径调整
- 优先在本地先跑单一模块进行定位，例如：
  - `tests\fafafa.core.collections.arr\BuildOrTest.bat`

3) 跑全量太慢？
- 提交前仅跑关键模块（上面的 4 个）
- 夜间/CI 跑全量，或分组并行（在 CI 编排层面并发多个 run_all_tests.sh/bat，分别过滤不同模块）

4) 是否有“测试规范命名”？
- 子模块测试脚本建议采用以下之一：`BuildOrTest.bat` / `BuildAndTest.bat`（Windows），`BuildOrTest.sh` / `BuildAndTest.sh`（Linux/macOS）
- 统一脚本会自动发现并执行上述命名脚本

---

### 建议的团队约定
- 每次提交前：关键模块 + 失败即停
- 每晚或合入前：全量回归
- 失败模块：提交日志到评审或 CI 附件，提升可复现性
- 新增测试：按规范命名子模块脚本，确保被统一脚本识别

---

### 典型命令速查
- Windows：
  - 关键模块（失败即停）：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`
  - 全量：
    - `tests\run_all_tests.bat`

- Linux/macOS：
  - 关键模块（失败即停）：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque`
  - 全量：
    - `bash tests/run_all_tests.sh`

