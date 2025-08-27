# fafafa.core.toml

模块职责
- 提供 TOML v1.0.0 解析与序列化能力，作为 fafafa.core 配置基础模块
- 设计遵循接口优先、跨平台、可扩展，借鉴 Rust/Go/Java 风格

当前能力
- Reader：字符串/整型/浮点/布尔、注释、换行 CRLF/LF/CR、dotted keys（含空格）、重复键/类型冲突检测、quoted/bare 键、Unicode 转义（\u/\U）
- Writer：递归输出嵌套表；字符串转义（含 \b/\f）；键名按需加引号（空格/非 bare 字符需加引号）；输出顺序稳定（标量→AoT→子表）；支持 flags：twfSortKeys、twfTightEquals、twfSpacesAroundEquals、twfPretty（注意：当同时指定 Spaces 与 Tight 时，以 Tight 优先；默认风格等同 Spaces）

核心 API（门面）
- Parse(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags = []): Boolean
- ParseV1(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError): Boolean
- ParseV2(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError): Boolean
- ToToml(const ADoc: ITomlDocument; const AFlags: TTomlWriteFlags = []): RawByteString
- ToTomlStream(const ADoc: ITomlDocument; const AStream: TStream; out AErr: TTomlError; const AFlags: TTomlWriteFlags = []): Boolean
- ToTomlFile(const ADoc: ITomlDocument; const AFileName: String; out AErr: TTomlError; const AFlags: TTomlWriteFlags = []): Boolean

Flags
- Read
  - trfDefault, trfStopWhenDone, trfAllowMixedNewlines（保留项）
  - trfUseV2：使用第二版解析器（parser.v2）。默认已经启用（Parse 默认即 V2）。如需强制旧版，请使用 trfUseV1。
- Write
  - twfSortKeys：按键名排序输出（根级/子表）
  - twfSpacesAroundEquals：等号两侧带空格（`key = value`），默认风格
  - twfTightEquals：紧凑等号（`key=value`）。当同时指定 `twfTightEquals` 与 `twfSpacesAroundEquals` 时，以 `twfTightEquals` 优先

新增通用 API
- Has(const ADoc: ITomlDocument; const APath: String): Boolean  判断路径是否存在
- TryGetValue(const ADoc: ITomlDocument; const APath: String; out AValue: ITomlValue): Boolean  获取原始值对象（标量/表/数组），仅判断存在性，不做类型强制

  - twfPretty：在表头前添加空行，提升可读性

使用示例（Reader）
```
var Doc: ITomlDocument; Err: TTomlError;
if Parse(RawByteString('a.b.c = "x"'), Doc, Err) then
  Writeln(Doc.Root.Contains('a'));
```

使用示例（Writer）
```
var S: RawByteString;
S := ToToml(Doc, [twfSortKeys, twfPretty]); // 默认空格等号
S := ToToml(Doc, [twfSortKeys, twfPretty, twfTightEquals]); // 紧凑等号

// Quoted 键、Pretty、SortKeys 示例
// 生成：
// [root]
// title = "TOML Test"
//
// [root."sub table"]
// a-b = 1
// f = 2.5
// "x y" = true
```

- Temporal 值写出
  - 当值类型为日期/时间族且缺少原始文本时，ToToml 将抛出异常（避免写入伪默认值）。请确保通过 Builder.PutTemporalText/工厂正确设置文本。

设计要点
- 键名大小写敏感；bare 键字符集 [A-Za-z0-9_-]；quoted 键支持转义（见下）
- 路径 Path 说明：当前 Get*/TryGet* 的路径仅支持以点分隔的 bare 键段，不支持含点或空格的键名作为段。建议：使用 Builder.BeginTable + quoted 键，或后续提供的 bracket 段（规划中）。
- 字符串转义：\" \\\ \n \r \t \b \f 以及 \uXXXX/\UXXXXXXXX（0..10FFFF，禁止代理项码点）
- 数值：严格下划线位置合法性；禁止 NaN/Inf/-Inf
- ITomlDocument/ITomlTable/ITomlValue 接口化；内部使用开放定址哈希存取，保持插入顺序
- dotted keys 采用“增量 ensure+下钻”，最终键仅写入最终子表；类型冲突/重复键严格报错
- Writer 递归输出：每表“标量→AoT→子表”，键名按需引号（含空格或非 [A-Za-z0-9_-] 的键需加引号），等号风格由 twfTightEquals/twfSpacesAroundEquals 控制（默认等价 Spaces）


## 字符串（单行/多行）
- 基本字符串（双引号）：支持转义 \" \\ \n \r \t \b \f、\uXXXX/\UXXXXXXXX
- 字面量字符串（单引号）：不处理转义；按字面存储
- 多行基本字符串（"""...""")：
  - 首行如果紧随换行（LF 或 CRLF）会被修剪
  - 同样支持转义序列（与单行基本字符串一致）
  - 支持续行：行尾反斜杠（\\）+ 行终止表示拼接相邻行，并修剪下一行起始空白
- 多行字面量字符串（'''...'''）：
  - 首行如果紧随换行（LF 或 CRLF）会被修剪
  - 不处理转义；按字面存储


## 性能与规模（微基准，手动）
- 位置：src/tests/tools
- 构建并运行（默认参数）：
  - Windows: src/tests/tools/run_toml_bench.bat
- 自定义参数（EXE 直接运行）：
  - toml_bench.exe <keys> <depth> <aot> <flags>
  - flags：p=pretty, s=sort, e=spaces-around-equals
  - 示例：toml_bench.exe 10000 2 0 ps
- 输出示例（相对值，仅用于本机对比）：
  - Writer: keys=10000 depth=2 aot=0 bytes≈147K p50≈75–81ms p90≈更高一点
  - Reader: size=21 p50≈~1ms（示例路径轻量，仅作参考）
- 说明：
  - 该微基准不会进入 CI；仅用于快速对比不同参数与 flags 组合，受本机负载与时钟粒度影响


- 进阶用法：CSV 导出与大 Reader 样本
  - EXE 额外参数：
    - 第 5 个参数：--csv=path（将一行结果追加到 CSV：keys,depth,aot,flags,out_bytes,in_bytes,writer_p50,writer_p90,reader_p50,reader_p90）
    - 第 6 个参数：--bigreader=true/false（使用更大的 Reader 文本样本）
    - 第 7 个参数：--runid=...（为本次基准设置 run_id，写入 CSV）
    - 第 8 个参数：--remark=...（备注说明，写入 CSV）
  - 示例：
    - toml_bench.exe 3000 3 100 ps --csv=C:\tmp\toml_bench.csv --bigreader=true --runid=R1 --remark="dev run"

- 预设典型场景（Windows 批处理）：
  - 深层+AoT：src/tests/tools/run_toml_bench_deep_aot.bat（约 keys=5000, depth=8, aot=1000, flags=pse）
  - 宽标量：src/tests/tools/run_toml_bench_wide_scalars.bat（约 keys=20000, depth=0, aot=0, flags=ps）


- 矩阵基准（多组合导出）
  - 脚本：src/tests/tools/run_toml_bench_matrix.bat
  - 入参：[csvDir] [keysList] [depthList] [aotList]
  - 默认：csvDir=src/tests/tools/bench_results；keys=5000；depth=2 4；aot=0 200
  - 作用：为每组 (keys,depth,aot) 输出独立 CSV 并跑 flags 组合（ps/p/s/e/pe/se/pse），并追加 bigreader=true 样本
  - 使用：
    - src/tests/tools/run_toml_bench_matrix.bat
    - 自定义：src/tests/tools/run_toml_bench_matrix.bat C:\tmp\bench_results "5000 10000" "2 4" "0 200"

测试与脚手架
- tests/fafafa.core.toml/ 下的 fpcunit 测试工程；BuildOrTest.bat 统一构建与运行

参考：升级到 v2 解析器的实践与差异说明，见 docs/UPGRADE-fafafa.core.toml-v2.md

- 当前 35/35 通过（包含新增 writer edgecases）

后续路线
- Reader：日期时间/数组/内联表（按 TDD 逐步推进）
- Writer：Pretty 策略细化、排序/空格与 Pretty 的组合策略完善
- 示例工程与更详细文档

