# fafafa.core.simd handoff

## 2026-03-08 状态

这一轮先把最容易导致 clean build / gate 假绿的问题收掉了。

## 已经收口的点

- `TSimdDispatchTable` 已重新对齐到 `src/fafafa.core.simd.pas` 当前实际访问的公开 slot
- `FillBaseDispatchTable` 已为新增宽向量 slot 补上 fallback，clean build 不再卡在 `Identifier idents no member`
- `src/fafafa.core.simd.types.inc`、`src/fafafa.core.simd.framework.intf.inc`、`src/fafafa.core.simd.framework.impl.inc` 已补齐，公开 façade 不再引用缺失 include
- `tests/fafafa.core.simd/BuildOrTest.sh check` 现在可通过，且不再被缺失脚本卡住
- `adapter-sync` 入口现在会先重建，旧二进制不再有机会掩盖当前源码编译问题
- `sbRISCVV` 不再因为平台满足就默认接线；只有定义 `SIMD_EXPERIMENTAL_RISCVV` 时才会带入 `fafafa.core.simd.riscvv`

## 现在怎么理解真相源

- 稳定 ABI / 公开边界：`src/fafafa.core.simd.STABLE`
- flat dispatch table：`src/fafafa.core.simd.dispatch.pas`
- 公开 façade：`src/fafafa.core.simd.pas`
- adapter 结构与映射：`src/fafafa.core.simd.backend.iface.pas`、`src/fafafa.core.simd.backend.adapter.pas`、`tests/fafafa.core.simd/check_backend_adapter_sync.py`

## 还值得继续做的事

- 把 `TSimdDispatchTable` / façade / adapter 映射进一步收成可生成或可校验的单真相源
- 继续压缩超大后端单元，至少把新增宽向量族优先拆到更稳定的 include 边界
- 继续把 portable cpuinfo 独立 runner 收口到和 x86 runner 同样稳定的 CI 形态
