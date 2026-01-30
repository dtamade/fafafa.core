# fafafa.core.process: posix_spawn 后端设计草案（T3）

## 目标
- 在 Unix 系统以更低开销、更安全的方式创建子进程，作为 fork+exec 的可选后端
- 在多线程环境中减少 fork 带来的写时复制与锁复制问题
- 保持与现有 API 语义一致（IProcessStartInfo/IProcess），不破坏现有测试

## 启用方式（编译期）
- 宏：`FAFAFA_PROCESS_USE_POSIX_SPAWN`（默认关闭）
- 打开后：Unix 平台优先走 posix_spawn 路径；若遇到不受支持的功能则回退到 fork+exec

## 能力与限制矩阵
- 支持
  - 可执行解析（PATH 搜索）
  - argv/环境 envp 传递
  - 标准流重定向（stdin/stdout/stderr）
  - 合流 stderr->stdout
  - 进程组（PGID）/会话（setsid）【与 FAFAFA_PROCESS_GROUPS 搭配时】
- 限制/注意事项
  - 工作目录：优先使用 `posix_spawn_file_actions_addchdir_np`（若目标 libc 支持）
    - 若不支持：需要回退 fork+exec（保持行为一致）
  - 优先级/调度属性：通过 `setpriority/nice` 等手段在 fork+exec 更灵活，posix_spawn 需评估 attr 扩展可用性，不可用时回退
  - 信号掩码/处理：保持与现状一致，避免在 T3 引入语义变化

## 实现草图
- 条件编译入口（Unix）：
  - `{$IFDEF FAFAFA_PROCESS_USE_POSIX_SPAWN}` 切换到 `StartUnixUsingPosixSpawn`
  - 否则使用现有 `fork+exec` 路径
- 关键 API
  - `posix_spawn(&pid, path, file_actions, attr, argv, envp)`
  - `posix_spawn_file_actions_*`：
    - `adddup2`：将父进程创建的管道端映射至 0/1/2
    - `addclose`：关闭不需要的 fd，结合 `O_CLOEXEC`/`FD_CLOEXEC`
    - `addchdir_np`（若可用）：切换工作目录
  - `posix_spawnattr_*`：
    - `posix_spawnattr_init/destroy`
    - 设置 PGID/会话（平台支持时）
- 环境与 argv 构造
  - 复用现有 `BuildArgumentArrayUnix`/`BuildEnvironmentArrayUnix`
- 失败与回退机制
  - 任何步骤返回非零 errno：
    - 若可回退（如不支持 chdir_np/attr 扩展）：清理 file_actions/attr 后回退到 fork+exec
    - 否则：抛出 `EProcessStartError`，包含 errno 与简短说明

## 资源与安全
- 所有临时 fd 均设置 `FD_CLOEXEC`/使用 `pipe2(O_CLOEXEC)`
- 父进程仅保留读/写端需要的句柄；其余在 `file_actions` 中 `addclose`
- 成功 spawn 后父进程关闭对子进程端 fd，维持与现实现一致

## 兼容性与平台差异
- Linux/glibc：posix_spawn 基于 vfork 的实现较常见，性能优于 fork+exec
- FreeBSD 等 BSD：实现细节不同，但语义相同；缺少 chdir_np 等扩展时回退
- macOS：更倾向 posix_spawn，但本轮不引入特化；后续可加 `*_np` 能力探测

## 测试计划（TDD）
- 仅在宏启用时追加/激活以下测试，默认构建不受影响
- 测试项
  1) 基本启动/等待/退出码（echo/true/false）
  2) stdin/stdout/stderr 重定向与合流
  3) PATH 搜索（含相对/绝对路径）
  4) envp 传递与覆盖
  5) 工作目录：
     - 若 chdir_np 可用：spawn 后 CWD 生效
     - 若不可用：应自动回退 fork+exec 路径（以能力探测注入预期）
  6) 进程组：setsid/PGID + kill(-pgid, SIGTERM/SIGKILL)（与 FAFAFA_PROCESS_GROUPS）
  7) 回退验证：刻意构造不受支持场景，验证自动回退且行为一致
- 性能对比（非必须）：
  - 多线程/大量短命子进程的启动耗时对比，记录但不设硬性阈值

## 风险与回滚
- 风险
  - 不同 libc 对 `*_np` 扩展支持差异；动作组合不当可能造成 fd 泄漏
  - 行为偏差（例如 CWD/优先级）导致与现有测试不完全一致
- 缓解
  - 以宏开关保护，默认关闭
  - 任何不可确保一致性的路径直接回退 fork+exec
  - 完整单元测试覆盖核心语义
- 回滚
  - 关闭 `FAFAFA_PROCESS_USE_POSIX_SPAWN` 即恢复原行为

## 里程碑
- M1：提交实现草案与占位代码结构（不启用）
- M2：实现 file_actions 基础重定向 + argv/envp + PATH 搜索
- M3：可选 CWD/PGID 支持与回退路径
- M4：完善测试集与文档，评估性能


## 启用与验证（快速指南）

- 启用宏（Unix）：在构建时加入 `-dFAFAFA_PROCESS_USE_POSIX_SPAWN`
- 快速验证脚本：`tests/fafafa.core.process/run_spawn_subset.sh`
  - 构建：自动带上宏并编译 `tests_process.lpi`
  - 运行：执行核心子集套件（Process/TimeoutAPI/CombinedOutput），验证 spawn 路径基础语义
- 默认构建：不启用宏，仍走 fork+exec；所有现有测试与示例不受影响


## PGID/会话启用说明

- 相关宏（默认关闭）：
  - `FAFAFA_POSIX_SPAWN_ATTR`：启用 `posix_spawnattr_*` 绑定
  - `FAFAFA_POSIX_SPAWN_SETPGROUP`：允许设置进程组 ID（PGID）
  - `FAFAFA_POSIX_SPAWN_FLAGS`：提供 `POSIX_SPAWN_SETPGROUP` 等平台相关标志（需在构建时传入正确值）
- 行为策略：
  - 若上述宏全部启用：在 `StartUnixUsingPosixSpawn` 中 `posix_spawnattr_init` -> `posix_spawnattr_setflags(POSIX_SPAWN_SETPGROUP)` -> `posix_spawnattr_setpgroup(0)`；否则传 `attr=nil`，保持默认语义
  - 与 `FAFAFA_PROCESS_GROUPS` 配合：若 spawn 路径不可用或失败，自动回退到 `fork+exec` 路径下的 `setpgid`
- 测试建议（Unix 环境）：
  - 子集脚本扩展（可选）：新增 `run_spawn_groups_subset.sh`，在启用宏时验证 PGID 行为

## 可选子集脚本（建议）

示例：`tests/fafafa.core.process/run_spawn_groups_subset.sh`
- 构建参数：`-dFAFAFA_PROCESS_USE_POSIX_SPAWN -dFAFAFA_POSIX_SPAWN_ATTR -dFAFAFA_POSIX_SPAWN_SETPGROUP -dFAFAFA_POSIX_SPAWN_FLAGS`
- 运行套件：
  - `TTestPipelineEnhanced`（FailFast kill 组）
  - `TTestCase_ProcessGroup_Unix`（若存在）
- 成功标准：所有断言通过；若平台不支持或失败，脚本退出码非零

## 子进程 fd 最小暴露策略（建议）

- 父进程：pipe2(O_CLOEXEC)/fcntl(FD_CLOEXEC) 确保默认不继承
- 子进程（spawn file_actions）：
  - adddup2 映射 0/1/2
  - addclose 关闭与重定向相对的另一端（stdin: 关闭写端；stdout: 关闭读端；stderr: 关闭读端）
- 后续增强：
  - 维护一份需要关闭的 fd 列表（含第三方打开的 fd），在 file_actions 中批量 addclose
  - 在 fork+exec 路径与 spawn 路径保持策略一致


## 平台 Flags 常量映射指南（避免硬编码）

- 建议在目标 Unix 环境用以下方法获取 `POSIX_SPAWN_*` 的真实值，并通过编译选项传入：
  1) 预处理导出：
     - `printf "#include <spawn.h>\n" | cc -dM -E - | grep POSIX_SPAWN_`
  2) 小型 C 程序打印：
     - 包含 `<spawn.h>`，`printf("%d\n", POSIX_SPAWN_SETPGROUP);` 等
  3) 然后在 lazbuild/fpc 侧加入：
     - `--add-options="-dFAFAFA_POSIX_SPAWN_FLAGS -dPOSIX_SPAWN_SETPGROUP=<值>"`
- 注意：若未提供正确 flags，`setpgroup` 可能被忽略；建议一并开启 `FAFAFA_POSIX_SPAWN_ATTR` 与 `FAFAFA_POSIX_SPAWN_SETPGROUP`


