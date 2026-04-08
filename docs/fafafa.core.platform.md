# fafafa.core.platform — 最小静态平台表达

> 当前 strict L0 边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> `fafafa.core.platform` 属于 strict non-SIMD L0，只负责静态平台表达，不承载 system probe 或 runtime capability 语义。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.platform.pas`
5. `tests/fafafa.core.platform/README.md`
6. `tests/fafafa.core.platform/BuildOrTest.sh`
7. `tests/fafafa.core.platform/BuildOrTest.bat`

## 目标

- 提供一个足够小、跨模块可复用的平台识别合同。
- 让 `simd`、`sync`、`io`、`os` 等上层模块共享同一套 OS / arch / pointer-width 基础表达。
- 保持 API 为静态表达层，不把 env/path/feature detection 一并拉进 L0。

## 当前 API

- `TPlatformOS`
- `TPlatformArch`
- `TPlatformTarget`
- `PlatformOS`
- `PlatformArch`
- `PlatformPointerBits`
- `PlatformEndianness`
- `PlatformIs64Bit`
- `PlatformTarget`
- `PlatformOSName`
- `PlatformArchName`

## 当前边界

- 这里只定义编译目标对应的最小平台表达。
- `TPlatformTarget` 只是把静态事实组合成一个小 record，不引入新的 runtime probe。
- 不纳入：
  - hostname / username / home dir / temp dir / exe path
  - OS 版本详细信息
  - CPU 数量、CPU feature、SIMD feature
  - memory / storage / network / load
  - container / CI / admin / WSL 检测
- 这些能力继续属于 `fafafa.core.os`、`fafafa.core.simd.cpuinfo` 或更高层模块。

## 测试

- Linux/macOS：`bash tests/fafafa.core.platform/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.platform\\BuildOrTest.bat test`
- 当前测试入口会锁定 compile-target 与 `PlatformOS` / `PlatformArch` 的一致性，以及 pointer width / endianness / `PlatformTarget` 组合语义的稳定性。
