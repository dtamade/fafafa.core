# fafafa.core.simd 模块文档

## 概述

`fafafa.core.simd` 是一个高性能、跨平台的 SIMD 优化模块，为 FreePascal 应用程序提供内存、文本、位集和搜索操作的硬件加速。

### 设计目标

- **性能优化**：在 FPC 缺少稳定 SIMD 内建支持的现实下，以“手写汇编微内核 + 运行时派发 + 标量回退”的方式，为常见热点提供可选加速
- **API 兼容性**：不改变调用方 API 语义；任何平台/构建环境下均可运行；有 SIMD 则自动用更快实现
- **跨平台支持**：支持 x86_64 (SSE2/AVX2/AVX-512) 和 AArch64 (NEON) 架构

### 设计原则

- **接口稳定、低耦合**：对外只暴露语义清晰的函数；不暴露 ISA 细节
- **运行时派发**：初始化时根据 CPU/OS 能力选择最优实现；支持环境/宏强制降级
- **平滑回退**：标量实现永远可用；汇编不可用/检测失败时自动回退
- **小而精**：优先覆盖高 ROI 原语（mem/text/bitset/search 的核心路径）
- **命名统一**：全部指令集名称使用全大写（SSE2/AVX2/NEON/AVX-512/SVE）

## 架构设计

### 模块结构

```
src/
├── fafafa.core.simd.pas           # 主用户入口：向量运算 + 类型重导出
├── fafafa.core.simd.api.pas       # 门面函数 API：MemEqual/SumBytes/Utf8Validate 等
├── fafafa.core.simd.types.pas     # 类型定义：TVecF32x4/TMask4 等
├── fafafa.core.simd.dispatch.pas  # 运行时派发：后端选择和函数表
├── fafafa.core.simd.cpuinfo.pas   # CPU 能力检测：CPUID/XGETBV 等
├── fafafa.core.simd.memutils.pas  # 内存工具：对齐分配
├── fafafa.core.simd.scalar.pas    # 后端：标量回退实现
├── fafafa.core.simd.sse2.pas      # 后端：SSE2 128-bit 实现
├── fafafa.core.simd.avx2.pas      # 后端：AVX2 256-bit 实现
└── fafafa.core.simd.avx512.pas    # 后端：AVX-512 512-bit 实现
```

### 支持的指令集

#### x86_64 架构
- **当前支持**：SSE2, AVX2, POPCNT
- **规划支持**：AVX-512F, AVX-512VL, AVX-512BW

#### AArch64 架构
- **当前支持**：NEON (占位符阶段)
- **规划支持**：CRC32, AES, PMULL, SVE

### 性能等级

| 等级 | x86_64 | AArch64 | 描述 |
|------|--------|---------|------|
| LEVEL_0 | SCALAR | SCALAR | 无 SIMD，纯标量实现 |
| LEVEL_1 | SSE2 | NEON | 基线 SIMD 支持 |
| LEVEL_2 | AVX2 | NEON+CRC/AES | 增强 SIMD 支持 |
| LEVEL_3 | AVX-512 | SVE/SVE2 | 高端 SIMD 支持（规划中） |

### 性能基准 (4096 字节, 1M 次迭代)

| 函数 | Scalar | SSE2 | AVX2 | 加速比 |
|------|--------|------|------|--------|
| MemEqual | 3300ms | 743ms (4.4x) | 139ms | **23.7x** |
| MemFindByte | 161ms | 48ms (3.4x) | 12ms | **13.4x** |
| SumBytes | 1861ms | 757ms (2.5x) | 99ms | **18.8x** |
| CountByte | 3117ms | 708ms (4.4x) | 136ms | **22.9x** |
| MinMaxBytes | 4962ms | - | 121ms | **41.0x** |
| BitsetPopCount | 26591ms | - | 537ms | **49.5x** |
| Utf8Validate | 2936ms | - | 318ms | **9.2x** |
| AsciiIEqual | 5894ms | - | 247ms | **23.9x** |

## 快速入门

### 基本用法
```pascal
uses
  fafafa.core.simd,      // 向量运算
  fafafa.core.simd.api;  // 门面函数

// 内存比较
if MemEqual(@buf1[0], @buf2[0], Length(buf1)) then
  WriteLn('缓冲区相等');

// 字节查找
pos := MemFindByte(@data[0], Length(data), $FF);

// 字节求和
total := SumBytes(@data[0], Length(data));

// UTF-8 验证
if Utf8Validate(@text[0], Length(text)) then
  WriteLn('UTF-8 有效');

// ASCII 转小写
ToLowerAscii(@str[1], Length(str));
```

### 向量运算
```pascal
var
  a, b, result: TVecF32x4;
begin
  // 使用运算符重载
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;
  result := a + b;  // [6.0, 8.0, 10.0, 12.0]
  result := a * b;  // [5.0, 12.0, 21.0, 32.0]
  result := -a;     // [-1.0, -2.0, -3.0, -4.0]
  
  // Shuffle 操作
  result := VecF32x4Shuffle(a, MM_SHUFFLE(0,0,0,0));  // 广播 a[0]
  result := VecF32x4Reverse(a);  // [4.0, 3.0, 2.0, 1.0]
  
  // 数学函数
  result := VecF32x4Sin(a);   // 逐元素 sin
  result := VecF32x4Exp(a);   // 逐元素 exp
end;
```

### 高级算法
```pascal
var
  v: TVecI32x4;
  arr, out_arr: array[0..7] of Int32;
begin
  // 排序网络 - 4 元素排序
  v.i[0] := 4; v.i[1] := 1; v.i[2] := 3; v.i[3] := 2;
  v := SortNet4I32(v, True);  // 升序 [1, 2, 3, 4]
  
  // 前缀和
  v.i[0] := 1; v.i[1] := 2; v.i[2] := 3; v.i[3] := 4;
  v := PrefixSumI32x4(v, True);  // inclusive [1, 3, 6, 10]
  
  // 数组前缀和
  arr[0] := 1; arr[1] := 2; arr[2] := 3; arr[3] := 4;
  PrefixSumArrayI32(@arr[0], @out_arr[0], 4);  // [1, 3, 6, 10]
  
  // 字符串搜索
  pos := StrFindChar(@text[0], Length(text), Ord('x'));
end;
```

### 查询后端信息
```pascal
WriteLn('当前后端: ', GetCurrentBackendInfo.Name);
// 输出: "AVX2" 或 "SSE2" 或 "Scalar"
```

## API 参考

### 内存操作 (Memory Operations)

#### MemEqual
```pascal
function MemEqual(a, b: Pointer; len: SizeUInt): LongBool;
```
**功能**：比较两个内存区域是否相等
**参数**：
- `a`, `b`: 要比较的内存区域指针
- `len`: 比较的字节数

**返回值**：相等返回 `True`，否则返回 `False`
**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON

#### MemFindByte
```pascal
function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
```
**功能**：在内存区域中查找指定字节的首次出现位置
**参数**：
- `p`: 搜索的内存区域指针
- `len`: 搜索的字节数
- `value`: 要查找的字节值

**返回值**：找到返回位置索引（0-based），未找到返回 -1
**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON

#### MemDiffRange
```pascal
function MemDiffRange(a, b: Pointer; len: SizeUInt): TDiffRange;
```
**功能**：找出两个内存区域的差异范围
**参数**：
- `a`, `b`: 要比较的内存区域指针
- `len`: 比较的字节数

**返回值**：`TDiffRange` 记录，包含 `First` 和 `Last` 字段
- 完全相同时：`First = -1, Last = -1`
- 有差异时：`First` 为首个差异位置，`Last` 为最后差异位置

**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON

### 文本操作 (Text Operations)

#### Utf8Validate
```pascal
function Utf8Validate(p: Pointer; len: SizeUInt): LongBool;
```
**功能**：验证内存区域是否为有效的 UTF-8 编码
**参数**：
- `p`: 要验证的内存区域指针
- `len`: 验证的字节数

**返回值**：有效 UTF-8 返回 `True`，否则返回 `False`
**优化**：x86_64 使用 SSE2 ASCII 快路径 + 标量回退，AArch64 使用 NEON ASCII 快路径

#### ToLowerAscii
```pascal
procedure ToLowerAscii(p: Pointer; len: SizeUInt);
```
**功能**：将 ASCII 字符转换为小写（就地修改）
**参数**：
- `p`: 要转换的内存区域指针
- `len`: 转换的字节数

**说明**：只转换 ASCII 字母 A-Z，非 ASCII 字节保持不变
**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON

#### ToUpperAscii
```pascal
procedure ToUpperAscii(p: Pointer; len: SizeUInt);
```
**功能**：将 ASCII 字符转换为大写（就地修改）
**参数**：
- `p`: 要转换的内存区域指针
- `len`: 转换的字节数

**说明**：只转换 ASCII 字母 a-z，非 ASCII 字节保持不变
**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON

#### AsciiIEqual
```pascal
function AsciiIEqual(a, b: Pointer; len: SizeUInt): LongBool;
```
**功能**：ASCII 字符串忽略大小写比较
**参数**：
- `a`, `b`: 要比较的内存区域指针
- `len`: 比较的字节数

**返回值**：忽略大小写相等返回 `True`，否则返回 `False`
**说明**：只对 ASCII 字母进行大小写转换，非 ASCII 字节直接比较
**优化**：x86_64 使用 SSE2/AVX2，AArch64 使用 NEON
- 初始化阶段：
  - 检测 CPU/OS 能力（x86：CPUID + OSXSAVE + XGETBV；ARM64：特征寄存器/操作系统导出），决定可用 ISA 集。
  - 为每个原语选择最佳实现，绑定函数指针。
- 强制策略：
  - 环境变量 FAFAFA_SIMD_FORCE=SCALAR|SSE2|AVX2|NEON|AVX-512|SVE|SVE2（大小写不敏感）。
  - 编译宏 FAFAFA_SIMD_USE_ASM 开启汇编；FAFAFA_SIMD_NO_ASM 禁用汇编（仅标量）。
- Info：
  - function SimdInfo: string;  // 返回 "X86_64-AVX2"、"AARCH64-NEON"、"SCALAR" 等。

实现策略
- M0：门面/检测/标量实现 + 派发骨架（功能即刻可用）。
- M1：微内核（SSE2）覆盖：MemEqual/MemFindByte/MemDiffRange；Utf8Validate 快路径；BitsetPopCount POPCNT 绑定。
- M2：AVX2 路径 + Bitset 带宽优化 + ASCII 大小写。
- M3：XxHash64 分块优化 + （可选）CRC32C 的 SSE4.2/PMULL 实现。
- M4：视硬件与工具链考虑 AVX-512/SVE/SVE2 的选点增强。

汇编与调用约定注意
- Windows x64：遵循 MS x64 ABI；如使用 AVX，返回前执行 vzeroupper；保存 XMM6–XMM15。
- SysV x86_64：保证 16 字节栈对齐；寄存器保存规则按照 SysV。
- AArch64：遵守 AAPCS64；必要时保存/恢复 V8–V15；NEON 为基线。
- 非对齐与尾部处理：内部处理任意指针与长度；严禁越界读写。

测试与基准（本地）
- 最小测试：tests/fafafa.core.simd/minitest_simd.lpr
- 边界测试：tests/fafafa.core.simd/minitest_simd_edges.lpr（未对齐、混合 UTF‑8）
- 微基准：tests/fafafa.core.simd/bench_simd.lpr（Mem*/Bitset/Utf8Validate/IndexOf/AsciiCase）
- 正确性：每个原语与标量参考实现对拍；覆盖随机/对抗/边界长度（0/1/15/16/31/32/n·W±k）。
- 一致性：强制不同 Profile（SCALAR/SSE2）结果一致（在支持平台上）。
- 性能：小/中/大三档；冷热缓存分别测试；记录速度提升比。

更好用、更现代（DX）
- 函数指针对外：直接调用 MemEqual 等，无需关心 ISA；Info 可用于日志。
- 便捷重载：支持 BytesView（ptr+len 轻量视图）与 open array of Byte 重载（后续）。
- 可插拔策略：允许在基准/诊断中显式选择 SCALAR/SSE2/AVX2/NEON 对比（后续 AVX2/SVE）。
- 文档与示例：提供最小示例打印当前 Profile 并跑一组微基准。

命名规范（强制）
- 指令集与 Profile：一律全大写（SSE2/AVX2/NEON/AVX-512/SVE）。
- 单元与符号：Pascal 风格，函数语义化命名（MemEqual/Utf8Validate 等）。

运行指南（本地）
- 构建与运行最小测试：
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/minitest_simd.lpr
- 构建与运行边界测试：
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/minitest_simd_edges.lpr
- 构建与运行微基准：
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/bench_simd.lpr
- 强制回退（对拍一致性）：
  - Windows: set FAFAFA_SIMD_FORCE=SCALAR
  - Linux/Mac: export FAFAFA_SIMD_FORCE=SCALAR

## 搜索基元（BytesIndexOf）

语义与约定
- 在字节序列 haystack 中查找 needle 的首次出现位置（0-based）；未找到返回 -1
- 约定：nlen=0 返回 0；nlen>len 返回 -1；指针可为任意对齐

实现策略
- 标量：BMH（Boyer–Moore–Horspool）快速滑动，通用可靠
- SSE2/AVX2：两段式加速
  1) 候选尾位批量筛选：利用 MemFindByte_SSE2/AVX2 在 pos+nlen-1 处批量查找 needle 的末字节
  2) 快速否决 + 完整确认：
     - 对命中候选，先比较首/尾块（SSE2: 16B；AVX2: 32B；长度不足退化）
     - 对超长 needle（SSE2: >32；AVX2: >64），再比较中段块快速否决
     - 最后用 CompareByte 完整确认匹配

复杂度
- 平均近似 O(len/nlen) 的滑动否决 + 常数次块比较；最坏退化 O(len·nlen)
- SIMD 路径对“长 needle + 稀疏命中”更具优势

绑定与回退
- 门面导出 BytesIndexOf：
  - x86_64：优先绑定 AVX2，其次 SSE2；无法使用则回退到标量 BMH
  - 可用 FAFAFA_SIMD_FORCE=SCALAR|SSE2|AVX2 强制覆盖，用于对拍与排障

使用示例
- 查找 'world' 在 'hello world' 中的位置：
  - i := BytesIndexOf(@buf[0], Length(buf), @pat[0], Length(pat)); // 命中返回 6

AVX2 注意事项
- 检测要求：OSXSAVE+AVX（CPUID leaf1 ECX bit27/28），XGETBV(XCR0) 确认 XMM/YMM 保存（bit1/bit2），leaf7 EBX bit5 为 AVX2。
- vzeroupper：所有 AVX 函数在与 SSE 路径切换及返回前调用 vzeroupper，避免 AVX→SSE 混用惩罚。
- 非对齐：使用 VMOVDQU/MOVDQU 支持任意指针；尾部采用 SSE2/标量收尾，严格控制访问范围。
- 覆盖顺序：优先级为 AVX2 > SSE2 > SCALAR；可用 FAFAFA_SIMD_FORCE 覆盖（SCALAR|SSE2|AVX2）。

支持矩阵（当前轮）
- x86_64：
  - SSE2：MemEqual / MemFindByte / MemDiffRange / ToLowerAscii / ToUpperAscii（内联汇编）
  - AVX2：MemEqual / MemFindByte / MemDiffRange / ToLowerAscii / ToUpperAscii（内联汇编）
  - POPCNT：BitsetPopCount 快路径
  - UTF‑8：FastPath（ASCII SSE2 + 非 ASCII 回退标量）
  - 搜索：BytesIndexOf（标量 BMH + SSE2/AVX2 快速筛选与否决）
- 其他架构：暂为 SCALAR（后续规划 NEON 等）

排障提示
- 若出现非预期性能/行为：
  - 设置 FAFAFA_SIMD_FORCE=SCALAR 重试以确认是否与 SIMD 路径相关
  - Windows x64 请确认未修改调用约定/优化开关；必要时以 /O- 测试
  - 如目标机为旧 CPU，请确认是否支持 AVX/AVX2（可打印 SimdInfo 获取 Profile）



## AArch64/NEON 路线卡位（规划）

目标与原则
- 与 x86_64 API 保持语义一致：MemEqual/MemFindByte/MemDiffRange/Utf8Validate/ToLower/ToUpper/BytesIndexOf/BitsetPopCount
- 渐进式落地：先占位（标量回退），后逐步添加 NEON 内核
- 零侵入：绑定与派发不影响现有 x86_64 行为

分期计划
- N0（占位）：
  - 绑定 Profile：AARCH64-NEON；所有函数先指向标量实现（已默认如此）
  - 文档/测试：沿用现有 minitest/edges/consistency/bench（在 ARM 上运行标量路径）
- N1（NEON 基元内核）：
  - MemEqual_NEON：LD1 + CMEQ + UQXTN/UMOV 掩码检查；尾部标量
  - MemFindByte_NEON：dup(val) + CMEQ + UQXTN/UMOV + TST/BFI；尾部标量
  - MemDiffRange_NEON：前/后块扫描 + 掩码首/末差异定位
- N2（文本/位集/搜索）：
  - Utf8Validate_ASCII 快路径：UQXTN/UMOV 掩码检测最高位
  - ToLower/ToUpper：XOR 0x80 + CMGT/CMHI 生成范围掩码 + OR/SUB 应用
  - BytesIndexOf：复用 MemFindByte_NEON + 首尾/中段块快速否决
  - BitsetPopCount：优先用 vcnt + pairwise add 路径；若有 ARMv8.1-CRC 再评估 CRC32

检测与绑定
- Profile：AARCH64-NEON（默认）
- 可在 detect 中保留 CRC32/AES/PMULL 标志位，后续用于可选加速（非阻塞）

测试与验证
- 一致性：consistency_simd.lpr 在 SCALAR 与 NEON 下结果一致
- 边界：未对齐、极短/极长/跨页、对抗数据，覆盖与 x86_64 等价
- 基准：与 x86_64 同维度；先验证占位可运行，再逐步落地内核对比

下一步（建议）
- 落地 N0 完成（文档已就绪）；如需，我可在代码中加入 CPUAARCH64 的 NEON 占位符号（调用标量），并预留绑定路径，随后进入 N1 实装 MemEqual_NEON。


NEON 注意事项（实现与验证建议）
- 指令选择：
  - MemEqual：ld1/eor/umaxv 聚合是否存在差异；尾部逐字节
  - MemFindByte：dup(val)/cmeq/umaxv 检测命中，块内逐字节定位首命中；尾部逐字节
  - MemDiffRange：cmeq 得相等掩码，umInV 检查块全等；块内从低到高（first）与高到低（last）逐字节定位
- 非对齐：ld1 对任意对齐安全，但仍需严格遵守长度边界；严禁读越界
- 绑定策略：
  - 定义 CPUAARCH64 且定义 FAFAFA_SIMD_NEON_ASM 时，门面绑定 MemEqual/MemFindByte/MemDiffRange 到 NEON 实现
  - 未定义时默认标量回退；SimdInfo() 报告 AARCH64-NEON 仅为 Profile 信息
- 测试建议：
  - 先在 AArch64 上执行标量基线，确认 minitest/edges/consistency/bench 可运行
  - 打开 NEON 绑定开关，对拍一致性（SCALAR vs NEON）
  - 基准对比块大小、对齐、数据分布（随机/全等/稀疏差异）


AArch64 门面绑定与使用
- 默认行为：无宏定义时，AArch64 上所有函数回退到标量实现（Profile 仍显示 AARCH64-NEON）
- 启用 NEON 内核：定义 FAFAFA_SIMD_NEON_ASM 后，门面在 AArch64 下将绑定 MemEqual/MemFindByte/MemDiffRange 到 NEON 版本
- 对拍建议：
  - 先在 SCALAR 下运行 minitest/edges/consistency/bench
  - 再启用 NEON，确保一致性通过后观察基准提升


### BytesIndexOf（NEON）实现要点
- 候选筛选：
  - 使用 MemFindByte_NEON 在 haystack 的候选尾位范围查找 needle 的末字节（dup(val) + cmeq → umaxv 判断是否命中）
  - 命中位置 i 表示可能的匹配尾部索引
- 快速否决：
  - 若 nlen≥16：比较首 16B；若 nlen>16 再比较尾 16B
  - 若 nlen>32：比较中段 16B（起点为 16 + (nlen-32)/2）
  - 以上任一比较失败则继续滑动到 i+1 的候选尾位
- 完整确认：
  - 通过 CompareByte(base, needle, nlen) 做一次最终确认
- 非对齐与尾部：
  - ld1 支持任意对齐；所有访问严格受 len/nlen 约束，避免越界
- 复杂度与收益：
  - 平均快速否决接近 O(len/nlen)；对“长 needle + 稀疏命中”的场景收益显著

### 基准对比模板（AArch64：SCALAR vs NEON）
- 构建 bench（IndexOf 已包含于 bench_simd.lpr）：
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/bench_simd.lpr
- 运行 SCALAR 基线：
  - export FAFAFA_SIMD_FORCE=SCALAR
  - ./bench_simd
  - 保存 BytesIndexOf 的 size/nlen/throughput 输出
- 运行 NEON：
  - 取消强制：unset FAFAFA_SIMD_FORCE
  - 启用 NEON 内核（编译时定义）：-dFAFAFA_SIMD_NEON_ASM
  - 重新编译并运行 ./bench_simd
- 计算加速比：
  - 对同一 size/nlen，取 NEON 吞吐 / SCALAR 吞吐，得到加速倍数
- 建议采样：
  - haystack 尺寸：64KB、512KB、4MB
  - needle 长度：4、8、16、32、64
  - 命中位置：中间（已在 bench 预置），必要时可扩展头/尾/未命中三类场景


### AArch64/NEON 测试（设备就绪时）
- 目的：在 arm64 上快速验证 NEON 内核的正确性与绑定行为
- ASCII 大小写（NEON 与门面）
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/minitest_text_neon.lpr
  - SCALAR 基线：export FAFAFA_SIMD_FORCE=SCALAR && ./minitest_text_neon
  - NEON 绑定：unset FAFAFA_SIMD_FORCE；编译时加 -dFAFAFA_SIMD_NEON_ASM 后运行
- UTF‑8 ASCII 快路径（NEON 与门面）
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/minitest_utf8_neon.lpr
  - SCALAR 基线：export FAFAFA_SIMD_FORCE=SCALAR && ./minitest_utf8_neon
  - NEON 绑定：unset FAFAFA_SIMD_FORCE；编译时加 -dFAFAFA_SIMD_NEON_ASM 后运行
- 预期：
  - 两个 minitest 在 SCALAR 与 NEON 下均打印 OK；NEON 下可结合 bench 观察性能变化


- 搜索 BytesIndexOf（NEON 与门面）
  - fpc -MObjFPC -S2 -Si -Fu./src tests/fafafa.core.simd/minitest_search_neon.lpr
  - SCALAR 基线：export FAFAFA_SIMD_FORCE=SCALAR && ./minitest_search_neon
  - NEON 绑定：unset FAFAFA_SIMD_FORCE；编译时加 -dFAFAFA_SIMD_NEON_ASM 后运行
  - 预期：NEON 与 SCALAR 下均打印 OK；NEON 下可结合 bench 的 BytesIndexOf 项观察吞吐变化

## types.pas API 参考

### 向量类型

#### 128-bit 有符号向量

| 类型 | 元素类型 | 元素数 | 描述 |
|------|----------|--------|------|
| `TVecF32x4` | `Single` | 4 | 4 个 32 位浮点数 |
| `TVecF64x2` | `Double` | 2 | 2 个 64 位浮点数 |
| `TVecI32x4` | `Int32` | 4 | 4 个 32 位有符号整数 |
| `TVecI64x2` | `Int64` | 2 | 2 个 64 位有符号整数 |
| `TVecI16x8` | `Int16` | 8 | 8 个 16 位有符号整数 |
| `TVecI8x16` | `Int8` | 16 | 16 个 8 位有符号整数 |

#### 128-bit 无符号向量

| 类型 | 元素类型 | 元素数 | 描述 |
|------|----------|--------|------|
| `TVecU32x4` | `UInt32` | 4 | 4 个 32 位无符号整数 |
| `TVecU64x2` | `UInt64` | 2 | 2 个 64 位无符号整数 |
| `TVecU16x8` | `UInt16` | 8 | 8 个 16 位无符号整数 |
| `TVecU8x16` | `UInt8` | 16 | 16 个 8 位无符号整数 |

#### 256-bit 向量

| 类型 | 元素类型 | 元素数 | 描述 |
|------|----------|--------|------|
| `TVecF32x8` | `Single` | 8 | 8 个 32 位浮点数 |
| `TVecF64x4` | `Double` | 4 | 4 个 64 位浮点数 |
| `TVecI32x8` | `Int32` | 8 | 8 个 32 位有符号整数 |
| `TVecU32x8` | `UInt32` | 8 | 8 个 32 位无符号整数 |

#### 向量类型结构
所有向量类型都是 `record` 类型，支持通过 variant 访问：
```pascal
var v: TVecF32x4;
begin
  // 方式 1: 通过元素数组访问
  v.f[0] := 1.0;
  v.f[1] := 2.0;
  
  // 方式 2: 通过 raw 字节数组访问
  WriteLn(v.raw[0]);  // 访问底层字节
end;
```

### 运算符重载

#### TVecF32x4 运算符
```pascal
operator + (const a, b: TVecF32x4): TVecF32x4;  // 逐元素加法
operator - (const a, b: TVecF32x4): TVecF32x4;  // 逐元素减法
operator * (const a, b: TVecF32x4): TVecF32x4;  // 逐元素乘法
operator / (const a, b: TVecF32x4): TVecF32x4;  // 逐元素除法
operator - (const a: TVecF32x4): TVecF32x4;     // 取反
operator * (const a: TVecF32x4; s: Single): TVecF32x4;  // 标量乘法
operator * (s: Single; const a: TVecF32x4): TVecF32x4;  // 标量乘法
operator / (const a: TVecF32x4; s: Single): TVecF32x4;  // 标量除法
```

#### TVecF64x2 运算符
```pascal
operator + (const a, b: TVecF64x2): TVecF64x2;
operator - (const a, b: TVecF64x2): TVecF64x2;
operator * (const a, b: TVecF64x2): TVecF64x2;
operator / (const a, b: TVecF64x2): TVecF64x2;
operator - (const a: TVecF64x2): TVecF64x2;
```

#### TVecI32x4 运算符
```pascal
operator + (const a, b: TVecI32x4): TVecI32x4;
operator - (const a, b: TVecI32x4): TVecI32x4;
operator - (const a: TVecI32x4): TVecI32x4;
```

**示例**：
```pascal
var a, b, c: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 5.0; b.f[1] := 6.0; b.f[2] := 7.0; b.f[3] := 8.0;
  c := a + b;  // [6.0, 8.0, 10.0, 12.0]
  c := a * 2.0;  // [2.0, 4.0, 6.0, 8.0]
end;
```

### 掩码类型

#### 掩码类型定义
| 类型 | 元素类型 | 元素数 | 描述 |
|------|----------|--------|------|
| `TMaskF32x4` | `UInt32` | 4 | F32x4 的向量掩码 |
| `TMaskF64x2` | `UInt64` | 2 | F64x2 的向量掩码 |
| `TMaskI32x4` | `UInt32` | 4 | I32x4 的向量掩码 |
| `TMaskI64x2` | `UInt64` | 2 | I64x2 的向量掩码 |

掩码元素值：`0` 表示 false，`$FFFFFFFF` (或 `$FFFFFFFFFFFFFFFF` 对于 64-bit) 表示 true。

#### 位掩码类型
| 类型 | 有效位数 | 描述 |
|------|----------|------|
| `TMask2` | 2 | 用于 2 元素向量 |
| `TMask4` | 4 | 用于 4 元素向量 |
| `TMask8` | 8 | 用于 8 元素向量 |
| `TMask16` | 16 | 用于 16 元素向量 |
| `TMask32` | 32 | 用于 32 元素向量 |

#### TMaskF32x4 函数

```pascal
function MaskF32x4AllTrue: TMaskF32x4;
```
返回所有元素为 true 的掩码。

```pascal
function MaskF32x4AllFalse: TMaskF32x4;
```
返回所有元素为 false 的掩码。

```pascal
function MaskF32x4Set(m0, m1, m2, m3: Boolean): TMaskF32x4;
```
根据 4 个布尔值构造掩码。

```pascal
function MaskF32x4Test(const m: TMaskF32x4; index: Integer): Boolean;
```
测试指定位置的掩码元素是否为 true。

```pascal
function MaskF32x4ToBitmask(const m: TMaskF32x4): TMask4;
```
将向量掩码转换为 4-bit 位掩码。

```pascal
function MaskF32x4Any(const m: TMaskF32x4): Boolean;
```
返回是否有任意元素为 true。

```pascal
function MaskF32x4All(const m: TMaskF32x4): Boolean;
```
返回是否所有元素都为 true。

```pascal
function MaskF32x4None(const m: TMaskF32x4): Boolean;
```
返回是否所有元素都为 false。

```pascal
function MaskF32x4Select(const m: TMaskF32x4; const a, b: TVecF32x4): TVecF32x4;
```
根据掩码选择元素：m[i]=true 选择 a[i]，否则选择 b[i]。

#### TMaskF32x4 逻辑运算符
```pascal
operator and (const a, b: TMaskF32x4): TMaskF32x4;  // 逐元素与
operator or (const a, b: TMaskF32x4): TMaskF32x4;   // 逐元素或
operator xor (const a, b: TMaskF32x4): TMaskF32x4;  // 逐元素异或
operator not (const a: TMaskF32x4): TMaskF32x4;     // 逐元素取反
```

#### TMaskF64x2 / TMaskI32x4 函数
```pascal
function MaskF64x2AllTrue: TMaskF64x2;
function MaskF64x2AllFalse: TMaskF64x2;
function MaskF64x2ToBitmask(const m: TMaskF64x2): TMask2;

function MaskI32x4AllTrue: TMaskI32x4;
function MaskI32x4AllFalse: TMaskI32x4;
function MaskI32x4ToBitmask(const m: TMaskI32x4): TMask4;
```

### 类型转换函数

#### IntoBits / FromBits - 位模式重新解释
不改变位模式，仅重新解释类型：
```pascal
function VecF32x4IntoBits(const a: TVecF32x4): TVecI32x4;
function VecI32x4FromBitsF32(const a: TVecI32x4): TVecF32x4;
function VecF64x2IntoBits(const a: TVecF64x2): TVecI64x2;
function VecI64x2FromBitsF64(const a: TVecI64x2): TVecF64x2;
```

**示例**：
```pascal
var f: TVecF32x4; i: TVecI32x4;
begin
  f.f[0] := 1.0;
  i := VecF32x4IntoBits(f);  // i.i[0] = $3F800000 (1.0 的 IEEE 754 表示)
end;
```

#### Cast - 元素级别数值转换
```pascal
function VecF32x4CastToI32x4(const a: TVecF32x4): TVecI32x4;  // 浮点截断为整数
function VecI32x4CastToF32x4(const a: TVecI32x4): TVecF32x4;  // 整数转为浮点
function VecF64x2CastToI64x2(const a: TVecF64x2): TVecI64x2;
function VecI64x2CastToF64x2(const a: TVecI64x2): TVecF64x2;
```

#### Widen - 扩展宽度
```pascal
function VecI16x8WidenLoI32x4(const a: TVecI16x8): TVecI32x4;  // 低 4 元素符号扩展
function VecI16x8WidenHiI32x4(const a: TVecI16x8): TVecI32x4;  // 高 4 元素符号扩展
```

#### Narrow - 缩小宽度
```pascal
function VecI32x4NarrowToI16x8(const a, b: TVecI32x4): TVecI16x8;  // a->低4, b->高4
```

#### 精度转换
```pascal
function VecF32x4ToF64x2Lo(const a: TVecF32x4): TVecF64x2;  // 低 2 元素 F32->F64
function VecF64x2ToF32x4(const a, b: TVecF64x2): TVecF32x4;  // 2*F64x2 -> F32x4
```

### Shuffle/Swizzle 函数

#### 辅助宏
```pascal
function MM_SHUFFLE(d, c, b, a: Byte): Byte;
```
生成 shuffle 立即数。结果 = `(d << 6) | (c << 4) | (b << 2) | a`。

**示例**：
- `MM_SHUFFLE(3,2,1,0) = $E4` - 不变
- `MM_SHUFFLE(0,0,0,0) = $00` - 广播元素 0
- `MM_SHUFFLE(0,1,2,3) = $1B` - 反转

#### Shuffle - 单向量元素重排
```pascal
function VecF32x4Shuffle(const a: TVecF32x4; imm8: Byte): TVecF32x4;
function VecI32x4Shuffle(const a: TVecI32x4; imm8: Byte): TVecI32x4;
```
根据 imm8 重排元素。imm8 每 2 bit 选择一个源元素索引 (0-3)。

**示例**：
```pascal
var a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  r := VecF32x4Shuffle(a, MM_SHUFFLE(0,0,0,0));  // [1,1,1,1] 广播
  r := VecF32x4Shuffle(a, MM_SHUFFLE(0,1,2,3));  // [4,3,2,1] 反转
end;
```

#### Shuffle2 - 双向量元素选择
```pascal
function VecF32x4Shuffle2(const a, b: TVecF32x4; imm8: Byte): TVecF32x4;
```
低 2 元素来自 a，高 2 元素来自 b。

#### Blend - 根据掩码混合
```pascal
function VecF32x4Blend(const a, b: TVecF32x4; mask: Byte): TVecF32x4;
function VecF64x2Blend(const a, b: TVecF64x2; mask: Byte): TVecF64x2;
function VecI32x4Blend(const a, b: TVecI32x4; mask: Byte): TVecI32x4;
```
mask bit=0 选择 a，bit=1 选择 b。

#### Unpack - 交织元素
```pascal
function VecF32x4UnpackLo(const a, b: TVecF32x4): TVecF32x4;  // [a0,b0,a1,b1]
function VecF32x4UnpackHi(const a, b: TVecF32x4): TVecF32x4;  // [a2,b2,a3,b3]
function VecI32x4UnpackLo(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4UnpackHi(const a, b: TVecI32x4): TVecI32x4;
```

#### Broadcast - 广播单元素
```pascal
function VecF32x4Broadcast(const a: TVecF32x4; index: Integer): TVecF32x4;
function VecI32x4Broadcast(const a: TVecI32x4; index: Integer): TVecI32x4;
```
将 a[index] 广播到所有位置。

#### Reverse - 反转元素顺序
```pascal
function VecF32x4Reverse(const a: TVecF32x4): TVecF32x4;  // [a3,a2,a1,a0]
function VecI32x4Reverse(const a: TVecI32x4): TVecI32x4;
```

#### RotateLeft - 循环旋转
```pascal
function VecF32x4RotateLeft(const a: TVecF32x4; n: Integer): TVecF32x4;
function VecI32x4RotateLeft(const a: TVecI32x4; n: Integer): TVecI32x4;
```
元素左移 n 个位置（循环）。

#### Insert/Extract - 插入和提取单元素
```pascal
function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
function VecI32x4Insert(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single;
function VecI32x4Extract(const a: TVecI32x4; index: Integer): Int32;
```

### SIMD 数学函数

所有数学函数都是逐元素操作，当前为标量参考实现。

#### 三角函数
```pascal
function VecF32x4Sin(const a: TVecF32x4): TVecF32x4;   // sin(x)
function VecF32x4Cos(const a: TVecF32x4): TVecF32x4;   // cos(x)
function VecF32x4Tan(const a: TVecF32x4): TVecF32x4;   // tan(x)
procedure VecF32x4SinCos(const a: TVecF32x4; out sinResult, cosResult: TVecF32x4);
```

**示例**：
```pascal
var angles, sines, cosines: TVecF32x4;
begin
  angles.f[0] := 0; angles.f[1] := Pi/6; angles.f[2] := Pi/4; angles.f[3] := Pi/2;
  sines := VecF32x4Sin(angles);  // [0, 0.5, 0.707, 1.0]
  VecF32x4SinCos(angles, sines, cosines);  // 同时计算 sin 和 cos
end;
```

#### 指数/对数函数
```pascal
function VecF32x4Exp(const a: TVecF32x4): TVecF32x4;   // e^x
function VecF32x4Exp2(const a: TVecF32x4): TVecF32x4;  // 2^x
function VecF32x4Log(const a: TVecF32x4): TVecF32x4;   // ln(x)
function VecF32x4Log2(const a: TVecF32x4): TVecF32x4;  // log2(x)
function VecF32x4Log10(const a: TVecF32x4): TVecF32x4; // log10(x)
function VecF32x4Pow(const base, exp: TVecF32x4): TVecF32x4;  // base^exp
```

#### 反三角函数
```pascal
function VecF32x4Asin(const a: TVecF32x4): TVecF32x4;  // arcsin(x), x ∈ [-1,1]
function VecF32x4Acos(const a: TVecF32x4): TVecF32x4;  // arccos(x), x ∈ [-1,1]
function VecF32x4Atan(const a: TVecF32x4): TVecF32x4;  // arctan(x)
function VecF32x4Atan2(const y, x: TVecF32x4): TVecF32x4;  // arctan2(y, x)
```

### 高级算法

#### 排序网络 (Sorting Networks)
SIMD 友好的小数组排序，使用固定比较交换网络。

```pascal
function SortNet4I32(const a: TVecI32x4; ascending: Boolean = True): TVecI32x4;
```
对 4 个 Int32 元素排序。
- `ascending`: True 为升序，False 为降序
- 使用 5 次比较交换操作

```pascal
function SortNet4F32(const a: TVecF32x4; ascending: Boolean = True): TVecF32x4;
```
对 4 个 Single 元素排序。

```pascal
function SortNet8I32(const a: TVecI32x8; ascending: Boolean = True): TVecI32x8;
```
对 8 个 Int32 元素排序。

**示例**：
```pascal
var v: TVecI32x4;
begin
  v.i[0] := 4; v.i[1] := 1; v.i[2] := 3; v.i[3] := 2;
  v := SortNet4I32(v, True);   // [1, 2, 3, 4]
  v := SortNet4I32(v, False);  // [4, 3, 2, 1]
end;
```

#### 前缀和 (Prefix Sum / Scan)

```pascal
function PrefixSumI32x4(const a: TVecI32x4; inclusive: Boolean = True): TVecI32x4;
function PrefixSumF32x4(const a: TVecF32x4; inclusive: Boolean = True): TVecF32x4;
```
向量前缀和。
- `inclusive=True`: `[a0, a0+a1, a0+a1+a2, a0+a1+a2+a3]`
- `inclusive=False`: `[0, a0, a0+a1, a0+a1+a2]` (exclusive)

```pascal
procedure PrefixSumArrayI32(src, dst: PInt32; count: SizeUInt);
procedure PrefixSumArrayF32(src, dst: PSingle; count: SizeUInt);
```
数组前缀和，结果写入 dst。

**示例**：
```pascal
var v, r: TVecI32x4;
    arr, out_arr: array[0..7] of Int32;
begin
  // 向量前缀和
  v.i[0] := 1; v.i[1] := 2; v.i[2] := 3; v.i[3] := 4;
  r := PrefixSumI32x4(v, True);   // [1, 3, 6, 10]
  r := PrefixSumI32x4(v, False);  // [0, 1, 3, 6]
  
  // 数组前缀和
  arr[0] := 1; arr[1] := 2; arr[2] := 3; arr[3] := 4;
  PrefixSumArrayI32(@arr[0], @out_arr[0], 4);  // [1, 3, 6, 10]
end;
```

#### 字符串搜索

```pascal
function StrFindChar(p: Pointer; len: SizeUInt; ch: Byte): PtrInt;
```
在字节序列中查找单个字符。
- `p`: 搜索起点
- `len`: 搜索长度
- `ch`: 要查找的字节值
- 返回值：找到返回位置索引 (0-based)，未找到返回 -1

**示例**：
```pascal
var
  text: AnsiString;
  pos: PtrInt;
begin
  text := 'Hello, World!';
  pos := StrFindChar(@text[1], Length(text), Ord('W'));  // 返回 7
  pos := StrFindChar(@text[1], Length(text), Ord('x'));  // 返回 -1
end;
```

## 性能指南

### 何时使用 SIMD

#### 适合 SIMD 的场景
- **大批量数据处理**：数据量 >= 64 字节时 SIMD 优势明显
- **内存密集操作**：MemEqual/MemFindByte/SumBytes 等
- **批量数值计算**：向量加减乘除、数学函数
- **字符串/文本处理**：UTF-8 验证、大小写转换、比较
- **位集操作**：PopCount、批量位操作

#### 不适合 SIMD 的场景
- **小数据量**：< 16 字节时标量可能更快（派发开销）
- **分支密集代码**：SIMD 不擅长条件跳转
- **随机内存访问**：不连续的数据难以向量化
- **依赖链计算**：每步依赖前一步结果的计算

### 最佳实践

#### 1. 数据对齐
```pascal
// 推荐：16/32 字节对齐的数据
var
  data: array[0..1023] of Single; align 32;  // AVX2 对齐
```
未对齐数据也能工作，但对齐可提升 5-15% 性能。

#### 2. 批量处理
```pascal
// 不推荐：逐元素调用
for i := 0 to Length(arr) - 1 do
  result := SomeSimdFunc(@arr[i], 1);

// 推荐：一次性处理整个数组
result := SomeSimdFunc(@arr[0], Length(arr));
```

#### 3. 避免混合使用 AVX 和 SSE
混合使用会导致性能惩罚（状态切换）。本库内部已处理 `vzeroupper`。

#### 4. 向量类型使用
```pascal
// 好：使用运算符重载
var a, b, c: TVecF32x4;
c := a + b * 2.0;

// 避免：在紧密循环中访问单个元素
for i := 0 to 3 do
  total := total + v.f[i];  // 改用归约操作
```

### 性能对比参考

测试环境：4096 字节数据，1M 次迭代

| 函数 | Scalar | SSE2 | AVX2 | 加速比 |
|------|--------|------|------|--------|
| MemEqual | 11804ms | 774ms | 153ms | **77x** |
| MemFindByte | 657ms | 52ms | 11ms | **60x** |
| SumBytes | 10267ms | 759ms | 98ms | **105x** |
| BitsetPopCount | 81136ms | - | 539ms | **151x** |
| Utf8Validate | 2936ms | - | 318ms | **9x** |
| AsciiIEqual | 5894ms | - | 247ms | **24x** |

### 调试与排障

#### 强制使用标量后端
```bash
# 用于对拍测试或排除 SIMD 问题
export FAFAFA_SIMD_FORCE=SCALAR
./your_program
```

#### 查询当前后端
```pascal
WriteLn('Backend: ', GetCurrentBackendInfo.Name);  // 输出 "AVX2"/"SSE2"/"Scalar"
```

#### 常见问题
1. **性能未达预期**：检查数据量是否足够大，小数据量 SIMD 优势不明显
2. **结果不一致**：设置 `FAFAFA_SIMD_FORCE=SCALAR` 对拍确认是否为 SIMD 实现问题
3. **崩溃/越界**：检查指针和长度参数是否正确
