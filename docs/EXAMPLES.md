# 示例总表（新增）

- fafafa.core.os
  - example_basic：基础信息与 JSON 输出
  - example_capabilities：能力检测与 JSON 输出（可选字段、输出到文件）
  - example_strict：严格语义变体示例（os_exe_path_ex/os_home_dir_ex/os_username_ex）


# fafafa.core.fs 使用示例

> See also: Collections
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md

## 集合模块示例总表（TVec / TVecDeque）

- 文档入口

## JSON for-in 与 Pointer 默认值（新）

参见：docs/partials/json.forin_and_pointer_defaults.md

要点：
- for-in 枚举：JsonArrayItems / JsonObjectPairs / JsonObjectPairsUtf8
- 指针默认值：JsonGet[Int/UInt/Bool/Float/Str/Utf8]OrDefaultByPtr
- UTF-8 键：JsonHasKeyUtf8 / JsonGetValueUtf8（注意在测试/示例单元使用 {$CODEPAGE UTF8}）

  - 概览：docs/fafafa.core.collections.md
  - TVec：docs/fafafa.core.collections.vec.md
  - TVecDeque：docs/fafafa.core.collections.vecdeque.md 或 docs/TVecDeque_Guide.md
  - API 索引：docs/API_collections.md

- 一键示例（Windows）
  - TVecDeque：examples\fafafa.core.collections.vecdeque\BuildOrTest_Examples.bat
  - TVec：examples\fafafa.core.collections.vec\BuildOrTest_Examples.bat

- 一键示例（Linux/macOS）
  - TVecDeque：examples/fafafa.core.collections.vecdeque/BuildOrTest_Examples.sh
  - TVec：examples/fafafa.core.collections.vec/BuildOrTest_Examples.sh

- 典型场景
  - TVecDeque：
    - 对象/接口注入策略：example_growth_object_based_min.lpr / example_growth_interface_based_min.lpr
    - 页对齐策略：example_growth_page_aligned_min.lpr / example_growth_page_aligned_portable_min.lpr
  - TVec：
    - Ensure vs EnsureCapacity：example_ensure_vs_capacity/example_ensure_vs_capacity.lpr
    - ReserveExact/Exact 最小示例：example_exact_and_reserveexact_min.lpr

- 示例索引与说明
  - Collections 示例索引与一键脚本：examples/fafafa.core.collections/README.md

## 文件系统模块示例总表（fafafa.core.fs）

- 文档入口
  - docs/fafafa.core.fs.md（含示例输出/FAQ、最佳实践）

- 一键示例（Windows）
  - examples\fafafa.core.fs\RunExamples.bat（批量）
  - examples\fafafa.core.fs\example_resolve_and_walk\buildOrRun.bat（最小）

- 一键示例（Linux/macOS）
  - examples/fafafa.core.fs/build.sh（批量）

- 典型场景
  - 路径解析与遍历：example_resolve_and_walk
  - 原子写入：example_writefileatomic
  - 复制/移动树：example_copytree_follow、example_copytree_preserve


## 加密模块示例总表（fafafa.core.crypto）

- 文档入口
  - docs/fafafa.core.crypto.md（总体）
  - docs/fafafa.core.crypto.aead.md（AEAD 接口与用法、契约、脚本与期望输出）

- 一键示例
  - Windows：examples\fafafa.core.crypto\BuildOrRun_MinExample.bat
  - Linux/macOS：examples/fafafa.core.crypto/BuildOrRun_MinExample.sh

- 示例源码
  - 最小 AEAD Append/In‑Place：examples/fafafa.core.crypto/example_aead_inplace_append_min.pas

- 说明
  - 若 lazbuild 未在 PATH，请设置 LAZBUILD_EXE 环境变量指向 lazbuild 可执行文件
  - 构建失败排查：
    - 脚本优先构建 .lpi，若不存在回退构建 .pas；失败会输出退出码
    - 检查 lazbuild 是否可用：设置 LAZBUILD_EXE 或将 lazbuild 加入 PATH

- Crypto 快速验证（Smoke Test）
  - Windows：scripts\verify-crypto-examples.bat [--no-run] [--clean]
  - Linux/macOS：./scripts/verify-crypto-examples.sh [--no-run] [--clean]
  - 校验 AEAD 的 run.log 与文件加解密的 fileenc.log；比较原始/解密文件内容相同；错误密码输出文件不应存在
  - Windows (PowerShell)：scripts\\verify-crypto-examples.ps1 [-NoRun] [-Clean]


    - 检查 src 搜索路径：.lpi 的 OtherUnitFiles=../../src；直接构建 .pas 时也需可解析 src
    - 检查 .lpi 的 Target.Filename 与脚本查找的输出路径是否一致（默认 bin/）


- Crypto 一键串联入口（AEAD → FileEncryption → 可选清理）
  - Windows：scripts\run-crypto-examples.bat [--clean]
  - Linux/macOS：./scripts/run-crypto-examples.sh [--clean]
  - 自动展示 AEAD 的 run.log 与文件加解密的 fileenc.log，--clean 末尾清理输出



## 终端模块示例总表（fafafa.core.term）

- 文档入口
  - docs/fafafa.core.term.md（基础/输入/输出/能力探测）

- 一键示例（Windows）
  - examples\fafafa.core.term\BuildOrRun_CoreExamples.bat（核心示例）
  - examples\fafafa.core.term\BuildOrRun_UI_Showcase.bat（UI 展示）

- 一键示例（Linux/macOS）
  - examples/fafafa.core.term/build_examples.sh（核心示例）
  - examples/fafafa.core.term/BuildOrRun_UI_Showcase.sh（UI 展示，如存在）

- 典型场景
  - 终端尺寸/清屏：01_size_clear.lpr
  - 颜色/写入：02_color_write.lpr
  - 备用屏幕：03_alt_screen_demo.lpr
  - 输入轮询：04_event_poll_echo.lpr / 05_input_best_practices.lpr
  - 帧式循环：07_frame_loop_demo.lpr / examples/fafafa.core.term.ui
  - WINCH/尺寸变化：
    - 回调 + 帧内去抖：examples/fafafa.core.term/resize_layout_demo.lpr
    - Channel(capacity=1)：examples/fafafa.core.term/example_winch_channel.lpr
    - Windows 轮询 + 帧内去抖：examples/fafafa.core.term/example_win_winch_poll.lpr
    - 跨平台 portable：examples/fafafa.core.term/example_winch_portable.lpr
  - Paste 最佳实践速查：docs/partials/term.paste.best_practices.md


  - OrderedMap（TRBTreeMap）示例与性能演示：
    - 文档：docs/partials/collections.orderedmap.apis.md、docs/partials/collections.orderedmap.keys_values.md
    - 一键运行（Windows）：samples\Build_perf_demo.bat
    - 源文件：samples\orderedmap_perf_demo.pas

    - 范围分页：samples\Build_range_pagination.bat（源码 samples\orderedmap_range_pagination.pas）



    - 整数键分页：samples\Build_range_pagination_int.bat（源码 samples\orderedmap_range_pagination_int.lpr）





# CLI Args Examples (Index)

- Default subcommand and caller-owned help
  - examples/fafafa.core.args.command/example_usage_default
- Schema + Usage rendering (caller prints)
  - examples/fafafa.core.args.command/example_help_schema
- ENV → argv merge
  - examples/fafafa.core.args.command/example_env_merge

---
- 进程模块最佳实践与脚本：docs/fafafa.core.process.bestpractices.md（含 Unix 子集 run_spawn_subset.sh / run_spawn_groups_subset.sh）

- 进程模块 AutoDrain 最小示例：
  - Windows：examples\fafafa.core.process\run_autodrain.bat
  - Linux/macOS：examples/fafafa.core.process/run_autodrain.sh
  - 文档：docs/fafafa.core.process.md → “AutoDrain（自动排水）行为与边界” 与 “最佳实践：AutoDrain 读取示例”



---

# Runner/Benchmark Sink 开关最小示例

- 测试 Runner（Windows Powershell）
  - $env:FAFAFA_TEST_USE_SINK_CONSOLE='1'; tests\fafafa.core.test\bin\tests.exe --summary-only
  - $env:FAFAFA_TEST_USE_SINK_JSON='1'; tests\fafafa.core.test\bin\tests.exe --json=out\report.json --no-console
  - $env:FAFAFA_TEST_USE_SINK_JUNIT='1'; tests\fafafa.core.test\bin\tests.exe --junit=out\report.xml --no-console

- 测试 Runner（Linux/macOS bash）
  - FAFAFA_TEST_USE_SINK_CONSOLE=1 ./tests/fafafa.core.test/bin/tests --summary-only
  - FAFAFA_TEST_USE_SINK_JSON=1 ./tests/fafafa.core.test/bin/tests --json=out/report.json --no-console
  - FAFAFA_TEST_USE_SINK_JUNIT=1 ./tests/fafafa.core.test/bin/tests --junit=out/report.xml --no-console

- 基准（Windows Powershell）
  - $env:FAFAFA_BENCH_USE_SINK_CONSOLE='1'; tests\fafafa.core.benchmark\bin\tests_benchmark.exe --report=console
  - $env:FAFAFA_BENCH_USE_SINK_JSON='1'; tests\fafafa.core.benchmark\bin\tests_benchmark.exe --report=json --outfile=out\bench.json

- 基准（Linux/macOS bash）
  - FAFAFA_BENCH_USE_SINK_CONSOLE=1 ./tests/fafafa.core.benchmark/bin/tests_benchmark --report=console
  - FAFAFA_BENCH_USE_SINK_JSON=1 ./tests/fafafa.core.benchmark/bin/tests_benchmark --report=json --outfile=out/bench.json

- 一键脚本：
  - Windows：examples\sink.quick-switch.ps1 -target runner -sink json -outfile out\report.json
  - Linux/macOS：./examples/sink.quick-switch.sh runner json out/report.json


- Runner 最佳实践（统一产物路径与退出码）
  - Windows（PowerShell）：`scripts/run-tests-ci.ps1`
  - Linux/macOS（Bash）：`scripts/run-tests-ci.sh`
  - 用例清单输出（JSON）：
    - Windows：`powershell -File scripts\list-tests.ps1 -Filter core -CI`
    - Linux/macOS：`./scripts/list-tests.sh core`

## OS 模块示例索引（快速）

- 文档：docs/fafafa.core.os.md（快速上手/构建/FAQ/平台差异）
- 示例工程：
  - examples/fafafa.core.os/example_basic.lpi
  - examples/fafafa.core.os/example_capabilities.lpi
- 运行产物：examples/fafafa.core.os/bin
  - example_basic.exe / example_capabilities.exe（Windows）
  - Linux/macOS 可用 lazbuild 构建 .lpi 或直接 fpc（确保包含 src 搜索路径）
- 采集系统信息到 JSON 文件（Windows）
  - examples\fafafa.core.os\buildOrRun_capabilities.bat --json --output=out\os_info.json
- 采集系统信息到 JSON 文件（Linux/macOS）
  - ./examples/fafafa.core.os/buildOrRun_capabilities.sh --json --output=out/os_info.json



说明
- Sink 开关为可选；不设置则继续使用默认 Reporter
- JSON Sink（Benchmark）已与默认 JSON Reporter 位等，schema/字段/小数位一致，可安全启用
- 所有时间戳使用 UTC Z（RFC3339），利于跨平台确定性与对比


# JSON 最小示例（Flags / StopWhenDone）

- Windows（cmd.exe）
  - examples\fafafa.core.json\BuildOrRun_Min.bat
- Linux/macOS（bash）
  - examples/fafafa.core.json/BuildOrRun_Min.sh
- 注意事项（JSON Pointer）：空指针 "" 返回根；单独 "/" 与双斜杠空 token（如 "/a//x"）非法返回 nil；~0→~，~1→/
- 行为边界说明：docs/fafafa.core.json.md#flags

---

# fafafa.core.lockfree 接口/工厂与 MapEx Quickstart

## 独立工程（宏启用）一键构建与运行
- Windows（项目根目录，建议用 cmd 避免 PowerShell 解析问题）
```
cmd /c "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe tests\fafafa.core.lockfree\fafafa.core.lockfree.ifaces_factories.test.lpr && tests\fafafa.core.lockfree\bin\lockfree_ifaces_factories_tests.exe"
```

## SPSC/MPMC/Stack 工厂示例
```pascal
uses fafafa.core.lockfree.ifaces, fafafa.core.lockfree.factories;

var Qs := specialize NewSpscQueue<Integer>(1024);
var Qm := specialize NewMpmcQueue<Integer>(1024);
var S  := specialize NewTreiberStack<Integer>;
```

## MapEx（OA）示例
```pascal
function CaseInsensitiveHash(const S: string): Cardinal;
begin
  Result := SimpleHash(UpperCase(S), Length(S));
end;

function CaseInsensitiveEqual(const L, R: string): Boolean;
begin
  Result := SameText(L, R);
end;

uses fafafa.core.lockfree.ifaces, fafafa.core.lockfree.factories;

var M  : specialize ILockFreeMapEx<string, Integer>;
var Old: Integer;
var R  : TMapPutResult;
begin
  M := specialize NewOAHashMapExWithComparer<string,Integer>(64, @CaseInsensitiveHash, @CaseInsensitiveEqual);
  R := M.PutEx('Key', 1, Old);  // mprInserted, Old=0
  R := M.PutEx('KEY', 2, Old);  // mprUpdated,   Old=1
end;
```

更多说明与最佳实践见 docs/fafafa.core.lockfree.interfaces.md 与 docs/fafafa.core.lockfree.md。

---

---

## ⚙️ fafafa.core.lockfree 示例索引（Quick Start）

- 文档与选型：docs/fafafa.core.lockfree.md（选型矩阵、限制与注意、常用工厂速查、严格工厂示例）
- 一键构建与运行：
  - Windows：examples\fafafa.core.lockfree\BuildOrRun.bat run
  - Linux/macOS：examples/fafafa.core.lockfree/BuildOrRun.sh run
- 示例工程：
  - example_lockfree.lpi / bench_map_str_key.lpi
  - example_oa_strict_factories.lpr（OA 严格工厂：大小写不敏感字符串键、记录键）
- 提示：
  - OA 适合“键简单/装载≤0.7/删除少”；复杂键/自定义相等或高删除率请考虑 MM 或 OA 严格工厂
  - Destroy/Clear 必须在“无并发访问”时调用


## 🌐 fafafa.core.socket 示例索引

- 文档：docs/fafafa.core.socket.md → “测试与示例：快速开始” 与 “平台差异速览（Windows vs Unix）”
- 一键构建示例（Windows）：examples\fafafa.core.socket\build_examples.bat（Debug/Release 不存在将自动回退）
- 示例可执行：examples/fafafa.core.socket/bin（example_socket/echo_server/echo_client/udp_server/udp_client）
- 运行示例（Windows）：examples\fafafa.core.socket\run_example_socket.bat address-demo
- 运行示例（Linux/macOS）：使用 lazbuild 构建 .lpi 或参考 example_socket.lpr 源码
- 测试入口（Windows）：tests\fafafa.core.socket\buildOrTest.bat test/adv/test-perf
- 测试入口（Linux/macOS）：tests/fafafa.core.socket/buildOrTest.sh test/adv/perf
- 快速冒烟：tests\fafafa.core.socket\smoke.bat / tests/fafafa.core.socket/smoke.sh
- 按套件运行：buildOrTest.bat test --suite=TTestCase_Socket_Advanced / ./buildOrTest.sh test --suite=TTestCase_Socket_Advanced
- 树复制（FollowSymlinks 演示）
  - Windows：examples\fafafa.core.fs\example_copytree_follow\buildOrRun.bat
  - Linux/macOS：examples/fafafa.core.fs/example_copytree_follow/buildOrRun.sh


- 一键运行最小示例：
  - Windows：examples\fafafa.core.socket\run_example_min.bat
  - Linux/macOS：./examples/fafafa.core.socket/run_example_min.sh



## 🚀 快速开始示例


### 示例工程（一键运行）
- 路径：examples/fafafa.core.fs/example_resolve_and_walk
- 功能：ResolvePathEx（不触盘/触盘+跟随）与 WalkDir（PreFilter/PostFilter）
- Windows 构建与运行：examples\fafafa.core.fs\example_resolve_and_walk\buildOrRun.bat
- Linux/macOS 构建与运行：examples/fafafa.core.fs/example_resolve_and_walk/buildOrRun.sh


### 快速排查（构建/运行）
- 构建失败：Can't find unit fafafa.core.fs
  - 检查示例 .lpi 的 <OtherUnitFiles> 是否正确指向仓库 src 目录（例如 ../../../src 或根下的 src）
  - 使用 lazbuild 时确保工作目录正确，或在 .bat 中使用绝对路径
- 真实路径/长路径异常（Windows）
  - 确认系统 LongPathsEnabled；如需长路径行为，启用宏 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH
- 符号链接相关失败（Windows）
  - 需管理员权限或启用 Developer Mode；测试前设置 FAFAFA_TEST_SYMLINK=1
- 输出与预期不同

### OpenFileEx 与 FsOpts* 简单用法

```pascal
program OpenFileExDemo;

uses
  fafafa.core.fs.highlevel;

var
  F: IFsFile;
begin
  // 只读打开（使用便捷别名）
  F := OpenFileEx('hello.txt', FsOptsReadOnly);
  Writeln('Size=', F.Size);

  // 覆盖写（截断）
  F := OpenFileEx('out.txt', FsOptsWriteTruncate);
  F.WriteString('hi');
end.
```

  - ResolvePathEx 默认不触盘；若需真实路径，请传 TouchDisk=True；必要时配合 FollowLinks=True



### 基础文件操作

```pascal
program BasicFileOperations;

uses
  fafafa.core.fs.highlevel;


### PreFilter vs PostFilter 与 OnError

```pascal
// PreFilter：阻止进入 blocked 子树 → 不会触发 OnError
Opts := FsDefaultWalkOptions;
Opts.PreFilter := @PreSkipBlocked; // if dir name = 'blocked' then False
Opts.OnError := @OnErrCountContinue;
WalkDir(Root, Opts, @Visit);
Assert(ErrCount = 0);

// PostFilter：拒绝 blocked 目录，但仍会进入其子树 → 可能触发 OnError
Opts := FsDefaultWalkOptions;
Opts.PostFilter := @PostRejectBlocked; // if dir name = 'blocked' then False
Opts.OnError := @OnErrCountContinue;
WalkDir(Root, Opts, @Visit);
Assert(ErrCount >= 1); // 在 Unix 下对 chmod 000 的 blocked 目录
```

var

### FollowSymlinks 与 OnError

```pascal
// Valid symlink → no OnError
Opts := FsDefaultWalkOptions; Opts.FollowSymlinks := True; Opts.OnError := @OnErrCountContinue;
WalkDir(Root, Opts, @Visit);
Assert(ErrCount = 0);

// Broken symlink → OnError on Unix (Windows: lenient)
Opts := FsDefaultWalkOptions; Opts.FollowSymlinks := True; Opts.OnError := @OnErrCountContinue;
WalkDir(Root, Opts, @Visit);
{$IFDEF UNIX} Assert(ErrCount >= 1); {$ELSE} Assert(True); {$ENDIF}
```

  LFile: TFsFile;
  LContent: string;
begin
  LFile := TFsFile.Create;
  try
    // 创建并写入文件
    LFile.Open('hello.txt', fomCreate);
    LFile.WriteString('Hello, fafafa.core.fs!');
    LFile.Close;

    // 读取文件内容
    LFile.Open('hello.txt', fomRead);
    LContent := LFile.ReadString;
    LFile.Close;

    Writeln('文件内容: ', LContent);
  finally
    LFile.Free;
  end;
end.

### Walk OnError 最小示例

```pascal
program WalkOnErrorDemo;

uses
  fafafa.core.fs.highlevel;

type
  TWalker = class
  public
    function OnErrContinue(const Path: string; Error, Depth: Integer): TFsWalkErrorAction;
    function OnVisit(const Path: string; const St: TfsStat; Depth: Integer): Boolean;
  end;

function TWalker.OnErrContinue(const Path: string; Error, Depth: Integer): TFsWalkErrorAction;
begin
  Result := weaContinue; // 忽略错误继续
end;

function TWalker.OnVisit(const Path: string; const St: TfsStat; Depth: Integer): Boolean;
begin
  // 这里只做计数或打印
  Writeln(Path);
  Result := True;
end;

var
  W: TWalker;
  Opts: TFsWalkOptions;
  Rc: Integer;
begin
  W := TWalker.Create;
  try
    Opts := FsDefaultWalkOptions;
    Opts.OnError := @W.OnErrContinue;
    Rc := WalkDir('Z:\not_exists', Opts, @W.OnVisit);
    // Rc = 0 （根无效但被 continue 策略视作空遍历）
    Writeln('Rc=', Rc);
  finally
    W.Free;
  end;
end.
```

```

### 便利函数使用

```pascal
program ConvenienceFunctions;

uses
  fafafa.core.fs.highlevel;

var
  LContent: string;
  LData: TBytes;
begin
  // 简单的文本文件操作
  WriteTextFile('simple.txt', 'Simple text content');
  LContent := ReadTextFile('simple.txt');
  Writeln('内容: ', LContent);

  // 简单的二进制文件操作
  SetLength(LData, 3);
  LData[0] := $FF;
  LData[1] := $00;
  LData[2] := $AA;

  WriteBinaryFile('binary.dat', LData);
  LData := ReadBinaryFile('binary.dat');
  Writeln('二进制数据长度: ', Length(LData));
end.
```


## ✅ 兼容两种构建模式的错误处理示例（FS_UNIFIED_ERRORS 开关）

如下示例演示：无论是否定义 FS_UNIFIED_ERRORS，均采用一致的错误分支逻辑。

```pascal
program UnifiedErrorHandling;

uses
  fafafa.core.fs, fafafa.core.fs.errors;

procedure DemoStat(const aPath: string);
var
  LStat: TfsStat;
  R: Integer;
  K: TFsErrorKind;
begin
  R := fs_stat(aPath, LStat);
  if R < 0 then
  begin
    // 最佳实践：优先用 FsErrorKind 分类，不依赖具体负值
    K := FsErrorKind(R);
    case K of
      fekNotFound:        Writeln('NotFound: ', aPath);
      fekPermission:      Writeln('Permission denied: ', aPath);
      fekInvalid:         Writeln('Invalid path: ', aPath);
      fekExists:          Writeln('Already exists (unexpected here): ', aPath);
      fekDiskFull:        Writeln('Disk full');
      fekIO:              Writeln('IO error');
    else
      Writeln('Unknown error: ', R);
    end;
  end
  else
    Writeln('Size: ', LStat.Size);
end;

procedure DemoOpen(const aPath: string);
var
  H: TfsFile;
  SysErr, FsErr: Integer;
begin
  H := fs_open(aPath, O_RDONLY, 0);
  if not IsValidHandle(H) then
  begin
    // fs_open 失败不返回负值，需取最近系统错，转换为统一码
    SysErr := GetSavedFsErrorCode();
    FsErr := SystemErrorToFsError(SysErr);
    Writeln('open failed: kind=', Ord(FsErrorKind(FsErr)), ' code=', FsErr);
    Exit;
  end;
  fs_close(H);
end;

begin
  DemoStat('nonexistent.file');
  DemoOpen('also_not_exist.file');
end.
```

## 🌍 国际化支持示例

### UTF-8多语言文件

```pascal
program MultiLanguageFile;

uses
  fafafa.core.fs.highlevel;

var
  LFile: TFsFile;
  LMultiLangText: string;
  LReadText: string;
begin
  // 创建包含多种语言的文本
  LMultiLangText := 'English Text' + LineEnding +
                    '中文内容' + LineEnding +
                    'Русский текст' + LineEnding +
                    'العربية' + LineEnding +
                    'Emoji: 🌍🔥💯';

  LFile := TFsFile.Create;
  try
    // 写入UTF-8文件
    LFile.Open('multilang.txt', fomCreate);
    LFile.WriteString(LMultiLangText);
    LFile.Close;

    // 读取并验证
    LFile.Open('multilang.txt', fomRead);
    LReadText := LFile.ReadString;
    LFile.Close;

    Writeln('多语言内容读取成功: ', LMultiLangText = LReadText);
  finally
    LFile.Free;
  end;
end.
```

## 🔒 安全路径处理示例

### 路径验证和清理

```pascal
program SecurePathHandling;

uses
  fafafa.core.fs.path,
  fafafa.core.fs.highlevel;

procedure TestPath(const aPath: string);
var
  LCleanPath: string;
begin
  Writeln('测试路径: ', aPath);

  if ValidatePath(aPath) then
  begin
    Writeln('  ✅ 路径安全');
    // 可以安全使用
  end
  else
  begin
    Writeln('  ❌ 路径不安全');
    LCleanPath := SanitizePath(aPath);
    Writeln('  🧹 清理后: ', LCleanPath);
  end;

  Writeln('');
end;

begin
  // 测试各种路径
  TestPath('safe/path/file.txt');           // 安全路径
  TestPath('../../../etc/passwd');          // 路径遍历攻击
  TestPath('file' + #0 + 'name.txt');       // 空字节注入
  TestPath('CON');                           // Windows保留名
  TestPath('%2e%2e/encoded.txt');           // URL编码攻击
  TestPath('file<name>.txt');               // 非法字符
end.
```

### 安全的用户输入处理

```pascal
program SecureUserInput;

uses
  fafafa.core.fs.path,
  fafafa.core.fs.highlevel;

function SafeOpenFile(const aUserPath: string): Boolean;
var
  LFile: TFsFile;
  LCleanPath: string;
begin
  Result := False;

  // 验证用户输入的路径
  if not ValidatePath(aUserPath) then
  begin
    Writeln('错误: 不安全的路径 - ', aUserPath);
    Exit;
  end;

  // 进一步清理路径
  LCleanPath := SanitizePath(aUserPath);

  // 确保路径在安全目录内
  if not IsSubPath(LCleanPath, 'safe_directory') then
  begin
    Writeln('错误: 路径超出安全范围');
    Exit;
  end;

  // 安全地打开文件
  LFile := TFsFile.Create;
  try
    LFile.Open(LCleanPath, fomRead);
    Writeln('成功打开文件: ', LCleanPath);
    LFile.Close;
    Result := True;
  except
    on E: Exception do
      Writeln('文件操作失败: ', E.Message);
  finally
    LFile.Free;
  end;
end;

var
  LUserInput: string;
begin
  // 模拟用户输入
  LUserInput := 'safe_directory/user_file.txt';
  SafeOpenFile(LUserInput);

  LUserInput := '../../../etc/passwd';
  SafeOpenFile(LUserInput);
end.
```

## ⚡ 高性能文件处理示例

### 大文件分块处理

```pascal
program LargeFileProcessing;

uses
  fafafa.core.fs.highlevel;

procedure ProcessLargeFile(const aFileName: string);
var
  LFile: TFsFile;
  LBuffer: TBytes;
  LBytesRead: Integer;
  LTotalBytes: Int64;
const
  CHUNK_SIZE = 64 * 1024; // 64KB块
begin
  LFile := TFsFile.Create;
  try
    LFile.Open(aFileName, fomRead);
    LTotalBytes := 0;

    Writeln('开始处理大文件: ', aFileName);
    Writeln('文件大小: ', LFile.Size, ' bytes');

    SetLength(LBuffer, CHUNK_SIZE);

    repeat
      LBytesRead := LFile.Read(LBuffer[0], CHUNK_SIZE);
      if LBytesRead > 0 then
      begin
        Inc(LTotalBytes, LBytesRead);

        // 处理数据块
        ProcessDataChunk(LBuffer, LBytesRead);

        // 显示进度
        Write(#13'进度: ', (LTotalBytes * 100) div LFile.Size, '%');
      end;
    until LBytesRead = 0;

    Writeln(#13'处理完成: ', LTotalBytes, ' bytes');
    LFile.Close;
  finally
    LFile.Free;
  end;
end;

procedure ProcessDataChunk(const aData: TBytes; aSize: Integer);
begin
  // 这里处理数据块
  // 例如：计算校验和、压缩、加密等
end;

begin
  // 创建测试大文件
  CreateTestLargeFile('large_test.dat', 10 * 1024 * 1024); // 10MB

  // 处理大文件
  ProcessLargeFile('large_test.dat');
end.
```

### 批量文件操作

```pascal
program BatchFileOperations;

uses
  fafafa.core.fs.highlevel,
  fafafa.core.fs.path;

procedure BatchProcessFiles(const aPattern: string);
var
  LFiles: TStringList;
  LI: Integer;
  LFile: TFsFile;
  LContent: string;
  LProcessedCount: Integer;
begin
  LFiles := TStringList.Create;
  LFile := TFsFile.Create;
  try
    // 查找匹配的文件（简化实现）
    FindFiles(aPattern, LFiles);

    Writeln('找到 ', LFiles.Count, ' 个文件');
    LProcessedCount := 0;

    for LI := 0 to LFiles.Count - 1 do
    begin
      try
        // 验证路径安全性
        if not ValidatePath(LFiles[LI]) then
        begin
          Writeln('跳过不安全路径: ', LFiles[LI]);
          Continue;
        end;

        // 处理文件
        LFile.Open(LFiles[LI], fomRead);
        LContent := LFile.ReadString;
        LFile.Close;

        // 执行处理逻辑
        LContent := ProcessFileContent(LContent);

        // 写回文件
        LFile.Open(LFiles[LI], fomWrite);
        LFile.WriteString(LContent);
        LFile.Close;

        Inc(LProcessedCount);
        Writeln('处理完成: ', LFiles[LI]);

      except
        on E: Exception do
          Writeln('处理失败 ', LFiles[LI], ': ', E.Message);
      end;
    end;

    Writeln('批量处理完成: ', LProcessedCount, '/', LFiles.Count);

  finally
    LFiles.Free;
    LFile.Free;
  end;
end;

function ProcessFileContent(const aContent: string): string;
begin
  // 示例：转换为大写
  Result := UpperCase(aContent);
end;

procedure FindFiles(const aPattern: string; aFiles: TStringList);
begin
  // 简化实现：添加一些测试文件
  aFiles.Add('test1.txt');
  aFiles.Add('test2.txt');
  aFiles.Add('test3.txt');
end;

begin
  BatchProcessFiles('*.txt');
end.
```

## 🔧 高级路径操作示例

### 路径解析和构造

```pascal
program AdvancedPathOperations;

uses
  fafafa.core.fs.path;

procedure DemoPathOperations;
var
  LPathInfo: TPathInfo;
  LJoinedPath: string;
  LParts: array[0..2] of string;
begin
  // 路径解析
  LPathInfo := ParsePath('C:\Projects\MyApp\src\main.pas');

  Writeln('路径解析结果:');
  Writeln('  完整路径: ', LPathInfo.Path);
  Writeln('  目录: ', LPathInfo.Directory);
  Writeln('  文件名: ', LPathInfo.FileName);
  Writeln('  基础名: ', LPathInfo.BaseName);
  Writeln('  扩展名: ', LPathInfo.Extension);
  Writeln('  是绝对路径: ', LPathInfo.IsAbsolute);
  Writeln('  文件存在: ', LPathInfo.Exists);
  Writeln('');

  // 路径构造
  LParts[0] := 'projects';
  LParts[1] := 'myapp';
  LParts[2] := 'main.pas';

  LJoinedPath := JoinPath(LParts);
  Writeln('构造的路径: ', LJoinedPath);

  // 路径转换
  Writeln('Unix风格: ', ToUnixPath(LJoinedPath));
  Writeln('Windows风格: ', ToWindowsPath(LJoinedPath));
  Writeln('标准化: ', NormalizePath(LJoinedPath));
  Writeln('');

  // 路径比较
  Writeln('路径比较:');
  Writeln('  相等: ', PathsEqual('dir/file.txt', 'dir\file.txt'));
  Writeln('  子路径: ', IsSubPath('dir/sub/file.txt', 'dir'));
end;

begin
  DemoPathOperations;
end.
```

## 🛡️ 错误处理示例

### 完整的错误处理

```pascal
program ComprehensiveErrorHandling;

uses
  fafafa.core.fs.highlevel,
  fafafa.core.fs.errors;

procedure SafeFileOperation(const aFileName: string);
var
  LFile: TFsFile;
  LContent: string;
begin
  LFile := TFsFile.Create;
  try
    try
      LFile.Open(aFileName, fomRead);
      LContent := LFile.ReadString;
      LFile.Close;

      Writeln('文件读取成功: ', Length(LContent), ' 字符');

    except
      on E: EFsError do
      begin
        case E.ErrorCode of
          FS_ERROR_FILE_NOT_FOUND:
            Writeln('错误: 文件不存在 - ', aFileName);
          FS_ERROR_ACCESS_DENIED:
            Writeln('错误: 访问被拒绝 - ', aFileName);
          FS_ERROR_INVALID_PATH:
            Writeln('错误: 无效路径 - ', aFileName);
          FS_ERROR_DISK_FULL:
            Writeln('错误: 磁盘空间不足');
          FS_ERROR_IO_ERROR:
            Writeln('错误: I/O错误 - ', E.Message);
          else
            Writeln('错误: 未知文件系统错误 (', Integer(E.ErrorCode), ') - ', E.Message);
        end;

        Writeln('系统错误代码: ', E.SystemErrorCode);
      end;

      on E: Exception do
        Writeln('意外错误: ', E.Message);
    end;

  finally
    LFile.Free;
  end;
end;

begin
  // 测试各种错误情况
  SafeFileOperation('existing_file.txt');      // 正常情况
  SafeFileOperation('nonexistent_file.txt');   // 文件不存在
  SafeFileOperation('');                        // 无效路径
  SafeFileOperation('../../../etc/passwd');    // 不安全路径
end.
```

## 🎯 实际应用示例

### 日志文件管理器

```pascal
program LogFileManager;

uses
  fafafa.core.fs.highlevel,
  fafafa.core.fs.path;

type
  TLogManager = class
  private
    FLogFile: TFsFile;
    FLogPath: string;
    FMaxSize: Int64;
  public
    constructor Create(const aLogPath: string; aMaxSize: Int64 = 10 * 1024 * 1024);
    destructor Destroy; override;

    procedure WriteLog(const aMessage: string);
    procedure RotateLog;
  end;

constructor TLogManager.Create(const aLogPath: string; aMaxSize: Int64);
begin
  inherited Create;

  if not ValidatePath(aLogPath) then
    raise Exception.Create('不安全的日志路径: ' + aLogPath);

  FLogPath := aLogPath;
  FMaxSize := aMaxSize;

---

## ❓ FAQ / Troubleshooting（fafafa.core.fs）

- Q: 为什么 `WalkDir('invalid_root', Opts, ...)` 在设置 `Opts.OnError = weaContinue` 后返回 0？
  - A: `weaContinue` 表示忽略该错误并继续遍历；当根路径本身无效时，整个遍历等价于“空遍历”，因此返回 0。
  - 默认行为（`OnError=nil`）：保持旧语义，根路径无效时直接返回统一负错误码（便于调用方快速失败）

- Q: 仍想拿到错误但不终止遍历？
  - A: 可以在 `OnError` 中记录日志/计数后返回 `weaContinue`，或对特定错误返回 `weaSkipSubtree` 以跳过当前子树

  FLogFile := TFsFile.Create;

  // 打开或创建日志文件
  if FileExists(FLogPath) then
    FLogFile.Open(FLogPath, fomAppend)
  else
    FLogFile.Open(FLogPath, fomCreate);
end;

destructor TLogManager.Destroy;
begin
  FLogFile.Free;
  inherited Destroy;
end;

procedure TLogManager.WriteLog(const aMessage: string);
var
  LLogEntry: string;
begin
  // 检查文件大小，必要时轮转
  if FLogFile.Size > FMaxSize then
    RotateLog;

  // 格式化日志条目
  LLogEntry := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + aMessage + LineEnding;

  // 写入日志
  FLogFile.WriteString(LLogEntry);
  FLogFile.Flush; // 确保立即写入磁盘
end;

procedure TLogManager.RotateLog;
var
  LBackupPath: string;
begin
  // 关闭当前日志文件
  FLogFile.Close;

  // 创建备份文件名
  LBackupPath := ChangeExtension(FLogPath, '.bak');

  // 删除旧备份
  if FileExists(LBackupPath) then
    DeleteFile(LBackupPath);

  // 重命名当前日志为备份
  RenameFile(FLogPath, LBackupPath);

  // 创建新的日志文件
  FLogFile.Open(FLogPath, fomCreate);
end;

var
  LLogManager: TLogManager;
  LI: Integer;
begin
  LLogManager := TLogManager.Create('application.log');
  try
    // 写入一些日志
    for LI := 1 to 100 do
      LLogManager.WriteLog('测试日志消息 #' + IntToStr(LI));

    Writeln('日志写入完成');
  finally
    LLogManager.Free;
  end;
end.
```

---

**💡 这些示例展示了fafafa.core.fs的强大功能和灵活性！**
