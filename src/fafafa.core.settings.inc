{ fafafa.core.settings.inc 框架配置文件 }
{ Macro hygiene: Use BOOL defines for IFDEF; use *_VALUE for value macros; never shadow API names }

{$MACRO ON}  // enable simple value-style macros like {$DEFINE NAME := value}

{$DEFINE FAFAFA_OS_CACHE_PROBES}




{ Result: method-style API is macro-gated; default OFF }
{.$DEFINE FAFAFA_CORE_RESULT_METHODS}


{$DEFINE FAFAFA_COLOR_ENABLE_LOWL_HUE_SNAPPING}

{$DEFINE FAFAFA_COLOR_ENABLE_BRUTE_HUE_LOCK}



{ Use COM-style interfaces globally for reference-counted lifetimes across the framework }
{$interfaces COM}


{ Auto-drain stdout/stderr when waiting on a process to avoid pipe-buffer deadlocks }
{$DEFINE FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}

{ Enable inline 开启内联 }
{.$DEFINE FAFAFA_CORE_INLINE}
{$DEFINE FAFAFA_CORE_INLINE}

{$IFDEF FAFAFA_CORE_INLINE}
  {$INLINE ON}
{$ENDIF}


{ Strict range checks for EraseAfter: enable reachability check in non-DEBUG builds too }
{ 在非 DEBUG 构建下也启用 EraseAfter 的可达性严格检查 }
{.$DEFINE FAFAFA_CORE_STRICT_ERASEAFTER}

{
  Enable crt memcpy, memmove, etc.
  Priority to using libc under linux, Performance of windows crt is not good, so it is not used.
  in linux, you need to link the libc library.
  启用 crt memcpy, memmove.
  在linux下,优先使用 libc, windows crt 性能表现不佳,无所谓.
  在linux下,开启此选项意味着要链接libc库.
}
{.$DEFINE FAFAFA_CORE_CRT_MEMCPY}
{.$DEFINE FAFAFA_CORE_CRT_MEMMOVE}

{
  Enable predefined common generic types,
  which may lead to code bloat but allows for worry-free use of these types directly.
  启用预定义的常用泛型类型, 这会带来代码膨胀, 但直接用预定义的泛型类型, 是件省心的事情.
}
{.$DEFINE FAFAFA_CORE_TYPE_ALIASES} // Predefine common generic types 预定义常用泛型类型

{
  Enable crt allocator, use malloc, calloc, realloc, free, etc.
  in linux, if you want to use the crt allocator, you need to link the libc library.
  启用 crt 分配器, 使用 malloc, calloc, realloc, free 等函数.
  在linux下,开启此选项意味着要链接libc库.
}
{$DEFINE FAFAFA_CORE_CRT_ALLOCATOR}

{
  Enable mimalloc allocator (dynamic library required at runtime).
  启用 mimalloc 分配器（运行期需提供 mimalloc 动态库）。
}
{$DEFINE FAFAFA_CORE_MIMALLOC_ALLOCATOR}


{
  Enable static link/import for mimalloc.
  When enabled, allocator.mimalloc binds to symbols at link time (no delayed loading).
  启用 mimalloc 静态链接/导入。开启后 mimalloc 通过 external 在链接期绑定，不再延迟加载。
}
{.$DEFINE FAFAFA_CORE_MIMALLOC_STATIC}

{
  Anonymous functions/references are only supported in fpc 3.3.1 and above.
  开启匿名函数/匿名引用 仅限 fpc 3.3.1 及以上
}
{$IF FPC_FULLVERSION >= 030301}
  {$IFNDEF FAFAFA_FORCE_NO_ANON}
    {$DEFINE FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {$ENDIF}
{$ENDIF}

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {$ModeSwitch functionreferences}
  {$ModeSwitch anonymousfunctions}
{$ENDIF}

{
  Process module configuration 进程模块配置
  Controls the implementation mode for the process module.
  控制进程模块的实现模式。
}

{
  Enable real process implementation instead of mock implementation.
  Comment out to use mock implementation (default for development/testing).
  Uncomment to enable real platform implementation (for production).
  启用真实进程实现而不是模拟实现。
  注释掉以使用模拟实现（开发/测试默认）。
  取消注释以启用真实平台实现（生产环境）。
}
{$DEFINE FAFAFA_REAL_PROCESS_IMPLEMENTATION}

{
  Enable verbose logging for process module in debug mode.
  在调试模式下启用进程模块的详细日志。
}
{$IFDEF DEBUG}
  {$DEFINE FAFAFA_PROCESS_VERBOSE_LOGGING}
{$ENDIF}

{
  Optional feature flags for process module
  进程模块可选特性开关（默认关闭，避免破坏现有行为）
}

{ Enable minimal ShellExecuteEx support on Windows (no redirection or custom env)
  启用最小的 ShellExecuteEx 支持（Windows，仅“打开”类场景，禁用重定向与自定义环境） }
{.$DEFINE FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}

{ Enable process groups / job objects support (KillTree/TerminateGroup)
  启用进程组/作业对象支持（KillTree/TerminateGroup 功能） }
{.$DEFINE FAFAFA_PROCESS_GROUPS}


{ Thread module debug diagnostics 线程模块调试诊断（仅 DEBUG 构建） }
{$IFDEF DEBUG}
  {$DEFINE FAFAFA_THREAD_DEBUG}
  {$DEFINE FAFAFA_CORE_SOCKET_DEBUG_GUARD}
{$ENDIF}


{ Thread Select mode 线程 Select 模式（默认：非轮询，匿名引用可用时生效） }
{ 若需强制回退到轮询实现，请定义 FAFAFA_THREAD_SELECT_FORCE_POLLING }
{$IFNDEF FAFAFA_THREAD_SELECT_FORCE_POLLING}
  {$DEFINE FAFAFA_THREAD_SELECT_NONPOLLING}
{$ENDIF}


{$DEFINE FAFAFA_SCHEDULER_DEBUG_LOG}

{ GHASH / CLMUL 后端开关：x86_64 Release 默认启用，DEBUG 下需显式 env 开启 }
{$IFDEF CPUX86_64}
  {$IFNDEF DEBUG}
    {$DEFINE FAFAFA_CRYPTO_X86_CLMUL}
  {$ENDIF}
{$ENDIF}

{ Socket module experimental toggles 套接字模块实验性功能开关（默认关闭） }
{ 打开这些宏将启用平台特定的高性能轮询器与异步Socket实现 }
{.$DEFINE FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{.$DEFINE FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}

{ IOCP debug strict assert (only effective when FAFAFA_SOCKET_POLLER_EXPERIMENTAL and DEBUG) }
{ IOCP 调试严格断言（仅在启用 IOCP 宏且 DEBUG 时生效；默认关闭） }
{.$DEFINE FAFAFA_IOCP_DEBUG_STRICT_ASSERT}

{ IOCP debug verbose logs (DEBUG only). When enabled, logs per-event details and pending lists. Default OFF }
{ IOCP 调试详细日志（仅 DEBUG）。开启后输出每次事件与挂起列表，默认关闭以减少噪音 }
{.$DEFINE FAFAFA_IOCP_DEBUG_VERBOSE}

{ Terminal module configuration 终端模块配置 }
{ Controls the implementation mode for the terminal module. }
{ 控制终端模块的实现模式。 }





{ Socket advanced API toggles 套接字高级API开关（默认关闭，逐步开放） }
{.$DEFINE FAFAFA_SOCKET_ADVANCED}

{
  Enable wide character input support for terminal module.
  启用终端模块的宽字符输入支持。
}
{$DEFINE FAFAFA_TERM_INPUT_WIDE}

{
  Enable inline functions for terminal module.
  启用终端模块的内联函数。
}
{$DEFINE FAFAFA_TERM_INLINE}

{ 如果启用内联,顺便开启rtl内联标记 }
{$IFDEF FAFAFA_TERM_INLINE}
  {$INLINE ON}
{$ENDIF}

{ Terminal + SignalCenter integration 开关 }
{ 默认开启：统一由 signal center 分发 SIGWINCH，可在此处注释以回退 }
{$DEFINE FAFAFA_TERM_USE_SIGNALCENTER_WINCH}





{ Collections facade 工厂族：开启门面 Make* 工厂（ForwardList/List/Deque/Queue/Stack）}
{$DEFINE FAFAFA_COLLECTIONS_FACADE}


{ Args.config module feature toggles 参数配置模块特性开关 }
{ 默认启用 TOML（已有最小实现），JSON/YAML 暂不启用 }
{$DEFINE FAFAFA_ARGS_CONFIG_TOML}
{$DEFINE FAFAFA_ARGS_CONFIG_JSON}
{.$DEFINE FAFAFA_ARGS_CONFIG_YAML}

{ Args module platform behavior 参数模块平台行为 }
{ Windows: collect argv via wide-char API to avoid codepage loss; can be disabled }
{$DEFINE FAFAFA_ARGS_WIN_WIDE}



{ Signal module configuration 信号模块配置 }
{ 默认启用常见信号/控制台事件安装；可按需裁剪 }
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGINT}
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGTERM}
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGHUP}
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGUSR1}
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGUSR2}
{$DEFINE FAFAFA_SIGNAL_ENABLE_SIGWINCH}
{$DEFINE FAFAFA_SIGNAL_ENABLE_WIN_CTRL}



{ JSON module configuration JSON 模块配置 }

{ Validate UTF-8 strictly in reader unless explicitly allowed via flags }
{$DEFINE FAFAFA_JSON_VALIDATE_UTF8}

{ Disable non-standard features at compile time (comments, trailing commas, Inf/NaN, invalid unicode). Off by default }
{.$DEFINE FAFAFA_JSON_DISABLE_NON_STANDARD}

{ Allow compile-time stripping of reader/writer to reduce binary size }
{.$DEFINE FAFAFA_JSON_DISABLE_READER}
{.$DEFINE FAFAFA_JSON_DISABLE_WRITER}


{ Test report JSON cleanup optional fields 测试报告 JSON cleanup 可选字段 }
{ 默认关闭：保持兼容。若需在 cleanup 项中记录时间戳，取消下一行注释 }
{$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS}


{ CSV module configuration CSV 模块配置 }


{ Test report JSON cleanup timestamp format controls }
{ 精度：取消下一行注释以将 ts 精度降为秒；默认毫秒 }
{.$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS_PRECISION_SEC}
{ 时区：取消下一行注释以输出本地偏移（+HH:MM）；默认 UTC Z }
{.$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS_TZ_LOCAL_OFFSET}

{ Enforce strict RFC4180 semantics by default (field counts, quoting rules). Can be commented out to relax defaults }
{$DEFINE FAFAFA_CSV_STRICT_RFC4180}

{ Allow compile-time stripping of reader/writer to reduce binary size }
{.$DEFINE FAFAFA_CSV_DISABLE_READER}
{.$DEFINE FAFAFA_CSV_DISABLE_WRITER}

{ CSV Escape handling is controlled at runtime via Dialect.Escape (default #0 = disabled).
  Double-quote doubling and Escape may both be supported; prefer configuring one explicitly per dialect. }


{ Report sinks configuration 报告 Sink 配置 }
{ 默认启用 Console Sink 使用 ITextSink；如需强制退回 WriteLn，请注释下一行 }
{$DEFINE FAFAFA_REPORT_CONSOLE_USE_ITEXTSINK}

{ FS module optional performance toggles (default OFF) }
{.$DEFINE FS_USE_PREAD}        // Unix: prefer pread/pwrite (atomic offset IO)
{.$DEFINE FS_USE_OVERLAPPED}   // Windows: alternate overlapped strategy experiments


{ FS module behavior toggles 行为开关 }
{$DEFINE FS_UNIFIED_ERRORS}         // 统一负错误码（跨平台一致）
{$DEFINE FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH}    // Windows: 启用长路径（为绝对路径接近上限时追加 \\?\ / \\?\UNC\ 前缀）




{ 在 Release 构建中默认启用缓存行填充以减少伪共享（DEBUG 下关闭以避免布局扰动影响调试） }
{$IFNDEF DEBUG}
  {$DEFINE FAFAFA_LOCKFREE_CACHELINE_PAD}
{$ENDIF}

{ Lock-free module optional performance toggles 无锁模块可选性能开关（默认关闭） }
{.$DEFINE FAFAFA_LOCKFREE_CACHELINE_PAD}          { 在关键状态字段间加入缓存行填充以降低伪共享 }
{.$DEFINE FAFAFA_LOCKFREE_BACKOFF}                { 在高冲突 CAS 重试时进行轻量退避 }

{ 可选：退避参数（仅在启用 FAFAFA_LOCKFREE_BACKOFF 时生效） }
{.$DEFINE FAFAFA_LOCKFREE_BACKOFF_EVERY := 64}    { 每多少次失败执行一次退避 }

{ 在 Release 构建中默认启用无锁退避策略，减少高冲突尾延迟（DEBUG 下保持关闭便于定位问题） }
{$IFNDEF DEBUG}
  {$DEFINE FAFAFA_LOCKFREE_BACKOFF}
{$ENDIF}

{.$DEFINE FAFAFA_LOCKFREE_BACKOFF_SLEEP_MS := 0}  { 退避的 Sleep 毫秒数，0 表示 Yield 风格 }


{ Benchmark module behavior toggles 基准模块行为开关 }
{ By default, library code should not write to console. Enable this to auto-report in Bench* helpers }
{ 默认情况下，库代码不应直接写控制台。启用此宏可在 Bench* 快手接口中自动输出报告 }
{.$DEFINE FAFAFA_CORE_BENCH_AUTO_REPORT}

{ Sync module optional Windows toggles 同步模块 Windows 可选开关 }
{ 使用 Windows 条件变量（CONDITION_VARIABLE）与 CRITICAL_SECTION 严格语义实现 CondVar.Wait* }
{.$DEFINE FAFAFA_SYNC_USE_CONDVAR}
{ 使用 SRWLOCK 优化读写锁（写锁非递归），默认关闭以避免影响现有行为 }
{.$DEFINE FAFAFA_SYNC_USE_SRWLOCK}

