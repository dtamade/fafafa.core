# fafafa.core.simd 规格说明（定稿）

目的
- 在 FPC 缺少稳定 SIMD 内建支持的现实下，以“手写汇编微内核 + 运行时派发 + 标量回退”的方式，为常见热点提供可选加速。
- 不改变调用方 API 语义；任何平台/构建环境下均可运行；有 SIMD 则自动用更快实现。

设计原则
- 接口稳定、低耦合：对外只暴露语义清晰的函数；不暴露 ISA 细节。
- 运行时派发：初始化时根据 CPU/OS 能力选择最优实现；支持环境/宏强制降级。
- 平滑回退：标量实现永远可用；汇编不可用/检测失败时自动回退。
- 小而精：优先覆盖高 ROI 原语（mem/text/bitset/hash 的核心路径）。
- 命名统一：全部指令集名称使用全大写（SSE2/AVX2/NEON/AVX-512/SVE）。

目录结构（建议）
- src/
  - fafafa.core.simd.pas（门面：类型/函数指针/派发/Info）
  - fafafa.core.simd.detect.pas（能力检测：CPUID/OSXSAVE/XGETBV/NEON 等）
  - fafafa.core.simd.mem.pas（内存与字节原语：标量实现 + SSE2 内核）
  - fafafa.core.simd.text.pas（文本原语：标量实现 + SSE2 快路径）
  - fafafa.core.simd.bitset.pas（位集原语：标量实现 + POPCNT 快路径）
- simd/
  - x86_64/*.S（SSE2/AVX2 微内核，可选）
  - aarch64/*.S（NEON 微内核，可选）

指令集清单（全大写）
- x86/x64：MMX, SSE, SSE2, SSE3, SSSE3, SSE4.1, SSE4.2, POPCNT, LZCNT, AESNI, PCLMULQDQ, SHA, AVX, AVX2, FMA,
  BMI1, BMI2, AVX-512F, AVX-512VL, AVX-512BW, AVX-512DQ, AVX-512VPOPCNTDQ, AVX-512VAES, AVX-512VPCLMULQDQ,
  AVX-512VBMI, AVX-512VBMI2, GFNI 等。
- AArch64：NEON(ASIMD), CRC32(ARMv8.1-CRC), AES, PMULL, SHA1, SHA2, DOTPROD, SVE, SVE2。

能力等级（抽象层）
- LEVEL_0 = SCALAR（无 SIMD）
- LEVEL_1 = SSE2 或 NEON（基线）
- LEVEL_2 = AVX2 或 NEON+CRC/AES（增强）
- LEVEL_3 = AVX-512 或 SVE/SVE2（可选高端）

对外 API（首批）
- Mem
  - function MemEqual(a, b: Pointer; len: SizeUInt): LongBool;
  - function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt; // -1 未找到
  - function MemDiffRange(a, b: Pointer; len: SizeUInt): TDiffRange;      // First/Last 索引，-1/-1 表示完全相同
- Text
  - function Utf8Validate(p: Pointer; len: SizeUInt): LongBool; // 门面在 x86_64 下绑定 FastPath（ASCII SSE2 + 非 ASCII 回退标量）
  - procedure ToLowerAscii(p: Pointer; len: SizeUInt);
  - procedure ToUpperAscii(p: Pointer; len: SizeUInt);
- Bitset
  - function BitsetPopCount(p: Pointer; bitLen: SizeUInt): SizeUInt; // x86_64 若 HasPopcnt 则绑定 POPCNT 快路径
  - procedure BitsetAnd(dst, a, b: Pointer; bitLen: SizeUInt); // Or/Xor/Not 同理（后续增补）

运行时派发与回退
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
