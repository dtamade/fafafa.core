unit fafafa.core.sync.namedMutex.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  {**
   * @permissions_control
   * **权限控制（Permission Control）**：
   *
   * 命名同步原语在不同平台上使用不同的权限控制机制：
   *
   * **Unix/Linux 平台**：
   * - 使用 POSIX 文件系统权限位（chmod 风格）
   * - 命名对象通常映射到文件系统路径（如 /dev/shm/）
   * - 权限格式：0xxx（八进制），例如 0660 = rw-rw----
   *
   * **默认权限策略**：
   * - **NamedMutex**: 0660 (S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP)
   *   - 用户可读写，组可读写，其他用户无权限
   *   - 适用场景：同一用户或同组进程间共享
   *
   * - **NamedSemaphore**: 0644 (rw-r--r--)
   *   - 用户可读写，组和其他用户只读
   *   - 注意：信号量的"读"权限允许等待操作
   *
   * - **NamedEvent/NamedCondVar/NamedRWLock/NamedBarrier**: 0660
   *   - 与 NamedMutex 相同的权限策略
   *
   * **Windows 平台**：
   * - 使用 ACL (Access Control List) 机制
   * - 命名对象存储在内核对象命名空间
   * - 默认权限：当前用户完全控制，管理员组完全控制
   * - UseGlobalNamespace = True 时需要管理员权限
   *
   * **安全最佳实践**：
   *
   * 1. **最小权限原则**：
   *    - 仅授予必要的权限
   *    - 避免使用 0666 或 0777（所有用户可写）
   *    - 考虑使用 0600（仅所有者）如果不需要跨用户共享
   *
   * 2. **命名空间隔离**：
   *    - 使用唯一的名称前缀避免冲突
   *    - 避免使用全局命名空间（UseGlobalNamespace = False）
   *    - 全局命名空间在 Windows 上需要管理员权限
   *
   * 3. **权限验证**：
   *    - 创建命名对象后验证权限设置
   *    - 处理权限不足的错误（EACCES/ERROR_ACCESS_DENIED）
   *    - 记录权限相关的错误以便调试
   *
   * 4. **跨平台考虑**：
   *    - Unix: 使用 umask 影响默认权限
   *    - Windows: 考虑 UAC (User Account Control) 影响
   *    - 测试不同用户和权限场景
   *
   * **常见权限问题**：
   *
   * 1. **EACCES (Permission denied)**：
   *    - 原因：当前用户无权限访问命名对象
   *    - 解决：检查文件系统权限，确保用户在正确的组中
   *
   * 2. **EEXIST (Already exists)**：
   *    - 原因：命名对象已存在，可能由其他进程创建
   *    - 解决：使用唯一名称或实现清理机制
   *
   * 3. **Windows ERROR_ACCESS_DENIED**：
   *    - 原因：全局命名空间需要管理员权限
   *    - 解决：使用本地命名空间或以管理员身份运行
   *
   * **权限检查示例**：
   * ```pascal
   * // Unix: 检查文件权限
   * var
   *   StatBuf: TStat;
   * begin
   *   if fpStat('/dev/shm/my_mutex', StatBuf) = 0 then
   *     WriteLn('Permissions: ', OctStr(StatBuf.st_mode and $1FF, 3));
   * end;
   *
   * // 跨平台: 处理权限错误
   * try
   *   mutex := MakeNamedMutex('my_mutex');
   * except
   *   on E: ELockError do
   *     if (GetLastError = EACCES) or (GetLastError = ERROR_ACCESS_DENIED) then
   *       WriteLn('Permission denied: check user permissions');
   * end;
   * ```
   *
   * @see namedShm.unix.pas - SHM_PERM_OWNER_ONLY, SHM_PERM_WITH_GROUP 常量
   * @posix_reference chmod(2), umask(2)
   * @windows_reference CreateMutex, SECURITY_ATTRIBUTES
   *}

  {**
   * @namespace_conflicts
   * **命名空间冲突处理（Namespace Conflict Handling）**：
   *
   * 命名同步原语使用字符串名称标识，可能导致命名冲突：
   *
   * **冲突类型**：
   *
   * 1. **应用间冲突**：
   *    - 不同应用使用相同名称
   *    - 示例：两个应用都使用 "app_mutex"
   *    - 后果：意外共享同步对象，导致死锁或竞态条件
   *
   * 2. **版本冲突**：
   *    - 同一应用的不同版本使用相同名称
   *    - 示例：v1.0 和 v2.0 都使用 "myapp_lock"
   *    - 后果：版本间互相干扰
   *
   * 3. **实例冲突**：
   *    - 同一应用的多个实例使用相同名称
   *    - 示例：多个用户运行同一应用
   *    - 后果：实例间意外共享或冲突
   *
   * **命名空间策略**：
   *
   * **Unix/Linux 平台**：
   * - 命名对象映射到文件系统路径
   * - POSIX 信号量：/dev/shm/sem.<name>
   * - POSIX 共享内存：/dev/shm/<name>
   * - 命名空间隔离：通过路径前缀实现
   *
   * **Windows 平台**：
   * - 本地命名空间（默认）：
   *   - 路径：Local\<name>
   *   - 作用域：当前登录会话
   *   - 权限：当前用户
   *   - 适用：单用户应用
   *
   * - 全局命名空间（UseGlobalNamespace = True）：
   *   - 路径：Global\<name>
   *   - 作用域：所有会话（包括服务）
   *   - 权限：需要管理员权限或 SeCreateGlobalPrivilege
   *   - 适用：跨会话通信、系统服务
   *
   * **命名最佳实践**：
   *
   * 1. **使用唯一前缀**：
   *    ```pascal
   *    // ✅ 好：包含应用名称和用途
   *    mutex := MakeNamedMutex('myapp_v1_database_lock');
   *
   *    // ❌ 差：通用名称，易冲突
   *    mutex := MakeNamedMutex('lock');
   *    ```
   *
   * 2. **包含版本信息**：
   *    ```pascal
   *    // ✅ 好：包含主版本号
   *    mutex := MakeNamedMutex('myapp_v2_config_mutex');
   *
   *    // ⚠️ 注意：包含完整版本可能导致版本间无法通信
   *    mutex := MakeNamedMutex('myapp_v2.1.3_mutex');
   *    ```
   *
   * 3. **使用用户标识符（可选）**：
   *    ```pascal
   *    // ✅ 好：多用户环境下隔离
   *    var username := GetEnvironmentVariable('USER');
   *    mutex := MakeNamedMutex('myapp_' + username + '_lock');
   *
   *    // ⚠️ 注意：跨用户通信时不要包含用户名
   *    ```
   *
   * 4. **使用 GUID/UUID（高安全性）**：
   *    ```pascal
   *    // ✅ 好：保证唯一性，适合临时对象
   *    var guid := CreateGUID;
   *    mutex := MakeNamedMutex('myapp_temp_' + GUIDToString(guid));
   *    ```
   *
   * 5. **避免特殊字符**：
   *    ```pascal
   *    // ✅ 好：仅使用字母、数字、下划线
   *    mutex := MakeNamedMutex('myapp_database_lock');
   *
   *    // ❌ 差：包含路径分隔符或特殊字符
   *    mutex := MakeNamedMutex('myapp/lock');  // Unix: 创建子目录
   *    mutex := MakeNamedMutex('myapp\\lock'); // Windows: 无效
   *    ```
   *
   * **冲突检测与处理**：
   *
   * 1. **检测现有对象**：
   *    ```pascal
   *    try
   *      mutex := MakeNamedMutex('myapp_lock');
   *    except
   *      on E: ELockError do
   *        if GetLastError = EEXIST then
   *          WriteLn('Mutex already exists - another instance running?');
   *    end;
   *    ```
   *
   * 2. **单实例应用模式**：
   *    ```pascal
   *    // 尝试创建互斥锁，如果已存在则退出
   *    var mutex: INamedMutex;
   *    try
   *      mutex := MakeNamedMutex('myapp_single_instance');
   *      if not mutex.TryLockNamed.IsLocked then
   *      begin
   *        WriteLn('Another instance is already running');
   *        Halt(1);
   *      end;
   *      // 应用主逻辑
   *    finally
   *      mutex := nil; // 自动释放
   *    end;
   *    ```
   *
   * 3. **清理孤儿对象**：
   *    ```pascal
   *    // Unix: 手动清理 /dev/shm/ 中的孤儿对象
   *    // 注意：仅在确认对象不再使用时清理
   *    (*$IFDEF UNIX*)
   *    if FileExists('/dev/shm/sem.myapp_lock') then
   *      DeleteFile('/dev/shm/sem.myapp_lock');
   *    (*$ENDIF*)
   *    ```
   *
   * **常见错误处理**：
   *
   * 1. **EEXIST (Already exists)**：
   *    - Unix 错误码：17
   *    - 含义：命名对象已存在
   *    - 处理：
   *      - 单实例应用：退出或提示用户
   *      - 多实例应用：打开现有对象或使用不同名称
   *
   * 2. **ENAMETOOLONG (Name too long)**：
   *    - Unix 错误码：36
   *    - 含义：名称超过系统限制
   *    - 限制：
   *      - POSIX 信号量：NAME_MAX (通常 255 字节)
   *      - 共享内存：PATH_MAX (通常 4096 字节)
   *    - 处理：使用更短的名称或哈希长名称
   *
   * 3. **ERROR_INVALID_NAME (Windows)**：
   *    - Windows 错误码：123
   *    - 含义：名称包含无效字符
   *    - 处理：移除或替换无效字符（\、/、:、*、?、"、<、>、|）
   *
   * **跨平台命名策略**：
   *
   * ```pascal
   * // 跨平台安全的命名函数
   * function SafeNamedObjectName(const AAppName, APurpose: string): string;
   * begin
   *   // 1. 使用应用名称前缀
   *   Result := AAppName + '_' + APurpose;
   *
   *   // 2. 替换不安全字符
   *   Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
   *   Result := StringReplace(Result, '\', '_', [rfReplaceAll]);
   *   Result := StringReplace(Result, ':', '_', [rfReplaceAll]);
   *
   *   // 3. 限制长度（POSIX 信号量限制）
   *   if Length(Result) > 250 then
   *     Result := Copy(Result, 1, 250);
   *
   *   // 4. 确保以字母开头（某些系统要求）
   *   if not (Result[1] in ['A'..'Z', 'a'..'z']) then
   *     Result := 'n_' + Result;
   * end;
   * ```
   *
   * **调试命名冲突**：
   *
   * 1. **Unix: 列出现有对象**：
   *    ```bash
   *    # POSIX 信号量
   *    ls -la /dev/shm/sem.*
   *
   *    # POSIX 共享内存
   *    ls -la /dev/shm/
   *
   *    # 查看权限和所有者
   *    stat /dev/shm/sem.myapp_lock
   *    ```
   *
   * 2. **Windows: 使用 Process Explorer**：
   *    - 下载 Sysinternals Process Explorer
   *    - View -> Show Lower Pane -> Handles
   *    - 搜索 "Mutant"、"Semaphore"、"Event" 等
   *
   * 3. **程序化检测**：
   *    ```pascal
   *    // 尝试打开现有对象
   *    var mutex: INamedMutex;
   *    try
   *      mutex := MakeNamedMutex('myapp_lock');
   *      WriteLn('Successfully created or opened mutex');
   *    except
   *      on E: ELockError do
   *        WriteLn('Error: ', E.Message);
   *    end;
   *    ```
   *
   * @see UseGlobalNamespace 配置选项
   * @posix_reference sem_open(3), shm_open(3)
   * @windows_reference CreateMutex, CreateSemaphore, Kernel Object Namespaces
   *}

  {**
   * @platform_capabilities
   * **平台能力文档（Platform Capabilities）**：
   *
   * 命名同步原语在不同平台上的实现和能力存在显著差异：
   *
   * **Unix/Linux 平台能力**：
   *
   * 1. **NamedMutex（命名互斥锁）**：
   *    - 实现：POSIX pthread_mutex_t + 共享内存（shm_open + mmap）
   *    - 进程共享：✅ 支持（PTHREAD_PROCESS_SHARED）
   *    - Robust 机制：✅ 支持（PTHREAD_MUTEX_ROBUST）
   *      - 自动检测持有者崩溃（EOWNERDEAD）
   *      - 支持锁恢复（pthread_mutex_consistent）
   *    - 递归锁：✅ 支持（PTHREAD_MUTEX_RECURSIVE）
   *    - 超时等待：✅ 支持（pthread_mutex_timedlock）
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（进程退出后需手动清理 /dev/shm/）
   *    - 性能：⚡ 高（内核态，futex 优化）
   *
   * 2. **NamedSemaphore（命名信号量）**：
   *    - 实现：POSIX sem_open
   *    - 进程共享：✅ 支持（原生跨进程）
   *    - 超时等待：✅ 支持（sem_timedwait）
   *    - 计数范围：✅ 支持（0 到 SEM_VALUE_MAX，通常 32767）
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（需手动 sem_unlink）
   *    - 性能：⚡ 高（内核态）
   *
   * 3. **NamedEvent（命名事件）**：
   *    - 实现：pthread_cond_t + pthread_mutex_t + 共享内存
   *    - 进程共享：✅ 支持（PTHREAD_PROCESS_SHARED）
   *    - 手动重置：✅ 支持（应用层实现）
   *    - 自动重置：✅ 支持（应用层实现）
   *    - 脉冲模式：✅ 支持（pthread_cond_broadcast + 立即重置）
   *    - 超时等待：✅ 支持（pthread_cond_timedwait）
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（需手动清理）
   *    - 性能：⚡ 高（内核态）
   *
   * 4. **NamedCondVar（命名条件变量）**：
   *    - 实现：pthread_cond_t + 共享内存
   *    - 进程共享：✅ 支持（PTHREAD_PROCESS_SHARED）
   *    - 超时等待：✅ 支持（pthread_cond_timedwait）
   *    - 虚假唤醒：⚠️ 可能发生（POSIX 标准允许）
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（需手动清理）
   *    - 性能：⚡ 高（内核态）
   *
   * 5. **NamedRWLock（命名读写锁）**：
   *    - 实现：pthread_rwlock_t + 共享内存
   *    - 进程共享：✅ 支持（PTHREAD_PROCESS_SHARED）
   *    - 读者优先：✅ 支持（PTHREAD_RWLOCK_PREFER_READER_NP）
   *    - 写者优先：✅ 支持（PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP）
   *    - 超时等待：✅ 支持（pthread_rwlock_timedrdlock/timedwrlock）
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（需手动清理）
   *    - 性能：⚡ 高（内核态）
   *
   * 6. **NamedBarrier（命名屏障）**：
   *    - 实现：pthread_barrier_t + 共享内存
   *    - 进程共享：✅ 支持（PTHREAD_PROCESS_SHARED）
   *    - 动态计数：❌ 不支持（初始化后固定）
   *    - 重用机制：⚠️ 需要手动重新初始化
   *    - 权限控制：✅ 支持（文件系统权限）
   *    - 持久化：⚠️ 半持久化（需手动清理）
   *    - 性能：⚡ 高（内核态）
   *
   * **Windows 平台能力**：
   *
   * 1. **NamedMutex（命名互斥锁）**：
   *    - 实现：CreateMutex（内核对象）
   *    - 进程共享：✅ 支持（原生跨进程）
   *    - Robust 机制：✅ 支持（WAIT_ABANDONED）
   *      - 自动检测持有者崩溃
   *      - 返回 WAIT_ABANDONED 状态
   *    - 递归锁：✅ 支持（原生递归）
   *    - 超时等待：✅ 支持（WaitForSingleObject + timeout）
   *    - 权限控制：✅ 支持（ACL，Access Control List）
   *    - 全局命名空间：✅ 支持（Global\ 前缀，需管理员权限）
   *    - 持久化：✅ 完全持久化（内核对象，进程退出自动清理）
   *    - 性能：⚡ 高（内核态）
   *
   * 2. **NamedSemaphore（命名信号量）**：
   *    - 实现：CreateSemaphore（内核对象）
   *    - 进程共享：✅ 支持（原生跨进程）
   *    - 超时等待：✅ 支持（WaitForSingleObject + timeout）
   *    - 计数范围：✅ 支持（0 到 LONG_MAX，通常 2^31-1）
   *    - 权限控制：✅ 支持（ACL）
   *    - 全局命名空间：✅ 支持（Global\ 前缀）
   *    - 持久化：✅ 完全持久化（内核对象）
   *    - 性能：⚡ 高（内核态）
   *
   * 3. **NamedEvent（命名事件）**：
   *    - 实现：CreateEvent（内核对象）
   *    - 进程共享：✅ 支持（原生跨进程）
   *    - 手动重置：✅ 支持（ManualReset = True）
   *    - 自动重置：✅ 支持（ManualReset = False）
   *    - 脉冲模式：✅ 支持（PulseEvent，已废弃，不推荐）
   *    - 超时等待：✅ 支持（WaitForSingleObject + timeout）
   *    - 权限控制：✅ 支持（ACL）
   *    - 全局命名空间：✅ 支持（Global\ 前缀）
   *    - 持久化：✅ 完全持久化（内核对象）
   *    - 性能：⚡ 高（内核态）
   *
   * 4. **NamedCondVar（命名条件变量）**：
   *    - 实现：命名事件 + 命名互斥锁模拟
   *    - 进程共享：✅ 支持（通过命名事件）
   *    - 超时等待：✅ 支持（WaitForSingleObject + timeout）
   *    - 虚假唤醒：⚠️ 可能发生（模拟实现）
   *    - 权限控制：✅ 支持（ACL）
   *    - 全局命名空间：✅ 支持（Global\ 前缀）
   *    - 持久化：✅ 完全持久化（内核对象）
   *    - 性能：⚠️ 中等（模拟实现，多次内核调用）
   *    - 限制：⚠️ 实验性（Broadcast 语义在极端竞争下有风险）
   *
   * 5. **NamedRWLock（命名读写锁）**：
   *    - 实现：Slim Reader/Writer Lock (SRW) + 共享内存模拟
   *    - 进程共享：⚠️ 有限支持（需要共享内存）
   *    - 读者优先：✅ 支持（应用层实现）
   *    - 写者优先：✅ 支持（应用层实现）
   *    - 超时等待：✅ 支持（应用层实现）
   *    - 权限控制：✅ 支持（ACL）
   *    - 全局命名空间：✅ 支持（Global\ 前缀）
   *    - 持久化：✅ 完全持久化（内核对象）
   *    - 性能：⚠️ 中等（模拟实现）
   *
   * 6. **NamedBarrier（命名屏障）**：
   *    - 实现：命名事件 + 命名互斥锁 + 共享计数器
   *    - 进程共享：✅ 支持（通过命名对象）
   *    - 动态计数：❌ 不支持（初始化后固定）
   *    - 重用机制：⚠️ 需要手动重新初始化
   *    - 权限控制：✅ 支持（ACL）
   *    - 全局命名空间：✅ 支持（Global\ 前缀）
   *    - 持久化：✅ 完全持久化（内核对象）
   *    - 性能：⚠️ 中等（模拟实现）
   *
   * **平台差异总结**：
   *
   * | 特性 | Unix/Linux | Windows |
   * |------|-----------|---------|
   * | 实现方式 | POSIX + 共享内存 | 内核对象 |
   * | 持久化 | 半持久化（需手动清理） | 完全持久化（自动清理） |
   * | 权限控制 | 文件系统权限（chmod） | ACL（更细粒度） |
   * | 全局命名空间 | 不支持 | 支持（Global\） |
   * | Robust 机制 | EOWNERDEAD + consistent | WAIT_ABANDONED |
   * | 性能 | 高（futex 优化） | 高（内核态） |
   * | 复杂原语 | 原生支持 | 需要模拟 |
   *
   * **跨平台兼容性建议**：
   *
   * 1. **优先使用简单原语**：
   *    - NamedMutex、NamedSemaphore、NamedEvent 在两个平台上都有良好支持
   *    - 避免使用 NamedCondVar、NamedRWLock、NamedBarrier（Windows 上为模拟实现）
   *
   * 2. **处理平台差异**：
   *    ```pascal
   *    (*$IFDEF UNIX*)
   *    // Unix: 需要手动清理
   *    try
   *      mutex := MakeNamedMutex('my_mutex');
   *      // 使用互斥锁
   *    finally
   *      mutex := nil;
   *      // 可选：手动清理
   *      DeleteFile('/dev/shm/my_mutex');
   *    end;
   *    (*$ENDIF*)
   *
   *    (*$IFDEF WINDOWS*)
   *    // Windows: 自动清理
   *    try
   *      mutex := MakeNamedMutex('my_mutex');
   *      // 使用互斥锁
   *    finally
   *      mutex := nil; // 自动清理
   *    end;
   *    (*$ENDIF*)
   *    ```
   *
   * 3. **测试跨平台行为**：
   *    - 在两个平台上测试命名冲突处理
   *    - 验证权限控制行为
   *    - 测试崩溃恢复机制（Robust/WAIT_ABANDONED）
   *
   * 4. **文档化平台限制**：
   *    - 明确标注实验性功能（如 NamedCondVar）
   *    - 说明性能差异（原生 vs 模拟）
   *    - 提供平台特定的最佳实践
   *
   * **性能考虑**：
   *
   * 1. **Unix/Linux 优化**：
   *    - 使用 futex（fast userspace mutex）优化
   *    - 避免频繁的系统调用
   *    - 考虑使用 PTHREAD_MUTEX_ADAPTIVE_NP（自适应自旋）
   *
   * 2. **Windows 优化**：
   *    - 优先使用原生内核对象（Mutex、Semaphore、Event）
   *    - 避免使用模拟实现（CondVar、RWLock、Barrier）
   *    - 考虑使用 Slim Reader/Writer Lock（SRW）替代 RWLock
   *
   * 3. **跨平台优化**：
   *    - 使用简单原语组合实现复杂功能
   *    - 避免过度使用命名同步原语（性能开销大）
   *    - 考虑使用线程内同步原语（Mutex、RWLock、CondVar）
   *
   * **调试和诊断**：
   *
   * 1. **Unix/Linux 工具**：
   *    ```bash
   *    # 列出所有命名对象
   *    ls -la /dev/shm/
   *
   *    # 查看进程打开的文件描述符
   *    lsof -p <pid> | grep /dev/shm
   *
   *    # 查看共享内存使用情况
   *    ipcs -m
   *    ```
   *
   * 2. **Windows 工具**：
   *    - Process Explorer（查看句柄）
   *    - WinObj（查看内核对象命名空间）
   *    - Performance Monitor（监控同步对象）
   *
   * 3. **程序化诊断**：
   *    ```pascal
   *    // 检测平台能力
   *    (*$IFDEF UNIX*)
   *    WriteLn('Platform: Unix/Linux');
   *    WriteLn('Robust Mutex: Supported');
   *    WriteLn('Global Namespace: Not Supported');
   *    (*$ENDIF*)
   *
   *    (*$IFDEF WINDOWS*)
   *    WriteLn('Platform: Windows');
   *    WriteLn('Robust Mutex: Supported (WAIT_ABANDONED)');
   *    WriteLn('Global Namespace: Supported (requires admin)');
   *    (*$ENDIF*)
   *    ```
   *
   * @see fafafa.core.sync.namedMutex.unix.pas - Unix 实现细节
   * @see fafafa.core.sync.namedMutex.windows.pas - Windows 实现细节
   * @posix_reference pthread(7), sem_overview(7), shm_overview(7)
   * @windows_reference Synchronization Objects, Kernel Objects, Named Objects
   *}

  {**
   * @usage_examples
   * **使用示例（Usage Examples）**：
   *
   * 以下示例展示命名同步原语的实际应用场景和最佳实践。
   *
   * **示例 1: 基本互斥锁使用（跨进程）**
   *
   * ```pascal
   * program BasicMutexExample;
   *
   * uses
   *   fafafa.core.sync.namedMutex;
   *
   * var
   *   mutex: INamedMutex;
   *   guard: INamedMutexGuard;
   * begin
   *   // 创建或打开命名互斥锁
   *   mutex := MakeNamedMutex('myapp_database_lock');
   *
   *   // 使用 RAII 守卫自动管理锁
   *   guard := mutex.LockNamed;
   *   try
   *     WriteLn('Critical section: accessing shared resource');
   *     // 执行需要互斥的操作
   *     Sleep(1000);
   *   finally
   *     guard := nil; // 自动释放锁
   *   end;
   *
   *   WriteLn('Lock released');
   * end.
   * ```
   *
   * **示例 2: 单实例应用模式**
   *
   * ```pascal
   * program SingleInstanceApp;
   *
   * uses
   *   fafafa.core.sync.namedMutex;
   *
   * var
   *   instanceMutex: INamedMutex;
   *   guard: INamedMutexGuard;
   * begin
   *   try
   *     // 尝试获取单实例锁
   *     instanceMutex := MakeNamedMutex('myapp_single_instance');
   *     guard := instanceMutex.TryLockNamed;
   *
   *     if not guard.IsLocked then
   *     begin
   *       WriteLn('Another instance is already running!');
   *       Halt(1);
   *     end;
   *
   *     WriteLn('Application started (single instance)');
   *
   *     // 应用主逻辑
   *     while True do
   *     begin
   *       // 处理事件
   *       Sleep(100);
   *     end;
   *   finally
   *     guard := nil; // 退出时自动释放
   *   end;
   * end.
   * ```
   *
   * **示例 3: 生产者-消费者模式（使用信号量）**
   *
   * ```pascal
   * program ProducerConsumerExample;
   *
   * uses
   *   fafafa.core.sync.namedSemaphore;
   *
   * // 生产者进程
   * procedure Producer;
   * var
   *   semaphore: INamedSemaphore;
   *   i: Integer;
   * begin
   *   semaphore := MakeNamedSemaphore('myapp_items', 0, 10);
   *
   *   for i := 1 to 5 do
   *   begin
   *     WriteLn('Producing item ', i);
   *     Sleep(500);
   *     semaphore.Release; // 增加计数
   *   end;
   * end;
   *
   * // 消费者进程
   * procedure Consumer;
   * var
   *   semaphore: INamedSemaphore;
   *   guard: INamedSemaphoreGuard;
   *   i: Integer;
   * begin
   *   semaphore := MakeNamedSemaphore('myapp_items', 0, 10);
   *
   *   for i := 1 to 5 do
   *   begin
   *     guard := semaphore.Wait; // 等待项目可用
   *     try
   *       WriteLn('Consuming item ', i);
   *       Sleep(1000);
   *     finally
   *       guard := nil;
   *     end;
   *   end;
   * end;
   *
   * begin
   *   // 根据命令行参数决定角色
   *   if ParamCount > 0 then
   *   begin
   *     if ParamStr(1) = 'producer' then
   *       Producer
   *     else if ParamStr(1) = 'consumer' then
   *       Consumer;
   *   end;
   * end.
   * ```
   *
   * **示例 4: 事件通知模式**
   *
   * ```pascal
   * program EventNotificationExample;
   *
   * uses
   *   fafafa.core.sync.namedEvent;
   *
   * // 等待者进程
   * procedure Waiter;
   * var
   *   event: INamedEvent;
   *   guard: INamedEventGuard;
   * begin
   *   event := MakeNamedEvent('myapp_ready_event', AutoResetNamedEventConfig);
   *
   *   WriteLn('Waiting for event...');
   *   guard := event.Wait;
   *   try
   *     WriteLn('Event received! Starting work...');
   *     // 执行工作
   *   finally
   *     guard := nil;
   *   end;
   * end;
   *
   * // 通知者进程
   * procedure Notifier;
   * var
   *   event: INamedEvent;
   * begin
   *   event := MakeNamedEvent('myapp_ready_event', AutoResetNamedEventConfig);
   *
   *   WriteLn('Preparing...');
   *   Sleep(2000);
   *
   *   WriteLn('Signaling event...');
   *   event.Signal;
   * end;
   *
   * begin
   *   if ParamCount > 0 then
   *   begin
   *     if ParamStr(1) = 'waiter' then
   *       Waiter
   *     else if ParamStr(1) = 'notifier' then
   *       Notifier;
   *   end;
   * end.
   * ```
   *
   * **示例 5: 读写锁模式（多读者单写者）**
   *
   * ```pascal
   * program ReaderWriterExample;
   *
   * uses
   *   fafafa.core.sync.namedRWLock;
   *
   * var
   *   rwlock: INamedRWLock;
   *
   * // 读者进程
   * procedure Reader(AId: Integer);
   * var
   *   guard: INamedRWLockReadGuard;
   * begin
   *   rwlock := MakeNamedRWLock('myapp_data_lock');
   *
   *   guard := rwlock.Read;
   *   try
   *     WriteLn('Reader ', AId, ': Reading data...');
   *     Sleep(1000);
   *     WriteLn('Reader ', AId, ': Done reading');
   *   finally
   *     guard := nil;
   *   end;
   * end;
   *
   * // 写者进程
   * procedure Writer(AId: Integer);
   * var
   *   guard: INamedRWLockWriteGuard;
   * begin
   *   rwlock := MakeNamedRWLock('myapp_data_lock');
   *
   *   guard := rwlock.Write;
   *   try
   *     WriteLn('Writer ', AId, ': Writing data...');
   *     Sleep(2000);
   *     WriteLn('Writer ', AId, ': Done writing');
   *   finally
   *     guard := nil;
   *   end;
   * end;
   *
   * begin
   *   if ParamCount > 1 then
   *   begin
   *     if ParamStr(1) = 'reader' then
   *       Reader(StrToInt(ParamStr(2)))
   *     else if ParamStr(1) = 'writer' then
   *       Writer(StrToInt(ParamStr(2)));
   *   end;
   * end.
   * ```
   *
   * **示例 6: 错误处理和超时**
   *
   * ```pascal
   * program ErrorHandlingExample;
   *
   * uses
   *   fafafa.core.sync.namedMutex, fafafa.core.sync.base;
   *
   * var
   *   mutex: INamedMutex;
   *   guard: INamedMutexGuard;
   * begin
   *   try
   *     mutex := MakeNamedMutex('myapp_lock');
   *
   *     // 尝试获取锁，最多等待 5 秒
   *     guard := mutex.TryLockForNamed(5000);
   *
   *     if not guard.IsLocked then
   *     begin
   *       WriteLn('Failed to acquire lock within 5 seconds');
   *       Halt(1);
   *     end;
   *
   *     try
   *       WriteLn('Lock acquired, performing work...');
   *       // 执行工作
   *     finally
   *       guard := nil;
   *     end;
   *   except
   *     on E: ELockError do
   *     begin
   *       WriteLn('Lock error: ', E.Message);
   *       case E.LockResult of
   *         lrTimeout: WriteLn('Timeout occurred');
   *         lrError: WriteLn('System error occurred');
   *       end;
   *     end;
   *   end;
   * end.
   * ```
   *
   * **示例 7: 条件变量模式（等待条件满足）**
   *
   * ```pascal
   * program ConditionVariableExample;
   *
   * uses
   *   fafafa.core.sync.namedCondvar, fafafa.core.sync.namedMutex;
   *
   * var
   *   condvar: INamedCondVar;
   *   mutex: INamedMutex;
   *   ready: Boolean = False;
   *
   * // 等待者进程
   * procedure Waiter;
   * var
   *   guard: INamedMutexGuard;
   * begin
   *   condvar := MakeNamedCondVar('myapp_condition');
   *   mutex := MakeNamedMutex('myapp_condition_mutex');
   *
   *   guard := mutex.LockNamed;
   *   try
   *     WriteLn('Waiting for condition...');
   *
   *     // 使用 while 循环防止虚假唤醒
   *     while not ready do
   *       condvar.Wait(guard);
   *
   *     WriteLn('Condition met! Proceeding...');
   *   finally
   *     guard := nil;
   *   end;
   * end;
   *
   * // 通知者进程
   * procedure Notifier;
   * var
   *   guard: INamedMutexGuard;
   * begin
   *   condvar := MakeNamedCondVar('myapp_condition');
   *   mutex := MakeNamedMutex('myapp_condition_mutex');
   *
   *   Sleep(2000);
   *
   *   guard := mutex.LockNamed;
   *   try
   *     ready := True;
   *     WriteLn('Condition set, signaling...');
   *     condvar.Signal;
   *   finally
   *     guard := nil;
   *   end;
   * end;
   *
   * begin
   *   if ParamCount > 0 then
   *   begin
   *     if ParamStr(1) = 'waiter' then
   *       Waiter
   *     else if ParamStr(1) = 'notifier' then
   *       Notifier;
   *   end;
   * end.
   * ```
   *
   * **示例 8: 屏障同步（多进程同步点）**
   *
   * ```pascal
   * program BarrierExample;
   *
   * uses
   *   fafafa.core.sync.namedBarrier;
   *
   * var
   *   barrier: INamedBarrier;
   *   processId: Integer;
   * begin
   *   if ParamCount < 1 then
   *   begin
   *     WriteLn('Usage: BarrierExample <process_id>');
   *     Halt(1);
   *   end;
   *
   *   processId := StrToInt(ParamStr(1));
   *
   *   // 创建屏障，等待 3 个进程
   *   barrier := MakeNamedBarrier('myapp_sync_point', 3);
   *
   *   WriteLn('Process ', processId, ': Doing work...');
   *   Sleep(Random(2000));
   *
   *   WriteLn('Process ', processId, ': Waiting at barrier...');
   *   barrier.Wait;
   *
   *   WriteLn('Process ', processId, ': All processes synchronized!');
   * end.
   * ```
   *
   * **示例 9: 跨平台安全命名**
   *
   * ```pascal
   * program SafeNamingExample;
   *
   * uses
   *   fafafa.core.sync.namedMutex, SysUtils;
   *
   * function SafeNamedObjectName(const AAppName, APurpose: string): string;
   * begin
   *   // 1. 使用应用名称前缀
   *   Result := AAppName + '_' + APurpose;
   *
   *   // 2. 替换不安全字符
   *   Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
   *   Result := StringReplace(Result, '\', '_', [rfReplaceAll]);
   *   Result := StringReplace(Result, ':', '_', [rfReplaceAll]);
   *
   *   // 3. 限制长度（POSIX 信号量限制）
   *   if Length(Result) > 250 then
   *     Result := Copy(Result, 1, 250);
   *
   *   // 4. 确保以字母开头
   *   if not (Result[1] in ['A'..'Z', 'a'..'z']) then
   *     Result := 'n_' + Result;
   * end;
   *
   * var
   *   mutex: INamedMutex;
   *   safeName: string;
   * begin
   *   safeName := SafeNamedObjectName('MyApp', 'database/lock');
   *   WriteLn('Safe name: ', safeName);
   *
   *   mutex := MakeNamedMutex(safeName);
   *   WriteLn('Mutex created successfully');
   * end.
   * ```
   *
   * **示例 10: 资源池管理（使用信号量）**
   *
   * ```pascal
   * program ResourcePoolExample;
   *
   * uses
   *   fafafa.core.sync.namedSemaphore;
   *
   * const
   *   MAX_CONNECTIONS = 5;
   *
   * var
   *   connectionPool: INamedSemaphore;
   *   guard: INamedSemaphoreGuard;
   *   connectionId: Integer;
   * begin
   *   // 创建信号量，初始值 = 最大连接数
   *   connectionPool := MakeNamedSemaphore('myapp_connection_pool',
   *                                         MAX_CONNECTIONS, MAX_CONNECTIONS);
   *
   *   WriteLn('Acquiring connection from pool...');
   *   guard := connectionPool.Wait;
   *   try
   *     connectionId := Random(1000);
   *     WriteLn('Connection ', connectionId, ' acquired');
   *
   *     // 使用连接
   *     Sleep(2000);
   *
   *     WriteLn('Connection ', connectionId, ' released');
   *   finally
   *     guard := nil; // 自动释放信号量
   *   end;
   * end.
   * ```
   *
   * **最佳实践总结**：
   *
   * 1. **始终使用 RAII 守卫**：
   *    - 使用 `INamedMutexGuard`、`INamedSemaphoreGuard` 等
   *    - 在 `try-finally` 块中释放守卫
   *    - 避免手动调用 `Release()`
   *
   * 2. **处理超时和错误**：
   *    - 使用 `TryLockForNamed()` 而不是无限等待
   *    - 捕获 `ELockError` 异常
   *    - 检查 `guard.IsLocked` 状态
   *
   * 3. **使用安全的命名约定**：
   *    - 包含应用名称前缀
   *    - 避免特殊字符
   *    - 限制名称长度
   *
   * 4. **条件变量使用 while 循环**：
   *    - 防止虚假唤醒
   *    - 确保条件真正满足
   *
   * 5. **跨平台考虑**：
   *    - 测试 Unix 和 Windows 平台
   *    - 处理平台特定的权限问题
   *    - 考虑持久化差异
   *
   * @see examples/fafafa.core.sync/ - 更多完整示例
   *}

  // ===== 配置结构 =====
  TNamedMutexConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次�?
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialOwner: Boolean;         // 是否初始拥有
  end;

// 配置辅助函数
function DefaultNamedMutexConfig: TNamedMutexConfig;
function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
function GlobalNamedMutexConfig: TNamedMutexConfig;

type
  // ===== RAII 模式的互斥锁守卫 =====
  INamedMutexGuard = interface(ILockGuard)
    ['{A1B2C3D4-5E6F-7890-ABCD-EF1234567890}']
    function GetName: string;           // 获取互斥锁名称
    // 析构时自动释放锁，无需手动调用 Release
  end;

  // ===== 现代化的命名互斥锁接口 =====
  // 注意：使用 LockNamed/TryLockNamed 避免与父接口 ILock 的方法签名冲突
  INamedMutex = interface(ILock)
    ['{F2A8B4C6-3D7E-4F9A-8B1C-5E6D9A2F4B8C}']
    // 核心锁操作 - 返回 RAII 守卫（带名称信息）
    function LockNamed: INamedMutexGuard;                              // 阻塞获取
    function TryLockNamed: INamedMutexGuard;                          // 非阻塞尝试
    function TryLockForNamed(ATimeoutMs: Cardinal): INamedMutexGuard; // 带超时获取

    // 查询操作
    function GetName: string;           // 获取互斥锁名称
    function GetHandle: Pointer;        // 获取底层互斥锁句柄（供 NamedCondVar 使用）
  end;

implementation

function DefaultNamedMutexConfig: TNamedMutexConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超�?
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重�?00�?
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialOwner := False;       // 默认不初始拥�?
end;

function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
begin
  Result := DefaultNamedMutexConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedMutexConfig: TNamedMutexConfig;
begin
  Result := DefaultNamedMutexConfig;
  Result.UseGlobalNamespace := True;
end;

end.
