# fafafa.core.simd 阅读地图

如果你只想找对的入口，这页就是最短路径。

## 先看哪份

- 想直接写代码：看 `docs/fafafa.core.simd.api.md`
- 想知道模块全貌：看 `docs/fafafa.core.simd.md`
- 想修 dispatch / backend：看 `src/fafafa.core.simd.dispatch.pas`
- 想判断稳定边界：看 `src/fafafa.core.simd.STABLE`
- 想做 adapter 对齐：看 `src/fafafa.core.simd.backend.iface.pas`、`src/fafafa.core.simd.backend.adapter.pas`、`tests/fafafa.core.simd/check_backend_adapter_sync.py`
- 想看本轮交接结论：看 `docs/fafafa.core.simd.handoff.md`

## 当前真相源

- `src/fafafa.core.simd.pas`：公开 façade / umbrella unit
- `src/fafafa.core.simd.dispatch.pas`：`TSimdDispatchTable`、base fallback、运行时派发
- `src/fafafa.core.simd.STABLE`：稳定 ABI / 公开边界约束
- `src/fafafa.core.simd.backend.iface.pas` + `src/fafafa.core.simd.backend.adapter.pas`：adapter-managed 结构，不替代 flat dispatch table
- `tests/fafafa.core.simd/BuildOrTest.sh`：Linux/macOS 侧主门禁与回归入口

## 维护时先记住三句

- public façade 能调用的 slot，必须先在 `TSimdDispatchTable` 落地
- `backend.iface` 是 adapter 形状，不是 `TSimdDispatchTable` 的替代真相源
- `sbRISCVV` 默认不接进 umbrella；只有定义 `SIMD_EXPERIMENTAL_RISCVV` 才会启用
