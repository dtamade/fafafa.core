# fafafa.core.crypto 示例导航（最小示例 / 基准 / 文件加解密）
> TL;DR（快速上手三步）
> 1. 运行 AEAD 最小示例：Windows examples\fafafa.core.crypto\BuildOrRun_MinExample.bat / Linux/macOS ./examples/fafafa.core.crypto/BuildOrRun_MinExample.sh
> 2. 运行端到端脚本：Windows scripts\run-crypto-examples.bat / Linux/macOS ./scripts/run-crypto-examples.sh（自动展示日志，可加 --clean）
> 3. 快速验证：Windows scripts\verify-crypto-examples.bat / Linux/macOS ./scripts/verify-crypto-examples.sh（可加 --no-run / --clean）



本目录包含加密模块的可运行示例与基准脚本，覆盖 AEAD 最小用法（Append/In‑Place）、AES‑GCM 基准与 CSV 输出，以及一个简单的文件加解密示例。

## 目录结构（节选）
- example_aead_inplace_append_min.pas  最小 AEAD Append/In‑Place 示例（可一键脚本运行）
- example_aead_inplace_append_min.lpi  Lazarus 工程（脚本优先构建 .lpi）
- BuildOrRun_MinExample.bat / .sh      一键构建并运行最小示例（Windows/Linux/macOS）
- example_gcm_bench.lpr                GCM 基准（控制台）
- example_gcm_bench_csv.lpr            GCM 基准（CSV 输出，写入 bench_results/）
- BuildOrRun_Bench.bat / .sh           一键构建并运行基准（控制台）
- BuildOrRun_BenchCSV.bat / .sh        一键构建并运行基准（CSV 输出）
- file_encryption.lpr                  简单文件加/解密示例（手动构建）

## 快速开始（最小示例：AEAD Append/In‑Place）
- Windows（cmd）：
  - examples\fafafa.core.crypto\BuildOrRun_MinExample.bat
- Linux/macOS（bash）：
  - ./examples/fafafa.core.crypto/BuildOrRun_MinExample.sh
- 预期输出（示例，长度随输入/Overhead 变化）：
  ```
  Append: CT+Tag len=21
  Append: PT len=5 ok=TRUE
  InPlace: CT+Tag len=28
  InPlace: PT len=12
  ```
- 参考文档：docs/fafafa.core.crypto.aead.md（接口契约、脚本与期望输出）

## 基准（AES‑GCM）
- 控制台基准：
  - Windows：examples\fafafa.core.crypto\BuildOrRun_Bench.bat
  - Linux/macOS：./examples/fafafa.core.crypto/BuildOrRun_Bench.sh
- CSV 基准：

### 文件加解密一键运行
- Windows：examples\fafafa.core.crypto\BuildOrRun_FileEncryption.bat
- Linux/macOS：./examples/fafafa.core.crypto/BuildOrRun_FileEncryption.sh

  - Windows：examples\fafafa.core.crypto\BuildOrRun_BenchCSV.bat
  - Linux/macOS：./examples/fafafa.core.crypto/BuildOrRun_BenchCSV.sh
- CSV 输出位置（示例）：examples/fafafa.core.crypto/bench_results/gcm_baseline.csv

- 运行后查看日志：examples/fafafa.core.crypto/fileenc.log（示例包含控制台打印 + 文件日志双写）
- 期望日志片段（含负向用例）：
  ```
  === file_encryption demo start ===
  使用密码(加密): "MySecretPassword123!"
  生成盐值: ...
  生成IV: ...
  密钥派生完成
  加密完成，处理了 15 字节
  ✓ 文件加密成功
  解密完成，处理了 15 字节
  ✓ 文件解密成功
  验证原始文件和解密文件...
  ✓ 文件加密/解密测试完全成功！
  ✓ 错误密码解密失败（符合预期）
  文件信息: 原始文件: test_original.txt ...
  === file_encryption demo done ===
  ```

- 清理脚本（多次演示后快速复原）
  - Windows：examples\fafafa.core.crypto\Cleanup_Outputs.bat
  - Linux/macOS：./examples/fafafa.core.crypto/Cleanup_Outputs.sh


- 快速验证（Smoke Test）
  - Windows：scripts\\verify-crypto-examples.bat [--no-run] [--clean]
  - Linux/macOS：./scripts/verify-crypto-examples.sh [--no-run] [--clean]
  - 校验 AEAD 的 run.log 与文件加解密的 fileenc.log；比较原始/解密文件内容相同；错误密码输出文件不应存在


## 文件加解密示例（简）
- 源码：examples/fafafa.core.crypto/file_encryption.lpr
- 构建建议（lazbuild）：
  - Windows：
    - 可设置 LAZBUILD_EXE 后运行：
      - `"%LAZBUILD_EXE%" --bm=Release examples\fafafa.core.crypto\file_encryption.lpr`
  - Linux/macOS：
    - `lazbuild --bm=Release examples/fafafa.core.crypto/file_encryption.lpr`
- 或直接使用 fpc（确保 -Fu 指向仓库 src）：
  - `fpc -Mobjfpc -Fu"src" -FE"examples/fafafa.core.crypto/bin" examples/fafafa.core.crypto/file_encryption.lpr`

## 常见问题 / 故障排查
- lazbuild 未找到：
  - 设置环境变量 LAZBUILD_EXE 指向 lazbuild 可执行文件，或将 lazbuild 加入 PATH
- 构建 .pas 失败：
  - 脚本优先使用 .lpi；若无 .lpi 直接构建 .pas，请确认可以解析仓库 src（OtherUnitFiles=../../src）
- 生成的可执行文件未找到：
  - 检查 .lpi 的 Target.Filename 是否与脚本默认查找路径一致（默认 bin/）

---
- 顶层导航：README.examples.md、docs/EXAMPLES.md
- 发布版入口：release/README.md → “Crypto Minimal Example”

