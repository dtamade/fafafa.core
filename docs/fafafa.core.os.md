# fafafa.core.os


- 目录
  - 快速上手：示例输出
  - 构建与运行示例
  - API 概览
  - Result-based API 迁移指南（推荐）
  - 设计与实现说明
  - 平台差异与回退策略（摘要）
  - 版本映射与时区解析（细化）
  - Windows 10/11 常见 Build 对照（示例）
  - 常见问题（FAQ）

现代化、跨平台的 OS 助手模块，提供：
- 环境变量管理（get/set/unset/environ）
- 基础系统信息（主机名、用户名、CPU 数、页大小、临时目录、可执行路径等）
- 统一的 `TPlatformInfo` 汇总结构
- 增强系统信息（CPU/内存/存储/网络/负载，带 Result 版本）
- **Result-based API**：统一错误处理，支持链式操作（推荐使用）

参考设计：
- Rust: std::env, std::fs (信息侧), std::process（接口边界）
- Go: os, filepath（路径相关约定复用至 fs.path）
- Java: System, Files（信息/属性接口设计）


## 快速上手：示例输出

- Linux（示例化）：
  - VersionDetailed: Ubuntu (22.04)
  - Kernel: 5.15.0
  - Uptime(s): 456789
  - Mem: total=34359738368 free=17179869184
  - BootTime: 1700000000
  - Timezone: Etc/UTC
  - CPU model: Intel(R) Xeon(R) Platinum 8272CL CPU @ 2.60GHz
  - Locale: en-US



示例：example_basic 的 JSON 输出
- 全量 JSON：example_basic --json
- 美化 JSON：example_basic --json --pretty
- 帮助：example_basic --help

示例：JSON 输出与字段筛选
- 子集字段（文本模式）：example_basic --fields=platform,version,kernel

- 全量 JSON：example_capabilities --json
- 美化 JSON：example_capabilities --json --pretty
- 子集字段：example_capabilities --json --fields=kernel,cpu,locale
- 帮助：example_capabilities --help

- 输出到文件（JSON）：example_capabilities --json --output=out.json

示例 JSON 片段（example_capabilities --json --pretty，示例化）：
```
{
  "version": {
    "name": "Ubuntu",
    "version": "22.04",
    "build": "",
    "prettyName": "Ubuntu 22.04.4 LTS",
    "id": "ubuntu",
    "idLike": "debian"
  },
  "kernel": "5.15.0-1051-azure",
  "uptime": 456789,
  "memory": { "total": 34359738368, "free": 17179869184 },
  "boottime": 1700000000,
  "timezone": "Etc/UTC",
  "cpuModel": "Intel(R) Xeon(R) Platinum 8272CL CPU @ 2.60GHz",
  "locale": "en-US",
  "capabilities": { "admin": false, "wsl": false, "container": true, "ci": true }
}
```


Windows 示例 JSON 片段（example_capabilities --json --pretty，示例化）：
```
{
  "version": {
    "name": "Windows 11 23H2",
    "version": "10.0",
    "build": "22631"
  },
  "kernel": "10.0.22631",
  "uptime": 123456,
  "memory": { "total": 17179869184, "free": 8589934592 },
  "boottime": 1700000000,
  "timezone": "China Standard Time",
  "cpuModel": "Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz",
  "locale": "zh-CN",
  "capabilities": { "admin": true, "wsl": false, "container": false, "ci": false }
}
```

macOS 示例 JSON 片段（example_capabilities --json --pretty，示例化）：
```
{
  "version": {
    "name": "macOS",
    "version": "14",
    "build": "",
    "codename": "Sonoma",
    "prettyName": "macOS 14 (Sonoma)",
    "id": "macos",
    "idLike": "darwin"
  },
  "kernel": "23.5.0",
  "uptime": 234567,
  "memory": { "total": 17179869184, "free": 4294967296 },
  "boottime": 1700000000,
  "timezone": "America/Los_Angeles",
  "cpuModel": "Apple M2",
  "locale": "en-US",
  "capabilities": { "admin": false, "wsl": false, "container": false, "ci": false }
}
```

- macOS（示例化）：
  - VersionDetailed: macOS (13)
  - Kernel: 22.5.0
  - Uptime(s): 234567
  - Mem: total=17179869184 free=4294967296
  - BootTime: 1700000000
  - Timezone: America/Los_Angeles

## 命令行参数概览（示例工程）

- example_basic
  - --json：JSON 输出；配合 --pretty 美化
  - --fields=platform,version,kernel,uptime,memory,boottime,timezone,cpu,locale,capabilities,env（文本模式）
  - --help：显示用法

- example_capabilities
  - --json：JSON 输出；配合 --pretty 美化
  - --fields=version,kernel,uptime,memory,boottime,timezone,cpu,locale,capabilities
  - --output=path：将 JSON 写入文件（失败回退 stdout）
  - --help：显示用法

  - CPU model: Apple M2
  - Locale: en-US

## 字段字典（JSON 输出）

- version
  - name: 系统名称（Windows/Ubuntu/macOS 等）；来源：Windows 映射/Unix NAME/macOS 回退映射；可能为空：否
  - version: 系统版本（Windows=major.minor；Linux=/etc/os-release VERSION_ID；macOS=主版本）；可能为空：是
  - build: 构建号（主要 Windows）；可能为空：是
  - codename: 代号（Linux VERSION；macOS 回退映射，如 Sonoma）；可能为空：是
  - prettyName: 人类可读名称（Linux PRETTY_NAME；macOS 组合）；可能为空：是
  - id: 发行版标识（Linux /etc/os-release ID）；可能为空：是
  - idLike: 近似标识（Linux /etc/os-release ID_LIKE）；可能为空：是
- kernel: 内核/系统内核版本（Windows=10.0.x；Unix=uname -r）；可能为空：是
- uptime: 自启动秒数；可能为 0
- memory
  - total: 物理内存总字节数；可能为 0（不可用时）
  - free: 可用物理内存字节数；可能为 0（不可用时）
- storage: 挂载点信息数组（path/filesystem/total/available/used/isRemovable/isReadOnly）
- network: 网卡数组（name/hwaddr/mtu/speed/bytesSent/bytesReceived/isUp/isLoopback）
- load: 系统负载（load1/5/15、running/total 进程数；不可用时为 -1）
- boottime: 启动时间（Epoch 秒，回退计算/读取；TSystemInfo.BootTime 同语义）；可能为 0
- timezone: 时区（Windows 返回 StandardName，如 China Standard Time；Unix 返回 TZ 或解析）；可能为空：是
- timezoneIana: IANA 时区（Windows 通过映射获取，如 Asia/Shanghai；Unix 同 timezone）；可能为空：是
- cpuModel: CPU 型号（Windows 注册表/环境变量；Linux /proc/cpuinfo）；可能为空：是
- locale: 规范化区域（如 zh-CN；Windows 使用 LOCALE_SNAME；Unix 由 LANG/LC_* 规范化）；可能为空：是
- capabilities
  - admin: 是否管理员（Windows 以 Administrators 组判定；Unix=uid=0）；布尔
  - wsl: 是否 WSL 环境（Linux osrelease 包含 Microsoft）；布尔
  - container: 是否容器（检测 /.dockerenv、/proc/1/cgroup 等）；布尔
  - ci: 是否 CI 环境（CI/GITHUB_ACTIONS/GITLAB_CI 等变量）；布尔
- platform（仅 example_basic JSON）
  - os/arch/is64/endian/cpuCount/pageSize/host/user/home/temp/exe：来自 TPlatformInfo；arch 现支持 amd64/386/arm64/arm/riscv64（其余标注 unknown）；可能为空：部分字段

注：所有字段遵循“最佳努力 + 安全回退”，不可用或无法判定时返回空串/0/省略，且不抛异常。



## 从 JSON 读取关键字段（消费示例）

- Linux/macOS（bash + jq）
  - 直接管道：
    - ./examples/fafafa.core.os/buildOrRun_capabilities.sh --json | jq -r '.version.name, .version.prettyName, .kernel'
  - 读取文件：
    - jq -r '.version.id, .version.idLike, .capabilities' out/os_info.json

- Windows（PowerShell）
  - $j = Get-Content .\out\os_info.json | ConvertFrom-Json
  - $j.version.name; $j.version.prettyName; $j.kernel; $j.capabilities.admin

- 提示
  - 部分字段可能为空或缺失（按平台与“最佳努力 + 安全回退”策略），使用时请做好空值处理
  - 如需只输出子集，示例程序支持 --fields（capabilities 支持在 JSON 下筛选；basic 支持文本模式筛选）

以下为 example_capabilities 的代表性输出（示例化，实际值可能不同）：

- VersionDetailed: Windows 11 23H2 (10.0 build 22631)
- Kernel: 10.0.22631
- Uptime(s): 123456
- Mem: total=17179869184 free=8589934592
## 当前行为与限制
- 非 Linux 平台的高级探测（内存/存储/网络/负载）尚未实现，返回 `False` / `TResult.Err(oseNotSupported)`；调用方需检查并回退。
- CI 作业：Linux x86_64/ARM64 实际运行 tests_os；Windows/macOS 作业可能因工具链缺失软失败，但会上传测试日志与二进制。
- 缓存：FAFAFA_OS_CACHE_PROBES 默认开启，可用 `os_cache_reset/_ex` 清空；并发访问已加锁。

## 构建与测试（Linux）
- 构建单测：`lazbuild --build-all tests/fafafa.core.os/fafafa.core.os.test.lpi`
- 运行单测：`./tests/fafafa.core.os/bin/tests_os --all --format=plain`
- 示例运行：`cd examples/fafafa.core.os && ./buildOrRun.sh --target=system_info --run --json --pretty`

## 调试工具
- `tests/fafafa.core.os/plays_no_proc.sh`：在无 /proc 的隔离 mount namespace 中运行 tests_os（需要 `unshare` 与 CAP_SYS_ADMIN），用于验证回退路径。仅供本地手工使用。

## 参考补充
- 管理员判定与 Locale 规范化：见 docs/partials/os.admin_and_locale.md
- Windows StandardName → IANA 映射：见 docs/partials/os.timezone_mappings.md
- Darwin → macOS 版本映射：见 docs/partials/macos.version_mapping.md
- BootTime: 1700000000
- Timezone: Asia/Shanghai
- CPU model: Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz
- Locale: zh-CN
- Admin? True  WSL? False  Container? False  CI? False


## 构建与运行示例

- 构建 example_basic
  - tools\lazbuild.bat examples\fafafa.core.os\example_basic.lpi
  - 运行：examples\fafafa.core.os\bin\example_basic.exe
- 构建 example_capabilities
  - tools\lazbuild.bat examples\fafafa.core.os\example_capabilities.lpi
  - 运行：examples\fafafa.core.os\bin\example_capabilities.exe

- 构建 example_strict（严格语义变体演示）
  - tools\lazbuild.bat examples\fafafa.core.os\example_strict.lpi
  - 运行：examples\fafafa.core.os\bin\example_strict.exe

## API 概览

### 基础 API（简单场景）
- function os_getenv(const AName: string): string;
- function os_setenv(const AName, AValue: string): Boolean;
- function os_unsetenv(const AName: string): Boolean;
- procedure os_environ(const ADest: TStrings);
- function os_hostname: string;
- function os_username: string;
- function os_home_dir: string;
- function os_temp_dir: string;
- function os_exe_path: string;
- function os_cpu_count: Integer;
- function os_page_size: Integer;
- function os_platform_info: TPlatformInfo;
- function os_kernel_version: string;
- function os_uptime: QWord;
- function os_memory_info(out totalBytes, freeBytes: QWord): Boolean;
- function os_boot_time: QWord;
- function os_timezone: string;
- function os_timezone_iana: string;
- function os_is_admin: Boolean;
- function os_is_wsl: Boolean;
- function os_is_container: Boolean;
- function os_is_ci: Boolean;

### 严格语义变体（Boolean + out）
- function os_exe_path_ex(out APath: string): Boolean
- function os_home_dir_ex(out APath: string): Boolean
- function os_username_ex(out AName: string): Boolean
- function os_hostname_ex(out S: string): Boolean
- function os_temp_dir_ex(out S: string): Boolean
- function os_kernel_version_ex(out S: string): Boolean
- function os_timezone_ex(out S: string): Boolean
- function os_timezone_iana_ex(out S: string): Boolean
- function os_os_version_detailed_ex(out V: TOSVersionDetailed): Boolean
- function os_exe_dir_ex(out ADir: string): Boolean

### Result-based API（推荐使用）
- function os_getenv_result(const AName: string): TOSStringResult;
- function os_lookupenv_result(const AName: string): TOSStringResult;
- function os_setenv_result(const AName, AValue: string): TOSBoolResult;
- function os_unsetenv_result(const AName: string): TOSBoolResult;
- function os_hostname_result: TOSStringResult;
- function os_username_result: TOSStringResult;
- function os_home_dir_result: TOSStringResult;
- function os_temp_dir_result: TOSStringResult;
- function os_exe_path_result: TOSStringResult;
- function os_exe_dir_result: TOSStringResult;
- function os_kernel_version_result: TOSStringResult;
- function os_timezone_result: TOSStringResult;
- function os_timezone_iana_result: TOSStringResult;
- function os_cpu_model_result: TOSStringResult;
- function os_locale_current_result: TOSStringResult;
- function os_cpu_count_result: TOSIntResult;
- function os_page_size_result: TOSIntResult;
- function os_uptime_result: TOSQWordResult;
- function os_boot_time_result: TOSQWordResult;
- function os_is_admin_result: TOSBoolResult;
- function os_is_wsl_result: TOSBoolResult;
- function os_is_container_result: TOSBoolResult;
- function os_is_ci_result: TOSBoolResult;

### 增强系统信息 API（Result 版本）
- function os_cpu_info: TCPUInfoResult;
- function os_memory_info_detailed: TMemoryInfoResult;
- function os_storage_info: TStorageInfoArrayResult;
- function os_network_interfaces: TNetworkInterfaceArrayResult;
- function os_system_load: TSystemLoadResult;
- function os_system_info: TSystemInfoResult;

## Result-based API 迁移指南（推荐）

### 为什么使用 Result-based API？
Result-based API 提供统一的错误处理机制，灵感来自 Rust 的 Result 类型：
- **明确的错误类型**：通过 TOSError 枚举区分不同错误原因
- **链式操作**：支持 Map、MapErr 等函数式操作
- **无异常**：所有错误通过返回值传递，不抛出异常
- **类型安全**：编译时检查错误处理

### 迁移示例

**旧代码（基础 API）：**
```pascal
var
  LHostname: string;
begin
  LHostname := os_hostname;
  if LHostname = '' then
    WriteLn('获取主机名失败')
  else
    WriteLn('主机名: ', LHostname);
end;
```

**新代码（Result-based API）：**
```pascal
var
  LResult: TOSStringResult;
begin
  LResult := os_hostname_result;
  if LResult.IsOk then
    WriteLn('主机名: ', LResult.Unwrap)
  else
    WriteLn('获取主机名失败: ', OSErrorToString(LResult.UnwrapErr));
end;
```

### 错误处理示例

```pascal
var
  LResult: TOSStringResult;
begin
  LResult := os_getenv_result('MY_VAR');
  case LResult.IsOk of
    True: WriteLn('值: ', LResult.Unwrap);
    False:
      case LResult.UnwrapErr of
        oseNotFound: WriteLn('环境变量不存在');
        oseInvalidInput: WriteLn('无效的变量名');
        else WriteLn('系统错误');
      end;
  end;
end;
```

### API 对照表

| 基础 API | Result-based API | 说明 |
|----------|------------------|------|
| os_getenv | os_getenv_result | 获取环境变量 |
| os_hostname | os_hostname_result | 获取主机名 |
| os_username | os_username_result | 获取用户名 |
| os_home_dir | os_home_dir_result | 获取主目录 |
| os_temp_dir | os_temp_dir_result | 获取临时目录 |
| os_exe_path | os_exe_path_result | 获取可执行文件路径 |
| os_cpu_count | os_cpu_count_result | 获取 CPU 核心数 |
| os_is_admin | os_is_admin_result | 检测管理员权限 |

### TOSVersionDetailed 字段说明
- Name：系统名称（Windows/Linux/macOS 等）
- VersionString：系统版本字符串（Windows 为 major.minor 或 10；Linux 为 /etc/os-release VERSION_ID；macOS 为主版本）
- Build：构建号（Windows），Linux/macOS 可能为空
- Codename：代号（Linux VERSION；macOS 映射，如 Ventura/Sonoma/Sequoia）
- PrettyName：人类可读（Linux PRETTY_NAME；macOS 组合形式 macOS <ver> (<Codename>)）
- ID：Linux 发行版标识（/etc/os-release ID）
- IDLike：Linux 近似标识（/etc/os-release ID_LIKE）

### macOS Darwin → macOS 映射（回退）
- Darwin 22 → macOS 13 (Ventura)
- Darwin 23 → macOS 14 (Sonoma)
- Darwin 24 → macOS 15 (Sequoia)

注：以上为最佳努力回退。优先从系统提供的信息获取；不可用时做启发式映射，字段可能为空。


## 设计与实现说明

- 条件编译分发：Windows 使用 WinAPI（GetEnvironmentStringsW, GetComputerNameW, GetSystemInfo）与注册表（CurrentVersion/CurrentBuildNumber/ProductName/DisplayVersion），Unix 使用 BaseUnix/fpsetenv/fpunsetenv 等
- UTF-8 约定：测试/示例使用 {$CODEPAGE UTF8}
- 依赖最小化：不引入额外单元；路径和文件职责留在 fafafa.core.fs/path 模块
- 平台实现分层：主单元仅保留接口与公共逻辑，平台差异实现拆分在 inc 文件中按条件编译包含
  - Windows: src/fafafa.core.os.windows.inc（环境快照、主机名、页大小、目录策略等）
  - Unix:    src/fafafa.core.os.unix.inc（fpsetenv/fpunsetenv、fpgethostname、_SC_PAGESIZE 等）

## 平台差异与回退策略（摘要）

- os_kernel_version
  - Windows: GetVersionExW → "major.minor.build"；失败返回空串
  - Unix: fpUname().release；失败返回空串
- os_uptime
  - Windows: GetTickCount64/1000（自启动秒数）；失败返回 0
  - Linux: 读取 /proc/uptime（字段1）；不可用返回 0
  - macOS/BSD: sysctl(kern.boottime) + 当前时间（gettimeofday）计算差值；失败返回 0
- os_memory_info(out total, free)
  - Windows: GlobalMemoryStatusEx（Phys 总量/可用）；失败回退 GlobalMemoryStatus；失败返回 False
  - Linux: 解析 /proc/meminfo（MemTotal/MemAvailable，单位 kB→B）
  - macOS: sysctl(hw.memsize) + host_statistics64 获取空闲/非活跃页 × pagesize；失败返回 False
- os_boot_time
  - Windows: DateTimeToUnix(Now) - os_uptime（秒）；若 uptime=0 则返回 0
  - Linux: 读取 /proc/stat 中 btime（秒）；失败返回 0
  - macOS/BSD: sysctl(kern.boottime)；失败返回 0
- os_timezone
  - Windows: GetTimeZoneInformation.StandardName；失败空串
  - Unix: 返回 TZ 环境变量（若未设置则空串）
- os_is_admin
  - Windows: CheckTokenMembership（失败/不可用时安全回退 False）
  - Unix: getuid=0 为 True，否则 False
- os_is_wsl
  - Unix(Linux): /proc/sys/kernel/osrelease 包含 "Microsoft" → True；否则 False
  - Windows: False
- os_is_container
  - Unix: 存在 /.dockerenv 或 /run/.containerenv → True；或 /proc/1/cgroup 含 docker/containerd/kubepods → True；否则 False
  - Windows: 默认 False（后续可拓展）
- os_is_ci
  - 检测环境变量：CI、GITHUB_ACTIONS、GITLAB_CI、BUILD_BUILDID 等任一存在即 True；否则 False

注：所有能力探测均为“最佳努力与安全回退”，不可用或无法判定时应返回 False/空串/0，不抛异常。

### 版本映射与时区解析（细化）
- Windows 版本名（示例策略）
  - Major=10 且 Build ≥ 22000 → Windows 11
  - Major=10 且 Build < 22000 → Windows 10

## 缓存与刷新（最佳实践）
- 为降低重复调用开销，模块对以下探测结果启用进程级轻量缓存（并发安全，临界区保护，默认开启 `FAFAFA_OS_CACHE_PROBES`）：
  - Windows/Unix: os_timezone、os_kernel_version、os_os_version_detailed、os_cpu_model
  - Windows: os_timezone_iana、os_is_admin
  - Unix: os_timezone_iana 等同 os_timezone（reset oscTimezoneIana 会一并清理 timezone 缓存）
- 关闭缓存：编辑 src/fafafa.core.settings.inc 注释掉宏 FAFAFA_OS_CACHE_PROBES 即可；禁用后按无缓存路径执行。
- 刷新缓存：在运行时调用 os_cache_reset 或 os_cache_reset_ex([oscTimezone, ...]) 清空所需缓存（适用于长进程在权限或环境变量更改后刷新）。
- 语义保证：缓存不改变返回语义，仅优化性能；未命中信息仍按原逻辑回退。

  - 其它 → Windows（保留 VersionString 与 Build 供上层更细化）
- Unix 时区优先级
  1) 环境变量 TZ
  2) /etc/timezone（若存在且非空）
  3) 解析 readlink(/etc/localtime) 的 …/zoneinfo/Region/City 尾段


参见附录：docs/partials/os.admin_and_locale.md

另见：docs/partials/os.timezone_mappings.md（Windows StandardName → IANA 映射表，最佳努力）
另见：docs/partials/macos.version_mapping.md（Darwin → macOS 版本映射，最佳努力）

## 平台覆盖矩阵（摘要）
说明：以下为常用函数在不同平台上的来源与回退；“可能为空”表示在该平台/环境下无法可靠获取时返回空串或0。

- os_locale_current
  - Windows: GetLocaleInfoW(LOCALE_SNAME)；可能为空：低概率
  - Linux: 解析 LANG/LC_*（下划线转连字符），可能为空：中
### Windows 版本识别键与回退（参考）
- 注册表路径：HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion
- 推荐读取键：
  - ProductName：产品名称（Windows 11/10 等），人类可读
  - DisplayVersion：功能更新版本（如 22H2/23H2），新系统可用
  - CurrentVersion：主/次版本（如 10.0）
  - CurrentBuildNumber：构建号（如 22631）
  - UBR：更新 Build 修订（可选）
- 回退：
  - 若上述键不可用，回退 GetVersionEx（可能受兼容性清单影响，精度有限）
- Caveats：
  - GetVersionEx 在缺失清单时可能返回较低版本；建议以注册表为主，GetVersionEx 仅作最后回退
  - 产品名与显示版本可能随渠道/本地化有所差异，建议在 UI 展示与日志中并列显示 version/build

  - macOS/BSD: 同 Linux 解析；可能为空：中

- os_timezone（本地时区名）
  - Windows: GetTimeZoneInformation.StandardName（如 China Standard Time）；可能为空：低
  - Linux: 优先 TZ；其次 /etc/timezone；再次 readlink(/etc/localtime) 提取 …/zoneinfo/Region/City；可能为空：低-中
  - macOS/BSD: 优先 TZ；其次 readlink(/etc/localtime)；可能为空：中

- os_timezone_iana（IANA 标识）
  - Windows: 由 StandardName 映射（最佳努力，未命中返回空）；可能为空：中
  - Unix: 与 os_timezone 等同（通常即 IANA）；可能为空：与 os_timezone 一致

- os_kernel_version
  - Windows: 注册表 CurrentVersion/CurrentBuildNumber → a.b.build；回退 GetVersionEx；可能为空：极低
  - Linux: uname -r（或 /proc 接口）；可能为空：低
  - macOS/BSD: uname -r；可能为空：低

- os_os_version_detailed
  - Windows: 注册表 ProductName/DisplayVersion/CurrentVersion/CurrentBuildNumber；回退 GetVersionEx 推断；可能为空：极低
  - Linux: 发行版未覆盖（保持空/通用名），VersionString 通常由 uname/内核推导；可能为空：中
  - macOS/BSD: 计划中（Darwin→macOS 映射）；当前返回通用名；可能为空：中

- os_memory_info
  - Windows: GlobalMemoryStatusEx；可能为空：极低
  - Linux: 解析 /proc/meminfo（MemTotal/MemAvailable）；可能为空：低（非 Linux 上为空）
  - macOS/BSD: 计划中（回退为空）

- os_cpu_model
  - Windows: 注册表 HARDWARE\...\CentralProcessor\0\ProcessorNameString；回退 PROCESSOR_IDENTIFIER；可能为空：低
  - Linux: 解析 /proc/cpuinfo model name；可能为空：低（非 Linux 上为空）
  - macOS: 计划中（sysctl machdep.cpu.brand_string）；当前为空
  - BSD: 计划中；当前为空

- os_uptime / os_boot_time
  - Windows: GetTickCount64 + 系统时间换算；可能为空：极低
  - Linux: /proc/uptime 或 sysfs；可能为空：低（非 Linux 上为空）
  - macOS/BSD: 计划中；当前为空

- os_is_admin
  - Windows: 通过 TokenGroups 比对 S-1-5-32-544；可能为空：否（布尔）
  - Unix: 检查 geteuid=0；可能为空：否（布尔）

- 路径类（home/temp/exe_path）
  - Windows: SHGetKnownFolderPath/Env/GetModuleFileNameW；可能为空：极低
  - Unix: 环境变量 + 约定目录 + /proc/self/exe（Linux）；可能为空：低

## FAQ（常见问题）
- Windows 的 timezone 为什么不是 IANA？
  - Windows API 返回 StandardName（如 China Standard Time），本库提供 os_timezone_iana 做最佳努力映射；未命中时返回空串，上层可选择回退。
- GetVersionEx 不是不可信？
  - 是，因此实现优先读取注册表 CurrentVersion/CurrentBuildNumber 等，GetVersionEx 仅作回退。
- 缓存会不会影响正确性？
  - 缓存不改变语义，仅减少重复探测开销；可通过 FAFAFA_OS_CACHE_PROBES 关闭，或在运行时调用 os_cache_reset 刷新。




## 常见问题（FAQ）

- 为什么 os_is_admin 在 Windows 下返回 False？
  - 可能原因：未以“管理员权限”启动（UAC 未提升）、组策略限制、AppContainer/服务上下文差异。
  - 我们通过 Administrators 组 SID（S-1-5-32-544）在 TokenGroups 中判定成员关系；若调用失败或信息不足，将安全回退 False。
  - 如需确定提升状态，请以管理员启动命令行或使用显式提升流程。

- 为什么 Unix/容器中 os_timezone 为空？
  - 可能原因：TZ 未设置、镜像未安装 tzdata、/etc/timezone 不存在、/etc/localtime 不是指向 zoneinfo 的 symlink。
  - 解决建议：设置 TZ（如 Asia/Shanghai），或安装 tzdata，并确保 /etc/localtime 正确指向 /usr/share/zoneinfo/*。

- os_locale_current 输出为空或格式与预期不完全一致？
  - 我们从 LANG→LC_ALL→LC_MESSAGES→LC_CTYPE 取首个非空，并规范为 language-REGION，剔除编码（.UTF-8）、修饰符（@...）与候选（:...）。
  - 若环境为 C/POSIX 或未设置相关变量，则可能为空或为 C。建议在运行环境中设置 LANG（如 zh_CN.UTF-8）。

- Windows 版本映射不精确？
  - GetVersionEx 的返回可能受兼容性清单影响；映射表为启发式，便于展示。对于生产级识别建议结合 WMI/注册表做更精细解析。

- os_memory_info/os_boot_time 返回 0？
  - 在不具备 /proc 的 Unix（或精简容器）可能不可用；Windows 回退使用 GlobalMemoryStatus 以及通过 uptime 推算 boot time。
  - 我们遵循“最佳努力 + 安全回退”，不可用时返回 False/0/空串，不抛异常。

- 容器/WSL/CI 判断与实际不一致？
  - 这些判断均基于启发式（cgroup/osrelease/环境变量），不同平台/内核定制可能出现偏差。可在上层结合更多信号或允许用户覆盖。


### Windows 10/11 常见 Build 对照（示例）
- 11:
  - 22621+ → 22H2+
  - 22000–22620 → 21H2
- 10:
  - 19045 → 22H2
  - 19044 → 21H2
  - 19043 → 21H1
  - 19042 → 20H2
  - 19041 → 2004
  - 22631 → 23H2
  - 26100 → 24H2（预览/GA 以实际系统为准）

（其余回退为 Windows 10/11 基础名称；以上列表可按需扩展）

  - 主单元实现节（inc 与主单元同目录，故无需 src/ 前缀）：
    {$IFDEF WINDOWS}
    {$I fafafa.core.os.windows.inc}
    {$ELSE}
    {$I fafafa.core.os.unix.inc}
    {$ENDIF}
- 错误修复：Windows 环境枚举释放使用 PStart（GetEnvironmentStringsW 返回的起始指针），避免释放被移动的指针


## 后续计划
- 进程/会话/用户 UID/GID 等更完整系统信息（可选）
- 环境变量快照/差异工具
- 平台能力探测（是否 WSL、容器等）

