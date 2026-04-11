# fafafa.core.endian — 端序语义与 ByteSwap 基础能力

> 当前 strict L0 边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> `fafafa.core.endian` 属于 strict non-SIMD L0，负责独立的端序语义，而不是继续埋在 `bytes` consumer 里。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.endian.pas`
5. `tests/fafafa.core.endian/README.md`
6. `tests/fafafa.core.endian/BuildOrTest.sh`
7. `tests/fafafa.core.endian/BuildOrTest.bat`

## 当前兼容策略

- `fafafa.core.endian` 是 `TEndianness`、native 解析与 byte-swap helper 的当前定义点。
- `fafafa.core.bytes` 现在显式依赖 `fafafa.core.endian`，并保留 `TEndianness` / `enLittleEndian` / `enBigEndian` / `enNative` 的兼容别名，避免破坏旧调用点。
- 新代码应优先直接使用 `fafafa.core.endian`，不要再把端序语义视作 `bytes` 的内部实现细节。

## 目标

- 提供最基础、最稳定的端序表达与 byte-swap 能力。
- 让 `bytes`、协议解析、序列化与底层 IO 都能复用同一套端序语义。
- 保持 API 面最小，不把读写缓冲、协议格式或字节容器一并拖进 L0。

## 当前 API

- `TEndianness = (enLittleEndian, enBigEndian, enNative)`
- `NativeEndianness`
- `ResolveEndianness`
- `IsLittleEndian`
- `IsBigEndian`
- `ByteSwap16`
- `ByteSwap32`
- `ByteSwap64`

## 当前边界

- 这里只定义端序枚举、native 解析和 byte-swap helper，不替代 `bytes` 模块的端序读写 API。
- `enNative` 的语义是“按当前平台本机端序解释”，不是第三种独立字节序。
- 如果你要看 `bytes` 域的实际读写接口，回 `docs/fafafa.core.bytes.md` 与 `src/fafafa.core.bytes.pas`；如果你要看 strict L0 合同，回本文件和 `src/fafafa.core.endian.pas`。

## 测试

- Linux/macOS：`bash tests/fafafa.core.endian/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.endian\\BuildOrTest.bat test`
- 当前测试入口会锁定 native 端序解析、`ResolveEndianness`、`IsLittleEndian/IsBigEndian` 关系和 `ByteSwap16/32/64` 的 involution 语义。
- 如果你是在 Linux x64 上做 strict L0 日常维护，优先从 `bash tests/run_strict_l0_maintenance_loop.sh` 开始，而不是只单跑当前模块。
- 如果你需要 exact Windows native evidence，当前只接受 GitHub Actions 或真实 Windows runner 产物。
