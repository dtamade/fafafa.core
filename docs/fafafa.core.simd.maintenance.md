# fafafa.core.simd 维护指南

这份文档面向维护 `fafafa.core.simd` 的开发者，重点说明现在的代码组织、推荐阅读顺序、哪些地方适合继续整理，以及哪些地方暂时不要再拆。

如果你只想快速定位入口，再看 `docs/fafafa.core.simd.map.md`。

如果你只想看“现在该做什么”，再看 `docs/fafafa.core.simd.checklist.md`。

如果你想快速了解当前收口已经做到哪里，以及后续最值得做什么，再看 `docs/fafafa.core.simd.handoff.md`。

## 先看什么

如果你第一次接手这个模块，建议按这个顺序读：

1. `src/fafafa.core.simd.README.md`
2. `docs/fafafa.core.simd.md`
3. `src/fafafa.core.simd.architecture.md`
4. `src/fafafa.core.simd.pas`
5. `src/fafafa.core.simd.dispatch.pas`
6. `src/fafafa.core.simd.cpuinfo.pas`
7. 具体后端（`avx2` / `avx512` / `neon` / `sse2`）

这个顺序有两个好处：

- 先理解对外 API 和运行时派发，再去看 ISA 细节。
- 先理解“主单元 + include 片段”的组织方式，再进入后端实现，不容易在大量汇编和 fallback 代码里迷路。

## 现在的代码组织

当前 `SIMD` 子系统已经从“少量超大 Pascal 单元”收口到“主单元 + include 片段”的结构。

### 主入口层

- `src/fafafa.core.simd.pas`
- `src/fafafa.core.simd.api.pas`
- `src/fafafa.core.simd.base.pas`

这里负责：

- 对外 API
- 类型别名与重导出
- 高层语义包装

其中 `src/fafafa.core.simd.pas` 已经把类型与框架包装拆到 include：

- `src/fafafa.core.simd.types.inc`
- `src/fafafa.core.simd.framework.intf.inc`
- `src/fafafa.core.simd.framework.impl.inc`

### 派发与能力检测层

- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.cpuinfo.pas`
- `src/fafafa.core.simd.backend.priority.pas`

这里负责：

- 后端优先级
- CPU / OS 能力判断
- dispatch table 选择
- runtime hook / backend rebuild

当前更值得关注的真相源：

- `src/fafafa.core.simd.dispatch.pas`：`TSimdDispatchTable` 与 base fallback 的事实真相源
- `src/fafafa.core.simd.cpuinfo.pas`：CPU/OS 支持视图与能力判断入口
- `src/fafafa.core.simd.STABLE`：公开 façade、in-repo dispatch contract 与 stable boundary 的真相源

### 后端层

当前后端大致分三类：

- **稳定基线**：`scalar`、`sse2`
- **已完成较多结构收口**：`avx2`、`avx512`、`neon`
- **特殊平台 / 试验性**：`sse2.i386`、`riscvv`

已经拆出的典型片段包括：

- `*.register.inc`：注册与 initialization
- `*.facade.inc`：门面 / helper / fallback
- `*.family.inc`：按向量族或操作族拆分的实现片段


## Include 清单

下面这份清单不是“完整文件索引”，而是维护时最值得关注的 include 入口。

### 主入口与派发

- `src/fafafa.core.simd.types.inc`
- `src/fafafa.core.simd.framework.intf.inc`
- `src/fafafa.core.simd.framework.impl.inc`
- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.cpuinfo.pas`
- `tests/fafafa.core.simd/check_backend_adapter_sync.py`
- `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`

### 后端注册

- `src/fafafa.core.simd.sse2.register.inc`
- `src/fafafa.core.simd.sse2.i386.register.inc`
- `src/fafafa.core.simd.sse3.register.inc`
- `src/fafafa.core.simd.ssse3.register.inc`
- `src/fafafa.core.simd.sse41.register.inc`
- `src/fafafa.core.simd.sse42.register.inc`
- `src/fafafa.core.simd.avx2.register.inc`
- `src/fafafa.core.simd.avx512.register.inc`
- `src/fafafa.core.simd.neon.register.inc`
- `src/fafafa.core.simd.riscvv.register.inc`

### 后端辅助区块

- `src/fafafa.core.simd.avx2.facade.inc`
- `src/fafafa.core.simd.avx512.facade.inc`
- `src/fafafa.core.simd.avx512.fallback.inc`
- `src/fafafa.core.simd.avx512.mask_sat.inc`
- `src/fafafa.core.simd.neon.facade_asm.inc`
- `src/fafafa.core.simd.neon.facade_scalar.inc`
- `src/fafafa.core.simd.neon.facade_platform.inc`
- `src/fafafa.core.simd.neon.dot.inc`
- `src/fafafa.core.simd.neon.scalar_fallback.inc`

### 族级实现（代表性）

- `src/fafafa.core.simd.avx512.f32x16_*.inc`
- `src/fafafa.core.simd.avx512.f64x8_*.inc`
- `src/fafafa.core.simd.avx512.i32x16_*.inc`
- `src/fafafa.core.simd.avx512.i64x8_*.inc`
- `src/fafafa.core.simd.avx512.u32x16_family.inc`
- `src/fafafa.core.simd.avx512.u64x8_family.inc`
- `src/fafafa.core.simd.avx512.i16x32_family.inc`
- `src/fafafa.core.simd.avx512.i8x64_family.inc`
- `src/fafafa.core.simd.avx512.u8x64_family.inc`
- `src/fafafa.core.simd.avx2.f32x8_*.inc`
- `src/fafafa.core.simd.avx2.f64x4_*.inc`
- `src/fafafa.core.simd.avx2.i32x8_family.inc`
- `src/fafafa.core.simd.avx2.wide_emulation.inc`
- `src/fafafa.core.simd.neon.scalar.*.inc`

这份清单的用途不是“让你全部读完”，而是帮你在改动前快速定位影响面。


## 命名规则

当前 include 文件名基本遵循这几个模式：

- `*.register.inc`：后端注册与 initialization
- `*.facade.inc`：门面、helper、fallback 快路径
- `*.family.inc`：单个向量族或一组同类操作
- `*.intf.inc` / `*.impl.inc`：主单元拆出来的接口/实现配对
- `*.scalar.*.inc`：NEON 这类后端的标量回退细分片段

推荐继续遵守两个约定：

1. **先后端，后主题**
   - 例如 `avx512.f32x16_math.inc`
   - 而不是把主题放前面，避免排序和 grep 时失焦

2. **名字描述“边界”而不是“意图”**
   - `mask_sat.inc`、`wide_loadstore.inc`、`framework.impl.inc` 这种命名更容易定位真实内容
   - 避免 `misc.inc`、`helpers2.inc` 这种泛名

如果一段代码很难起一个清晰名字，通常也意味着它还不适合继续物理拆分。

## 目录速查

下面这份统计不是精确的代码规模报告，而是帮助维护者快速判断“哪里已经拆得很多，哪里最好别再动”。

| 主题 | include 数量 | 说明 |
|------|-------------|------|
| `dispatch` | 0 | 主逻辑仍集中在 `src/fafafa.core.simd.dispatch.pas` |
| `cpuinfo` | 0 | 后端判断主逻辑仍集中在 `src/fafafa.core.simd.cpuinfo.pas` |
| `sse2` | 14 | 已有一定拆分，但继续细拆风险明显升高 |
| `avx2` | 16 | family/facade 收口较充分 |
| `avx512` | 29 | family 拆分最充分 |
| `neon` | 20 | facade/fallback/family 已较充分拆分 |
| `riscvv` | 3 | 仍偏集中，但主入口已明确 |

用法很简单：

- 想加新功能时，先看这个 backend 是不是已经有合适的 include 边界。
- 想继续重构时，先问自己：这是在“补清晰边界”，还是在“把已经很碎的东西继续打碎”。

后者通常不值得。

## 维护者检查表

改动 `SIMD` 代码前，建议快速过一遍这个清单。

### 改动前

- 确认你改的是哪一层：主入口、dispatch/cpuinfo、后端 register、后端 family，还是 helper/facade。
- 先找对应的 `*.inc`，不要默认主文件就是唯一真实位置。
- 如果改动涉及 backend 选择、hook、能力检测，优先看 `dispatch` / `cpuinfo`，不要只改单个 backend。
- 如果改动涉及 `SSE2`，先判断是不是值得做；很多时候“保持稳态”比继续细拆更好。

### 改动后

日常改动至少跑这四条（快门禁 / 基础门禁）：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

说明：

- `check` 负责编译卫生、基础 runner parity，以及默认启用的轻量静态检查。
- `gate` 负责日常改动使用的快门禁 / 基础门禁；它会串联主要模块回归，并默认包含 `contract-signature` 与 `publicabi-signature` 这类结构护栏，但不会默认打开所有重检查。
- 如果你明确改了 `TSimdBackendInfo` / `TSimdDispatchTable` 的声明形状，先单独跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh contract-signature
python3 tests/fafafa.core.simd/check_dispatch_contract_signature.py --dump-current
```

只有在这是**有意的 in-repo contract 变更**时，才更新 checker 里的 expected signature。

如果你明确改了 public ABI wrapper 的声明/常量/consumer mirror，再额外跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh publicabi-signature
python3 tests/fafafa.core.simd/check_public_abi_signature.py --dump-current
```

准备 closeout / release 时，再补这一条：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

`gate-strict` 是发布门禁 / 完整门禁，会在 `gate` 的基础上额外打开性能烟测、repeat、non-x86 / evidence 等更重的检查。

### 出现异常时先怀疑什么

- `Text file busy`：通常是并发构建/运行冲突，不一定是代码回归。
- `backend_slot_counts` 异常下降：通常是 checker 没跟上 `{$I ...}` include，先看脚本是否递归展开本地 include。
- `Function nesting > 31`：通常是 Pascal 文件中把声明区/实现区切错了，不要继续叠加拆分。
- 链接错误或 VMT 缺失：优先检查单元引用和 initialization / RegisterTest / RegisterBackend 的入口有没有被破坏。

### 什么时候跑哪种门禁

- 日常改动、局部修正、文档同步：优先跑 `check` + 定向 suites + `gate`。
- closeout、发布前回归、需要更强证据链时：在上面的基础上再跑 `gate-strict`。
- 如果你只是确认脚本/文档口径没有漂移，先看 `BuildOrTest.sh` 的 `gate` / `gate-strict` usage 和 gate-summary profile 字段。

### 并发或预演时用隔离输出

如果你在同一台机器上并发跑多个 `SIMD` helper，或者只是想预演 closeout 而不污染默认 `bin2/lib2/logs`，优先设置 `SIMD_OUTPUT_ROOT`。

Run:
```bash
SIMD_OUTPUT_ROOT=/tmp/simd-run-123 bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

或者：
```bash
SIMD_OUTPUT_ROOT=/tmp/simd-run-123 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

这会把主 runner 的 `bin2/lib2/logs` 改写到新根目录下；`cpuinfo` 与 `cpuinfo.x86` 子 runner 在 shell 链路里也会自动落到 `cpuinfo/` 与 `cpuinfo.x86/` 子目录。

Windows batch runner 也已经接入同名环境变量，但这部分目前仍缺 Windows 实机验证。

### 什么时候该停手

如果你发现自己开始：

- 为了拆分而拆分
- 需要跨多个后端同时大改
- 需要改测试文件结构才能继续
- 在 `SSE2` 上持续碰编译器边界

那通常说明这一轮已经不适合继续做物理拆分了。改做文档、清单和设计说明，收益往往更高。

## 推荐继续整理的区域

如果后续还要继续做低风险整理，优先顺序建议如下：

1. 文档同步与阅读地图
2. `dispatch` / `cpuinfo` 的说明补充
3. 已经 include 化的后端片段做命名统一与目录清单整理
4. 小范围 helper 抽离

也就是说，接下来更适合做“结构可读性提升”，而不是继续大量物理拆分。

## 暂时不要再拆的区域

### `src/fafafa.core.simd.sse2.pas`

这是当前最接近风险边界的后端。

原因很简单：

- 它既承担 128-bit 基线实现，又承担很多 256/512 的仿真路径。
- 里面有大量 fallback、宽向量分解、mask/select、舍入与数学函数的交错实现。
- 继续细拆时，Pascal 对函数声明 / 实现布局的要求比较苛刻，稍不注意就容易触发编译问题。

结论：

- 可以继续读、继续审查。
- 可以补文档、补清单。
- 但不建议再做高频的物理拆分，除非先专门做一次针对 `sse2` 的重构设计。

## 读后端时怎么找入口

建议优先看这些片段：

- `*.register.inc`：这个后端到底注册了哪些能力
- `*.facade.inc`：这个后端的 mem/text/search/bitset 快路径在哪里
- `dispatch` / `cpuinfo`：这个后端什么时候会被选中

然后再去看 family 实现，比如：

- `f32x8`
- `f64x4`
- `i32x16`
- `u8x64`

不要一上来就整文件从头读到尾，那样最容易丢上下文。

## 回归时优先跑什么

改动结构但不改语义时，优先回归这些：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

这三项足够覆盖：

- dispatch table 是否还完整
- direct dispatch 是否还跟随主 dispatch
- 关键 gate、coverage、adapter、wiring 是否保持稳定

## 一句话原则

继续维护这个模块时，优先做：

- 结构说明
- 命名统一
- 小块 helper 收口
- 明确稳定边界

尽量少做：

- 对 `SSE2` 这种基线大后端的继续硬拆
- 对测试大文件的物理拆分
- 没有专门设计前的大规模跨后端重排
