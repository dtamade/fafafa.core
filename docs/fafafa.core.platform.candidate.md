# fafafa.core.platform 候选审查

> 当前 strict non-SIMD L0 的总边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> 本页不代表 `fafafa.core.platform` 已经存在；它只负责审查“如果要做，这个候选是否值得进入 strict L0”。

## 当前结论

当前不建议直接把 `platform` 做成 strict L0 新模块。

原因不是“平台语义永远不能进 L0”，而是今天仓库里最接近 `platform` 的现有实现并不满足“模块边界小、依赖面窄、长期稳定”的条件。

## 现有证据

### 仓库里没有现成的 `fafafa.core.platform`

当前没有发现：

- `src/fafafa.core.platform.pas`
- `tests/fafafa.core.platform/BuildOrTest.sh`
- 对应 README / 模块文档 / 测试入口

这意味着 `platform` 还不是一个已收敛的模块，只是一个候选名字。

### 仓库里最接近的现有实现是 `fafafa.core.os`

`src/fafafa.core.os.pas` 当前已经承载了大量“平台相关”能力，包括：

- `TPlatformInfo`
- `TOSVersionDetailed`
- `TCPUInfo`
- `TMemoryInfo`
- `TStorageInfo`
- `TNetworkInterface`
- `TSystemInfo`
- `os_platform_info`
- `os_os_version_detailed`
- `os_cpu_info`
- `os_is_admin`
- `os_is_wsl`
- `os_is_container`
- `os_is_ci`

但这组能力明显不是 strict L0 风格的小核模块，而是一个更宽的 OS / system info / capability facade。

### `fafafa.core.os` 的依赖面已经超出 L0 候选应有范围

从 `src/fafafa.core.os.pas` 可见，它直接依赖：

- `SysUtils`
- `Classes`
- `fafafa.core.result`

并且它自己的公开 API 又把很多“best-effort system probe”暴露出来，例如：

- 主机名、用户名、home/temp/exe path
- OS version
- CPU / memory / storage / network / load
- container / CI / admin 检测

这类 API 很难长期保持“小而硬”的基础表达层定位。

## 为什么它现在不适合进 strict L0

根据 L0 准入规则，一个模块进入 L0 至少要满足：

- 只依赖 RTL + 已确认 L0
- 提供跨框架复用的基础表达
- API 面足够小
- 不是服务层 / probe 聚合层 / registry / dispatch

`fafafa.core.os` 现在的主要问题是：

### 1. 它是“信息聚合门面”，不是纯表达层

`TPlatformInfo` 本身接近表达层，但 `os_platform_info` 只是整个 `os` 模块里的一小部分。

一旦直接把这整个模块当作 `platform` 候选，L0 就会被顺带带入：

- system probing
- environment / hostname / username
- filesystem path 语义
- container / CI detection
- network / storage / load

这会把 L0 从 kernel 变成 system facade。

### 2. “platform” 这个名字天然容易变宽

如果没有强约束，`platform` 很容易不断吸收：

- OS family
- architecture
- ABI
- page size
- CPU features
- runtime environment
- process capabilities

最后形成一个“大一统平台工具箱”，这和当前 L0 收紧方向正相反。

### 3. 现有能力里只有一小部分可能像 L0

从 today evidence 看，真正有机会成为 L0 的，顶多是这种极小表达：

- OS family enum
- architecture enum
- pointer width / 64-bit flag
- maybe native endianness

但这里面：

- endianness 已经有 `fafafa.core.endian`
- page size 已经在 `fafafa.core.layout`
- CPU feature detection 则明显更接近 `os` / `simd.cpuinfo`

所以 `platform` 候选真正剩下的核心空间已经很小。

## 如果未来要做，推荐怎么做

### 推荐候选形态

如果未来真的要引入 `fafafa.core.platform`，推荐第一版只允许包含：

- `TPlatformOS = (...)`
- `TPlatformArch = (...)`
- `NativePlatformOS`
- `NativePlatformArch`
- `Is64BitPlatform`

可选但要非常谨慎的项：

- `PointerSize`
- `NativeAbiName`

### 明确不应放进去的内容

第一版不要放：

- hostname / username / home dir / temp dir / exe path
- CPU count / CPU model / CPU features
- memory / storage / network / load
- container / CI / admin / WSL detection
- OS version detailed probing

这些都更像 `os` 域，而不是 strict L0 foundation kernel。

## 当前建议

当前最合理的判断是：

- `fafafa.core.os` 不应整体下沉到 strict L0
- `platform` 只有在被压缩成极小静态表达层后，才值得继续评估

换句话说：

**今天不该把 `platform` 实现成一个大模块；如果要做，只能做一个比 `os` 小得多的纯表达层壳。**
