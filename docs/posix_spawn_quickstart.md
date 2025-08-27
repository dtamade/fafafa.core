# fafafa.core.process - posix_spawn 快速上手（Unix）

本指南帮助你在 Unix/Linux 环境启用并验证 `posix_spawn` 快路径。该路径默认关闭，启用后不满足条件会自动回退到 `fork+exec`，保证语义一致与安全。

## 先决条件
- Unix/Linux 系统（glibc/bsd libc）
- Lazarus lazbuild（推荐），或 FPC 直接编译
- 标准 C 运行库提供 `posix_spawnp`；可选提供：
  - `posix_spawn_file_actions_*`（用于重定向）
  - `posix_spawn_file_actions_addchdir_np`（用于工作目录）

## 功能开关（编译宏）
- `FAFAFA_PROCESS_USE_POSIX_SPAWN`：启用 spawn 快路径（默认：关闭）
- `FAFAFA_POSIX_SPAWN_FILE_ACTIONS`：启用 file_actions 绑定与重定向（默认：关闭）
- `FAFAFA_POSIX_SPAWN_CHDIR_NP`：启用 chdir_np（若 libc 支持）（默认：关闭）

说明：
- 未启用 `FAFAFA_POSIX_SPAWN_FILE_ACTIONS` 时，spawn 路径不支持重定向/工作目录，遇到相关配置会自动回退 `fork+exec`。
- 未启用 `FAFAFA_POSIX_SPAWN_CHDIR_NP` 时，设置工作目录将回退 `fork+exec`。

## 快速验证（推荐脚本）
项目已提供 Unix 快速脚本，自动注入宏并跑核心子集测试：

```bash
cd tests/fafafa.core.process
chmod +x run_spawn_subset.sh
./run_spawn_subset.sh
```

该脚本会：
- 使用 `-dFAFAFA_PROCESS_USE_POSIX_SPAWN` 构建 tests_process.lpi
- 运行核心套件：`TTestCase_Process` / `TTestCase_TimeoutAPI` / `TTestCase_CombinedOutput`
- 通过即输出：`=== Spawn subset tests passed ===`

## 手动构建示例
- 使用 lazbuild（基础 spawn，无重定向能力）
```bash
lazbuild --add-options="-dFAFAFA_PROCESS_USE_POSIX_SPAWN" tests/fafafa.core.process/tests_process.lpi
```

- 使用 lazbuild（spawn + 重定向能力 + chdir_np）
```bash
lazbuild \
  --add-options="-dFAFAFA_PROCESS_USE_POSIX_SPAWN -dFAFAFA_POSIX_SPAWN_FILE_ACTIONS -dFAFAFA_POSIX_SPAWN_CHDIR_NP" \
  tests/fafafa.core.process/tests_process.lpi
```

- 直接运行测试（生成的二进制名通常为 `tests`）
```bash
./tests/fafafa.core.process/bin/tests --all --format=plain --progress
```

## 行为与回退策略
- 默认（宏关闭）：始终 `fork+exec`，行为与既有实现一致
- 宏开启：
  - 满足条件：`posix_spawnp` 路径，支持 argv/envp、（可选）重定向与 chdir_np
  - 不满足条件：自动回退 `fork+exec`，不改变行为与测试预期

典型回退条件：
- 未启用 `FAFAFA_POSIX_SPAWN_FILE_ACTIONS` 却配置了重定向
- 未启用或 libc 不支持 `addchdir_np` 却设置了工作目录
- spawn 调用返回非 0 errno

## 常见问题排查
- 找不到 lazbuild
  - 安装 Lazarus 或将 lazbuild 加入 PATH；或直接用 FPC 编译（需手动指定单元路径）

- 链接/符号找不到 `posix_spawnp`
  - 检查系统 libc；在多数现代 Linux/glibc 环境应可用

- 工作目录未生效
  - 确认是否启用 `FAFAFA_POSIX_SPAWN_CHDIR_NP` 且 libc 支持该符号，否则会自动回退 `fork+exec`

- 重定向无效
  - 确认已启用 `FAFAFA_POSIX_SPAWN_FILE_ACTIONS`；并验证测试套件 `TTestCase_CombinedOutput` 与 `TTestCase_Process` 的重定向用例

- PATH 搜索差异
  - spawn 使用 `posix_spawnp`：遵循 PATH 搜索；`UsePathSearch(False)` 时需提供绝对/相对路径

## 建议的测试顺序（Unix）
1) 仅启用 `FAFAFA_PROCESS_USE_POSIX_SPAWN`，跑 `run_spawn_subset.sh`（不涉及 chdir/重定向）
2) 加上 `FAFAFA_POSIX_SPAWN_FILE_ACTIONS`，再跑子集（验证重定向与合流）
3) 若 libc 支持，再加 `FAFAFA_POSIX_SPAWN_CHDIR_NP`，测试带工作目录的用例
4) 通过后再尝试全量测试：
```bash
cd tests/fafafa.core.process
./buildOrTest.sh test
```
（注意：`buildOrTest.sh` 未自动添加宏，可先用 lazbuild 构建后再直接运行 bin/tests）

## 关闭与回退
- 移除编译宏即可回到原有 `fork+exec` 行为
- 代码在启用宏时也会在不满足能力条件时自动回退，保证稳定

## 参考
- docs/fafafa.core.process.posix_spawn.plan.md（设计与测试计划）
- tests/fafafa.core.process/run_spawn_subset.sh（快速验证脚本）
- src/fafafa.core.process.unix.inc（spawn 接入与回退逻辑）

