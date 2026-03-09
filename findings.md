# Findings

- 当前 BACKEND_PRIORITY 在 dispatch/cpuinfo 内重复 3 处。
- SetDispatchChangedHook 目前是单播槽位，direct 使用它做重绑。
- RegisterBackend 每次注册都会立刻 InitializeDispatch。
- gate 对 windows evidence 默认 fail-open；更适合 release profile 严格化。
- 巨型文件拆分本轮采用“抽取公共策略/机制”为主，避免全量物理拆解风险。
- 候选：将 simd facade 中 backend/cpuinfo alias 与 helper 分组抽离；将 dispatch hook/priority 相关机制继续独立化。
- 第三波进展：SSE2/AVX2/NEON 主文件已保留算子主体，注册区改为 include 接入。
