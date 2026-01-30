# fafafa.core.crypto Cross-Platform Checklist

目标：让任何人能在 Windows / Linux / macOS 上以最少步骤完成构建与测试，并运行最小示例/微基准。

## 1) 环境准备

- Free Pascal / Lazarus
  - 建议 Lazarus trunk + FPC 3.3.x（项目脚本对 lazbuild 友好）
  - Windows: 安装 Lazarus 后，确保 tools\lazbuild.bat 可用
  - Linux/macOS: 确保 lazbuild 在 PATH 中
- Git 与 Shell
  - Windows: PowerShell 5+ / CMD
  - Linux/macOS: bash/zsh

## 2) 快速验证（推荐）

- 单命令：运行项目内封装测试脚本
  - Windows:
    - tests\fafafa.core.crypto\BuildOrTest.bat test
  - Linux/macOS:
    - tests/fafafa.core.crypto/BuildOrTest.sh test
- 期望输出：最后出现“此时不应有 failed。”，并生成 junit 报告：
  - tests/fafafa.core.crypto/reports/tests_crypto.junit.xml

## 3) 一键脚本（可选，覆盖 examples 与 plays）

- Windows:
  - scripts\build_or_test_crypto.bat test        # 仅测试
  - scripts\build_or_test_crypto.bat examples    # 构建示例到 bin/
  - scripts\build_or_test_crypto.bat plays       # 构建微基准到 bin/
- Linux/macOS:
  - scripts/build_or_test_crypto.sh test
  - scripts/build_or_test_crypto.sh examples
  - scripts/build_or_test_crypto.sh plays

说明：examples 与 plays 目前为最小集（AES‑GCM 示例与微基准），后续按需扩展。

## 4) 目录规范（与现有模块保持一致）

- examples/fafafa.core.crypto/
  - example_crypto_gcm_basic.lpr
  - example_crypto_gcm_tag12.lpr
  - lib/    # 编译中间产物
- plays/fafafa.core.crypto/
  - bench_gcm_throughput.lpr
  - lib/
- bin/
  - example_*.exe / bench_*.exe（Windows）
  - example_* / bench_*（Linux/macOS）

## 5) 常见问题

- lazbuild 未找到：请在 scripts 中修改 LAZBUILD 路径，或将 lazbuild 加入 PATH
- 测试失败：检查 FPC/Lazarus 版本；Windows 打开 PowerShell 执行权限；Linux/macOS 脚本 chmod +x
- 性能波动：微基准仅为相对指标，关注同机同编译器下的差异

## 6) 安全注意

- 所有认证标签比较已使用常量时间比较（SecureCompare/ConstantTimeCompare）
- Seal/Open 以及 GHASH 过程中敏感中间数据已显式清零，避免驻留




## 7) RNG 后端与回退策略

- Windows
  - 首选 BCryptGenRandom（CNG，bcrypt.dll），无需显式句柄；失败时回退到 CryptGenRandom（advapi32.dll）
  - 可用于测试/诊断的强制回退环境变量：FAFAFA_CRYPTO_RNG_FORCE_LEGACY=1
- Linux
  - 首选 getrandom(2) 系统调用（非阻塞模式），若不可用或读取得不到满足则回退 /dev/urandom
- macOS
  - 使用 SecRandomCopyBytes（Security.framework）
- 实现备注
  - 所有路径均通过 ISecureRandom 接口（GetBytes/GetInteger/GetBase64UrlString 等），调用方无感
  - 提供 Reset/Burn 控制生命周期；单元测试覆盖了 Windows legacy 强制路径与分布烟囱检查
- 常见问题
  - Windows 无法加载 bcrypt/advapi32：请确认系统库可用性；可先通过 FAFAFA_CRYPTO_RNG_FORCE_LEGACY 进行回退验证
  - Linux getrandom 不可用：属于内核/架构差异，库会自动回退到 /dev/urandom
