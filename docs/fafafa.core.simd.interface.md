# fafafa.core.simd 接口分层与命名约定

这份文档专门收口 `simd` 模块的接口设计结论。目标只有一个：把公开层次、canonical 入口、兼容别名说死，避免继续把不同语义的 “available / active / best backend” 混在一起。

## 结论

当前 `simd` 的接口问题，核心不是能力缺失，而是历史别名过多、层次容易误读。这个 round 的最终口径是：

- `fafafa.core.simd` 是总 façade，负责向量/数学入口，并提供少量高频 runtime convenience wrapper
- `fafafa.core.simd.api` 只负责 mem/text/stat data-plane façade
- `fafafa.core.simd.runtime` 是 backend control-plane 与 runtime state 的 canonical 入口
- `fafafa.core.simd.cpuinfo` 是 CPU/OS capability 视图的 canonical 入口
- 所有 legacy alias 继续保留兼容，但新代码、示例、文档默认只使用 canonical 名称

## 分层职责

### `fafafa.core.simd`

- 面向业务调用方的一站式入口
- canonical 暴露向量/数学 façade
- 额外重导出少量 runtime / cpuinfo convenience wrapper，便于常见调用方不分层导入

### `fafafa.core.simd.api`

- 只放 data-plane façade
- 典型入口：`MemEqual`、`MemFindByte`、`Utf8Validate`、`AsciiIEqual`、`BytesIndexOf`
- 不承担 backend 选择、CPU 能力判断、注册状态查询

### `fafafa.core.simd.runtime`

- canonical control-plane
- canonical runtime state view
- canonical dispatchable / registered / active backend 语义
- `TSimdRuntimeSnapshot` 类型也归这个单元所有；如果调用方要显式声明 snapshot 变量，应该直接 `uses fafafa.core.simd.runtime`
- backend 列表容器 `TSimdBackendArray` 属于 `fafafa.core.simd.base`，`runtime` / `cpuinfo` 只是返回它

### `fafafa.core.simd.cpuinfo`

- canonical CPU/OS capability view
- 只回答“这台机器/当前 OS 能不能用”
- 不回答“当前二进制是否已注册”或“当前是否可派发”

### `fafafa.core.simd.dispatch`

- 更低层的 dispatch contract 与维护入口
- 仍然稳定，但不再是普通调用方默认 control-plane API
- 主要面向维护、测试、底层 wiring

## 实现层口径

这一层不面向普通调用方，但必须统一口径：

- `fafafa.core.simd.*` backend unit：`backend adapter / backend assembly layer`
- `fafafa.core.simd.intrinsics.*`：`raw ISA leaf / low-level semantic leaf`

职责切分：

- backend adapter 负责 `TVec*` / `TMask*` façade 语义、dispatch 注册、backend 能力接线、必要的多寄存器拼装与 façade helper
- raw ISA leaf 只负责原始寄存器或原始 intrinsic 风格接口，例如 `TM128/TM256/TM512`
- raw ISA leaf 不负责 dispatch table 注册
- raw ISA leaf 不负责 façade 级 `TVec*` 公开语义
- raw ISA leaf 不负责 backend selection / runtime control-plane

当前 SSE2 的专门判断：

- `src/fafafa.core.simd.sse2.pas` 是当前 backend adapter truth source
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas` 是未来 raw leaf 的目标落点
- `src/fafafa.core.simd.intrinsics.sse2.pas` 是 transitional compatibility wrapper

对应真相表：

- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`

如果你这次讨论的是“为什么不能把 backend adapter 整层拿掉、直接做 façade -> intrinsics 两层直通”，统一以 `docs/SIMD_LAYERING_IMPLEMENTATION.md` 为准。

## 四层 backend 语义

| 语义 | 定义 | canonical 入口 |
|------|------|----------------|
| `supported_on_cpu` | 当前 CPU/OS 能力允许 | `cpuinfo.GetSupportedBackendList` / `cpuinfo.GetBestSupportedBackend` |
| `registered` | 当前二进制已经注册 | `runtime.GetRegisteredBackendList` / `runtime.IsBackendRegisteredInBinary` |
| `dispatchable` | CPU 支持 + 已注册 + `BackendInfo.Available=True` | `runtime.GetDispatchableBackendList` / `runtime.GetBestDispatchableBackend` |
| `active` | 当前真正生效的 backend | `runtime.GetCurrentRuntimeSnapshot` / `runtime.GetCurrentBackend` |

规则：

- 不再把一个含糊的 `available` 当通用总称
- `cpuinfo` 的 “available” 历史别名仍表示 `supported_on_cpu`
- façade / runtime 的 `GetAvailableBackendList` 历史别名表示 `dispatchable`

## Canonical 名称

### CPU capability

- `GetCPUInfo`
- `IsBackendSupportedOnCPU`
- `GetSupportedBackendList`
- `GetBestSupportedBackend`

### Runtime state

- `GetCurrentRuntimeSnapshot`
- `GetCurrentBackend`
- `GetCurrentBackendInfo`
- `GetRegisteredBackendList`
- `IsBackendRegisteredInBinary`
- `GetDispatchableBackendList`
- `GetBestDispatchableBackend`

### Runtime control-plane

- `TrySetCurrentBackend`
- `SetCurrentBackend`
- `ResetCurrentBackendSelection`

## Compatibility aliases

这些接口现在保留，但只按 compatibility alias 理解：

### `cpuinfo` aliases

- `GetSupportedBackends` -> `GetSupportedBackendList`
- `GetAvailableBackends` -> `GetSupportedBackendList`
- `GetBestBackendOnCPU` -> `GetBestSupportedBackend`
- `GetBestBackend` -> `GetBestSupportedBackend`

### `runtime` / façade aliases

- `GetCPUInfo`：`fafafa.core.simd` 直接重导出的 canonical convenience wrapper
- `GetCurrentSimdRuntimeSnapshot` -> `GetCurrentRuntimeSnapshot`
- `GetAvailableBackendList` -> `GetDispatchableBackendList`
- `GetCPUInformation` -> `GetCPUInfo`
- `TryForceBackend` -> `TrySetCurrentBackend`
- `ForceBackend` -> `SetCurrentBackend`
- `ResetBackendSelection` -> `ResetCurrentBackendSelection`

### `dispatch` low-level names

- `IsBackendAvailableOnCPU`（low-level compatibility alias；新代码改用 `cpuinfo.IsBackendSupportedOnCPU`）
- `GetActiveBackend`
- `TrySetActiveBackend`
- `SetActiveBackend`
- `ResetToAutomaticBackend`

这些名字不是废弃实现，但已经降级为低层入口；新代码不再默认推荐直接面向它们写 control-plane。

## 推荐用法

### 查询 CPU 能力

```pascal
uses fafafa.core.simd.cpuinfo;

LBackends := GetSupportedBackendList;
LBest := GetBestSupportedBackend;
```

### 查询当前 runtime 状态

```pascal
uses fafafa.core.simd.runtime;

LSnapshot := GetCurrentRuntimeSnapshot;
LDispatchable := GetDispatchableBackendList;
```

### 强制切换 backend

```pascal
uses fafafa.core.simd.runtime;

if TrySetCurrentBackend(sbScalar) then
  DoSomething;
ResetCurrentBackendSelection;
```

## 本轮接口审查的封边标准

本轮之后，接口层按下面标准理解：

- 文档、示例、smoke 默认只展示 canonical 名称
- legacy alias 只在兼容说明和契约测试里出现
- `runtime` 与 `cpuinfo` 的语义边界明确分离
- `dispatch` 保留为低层 contract，不再承担默认公开 control-plane 教程入口

下一轮如果继续审查，应只看实现质量、线程安全细节、fallback/adapter wiring 等实现问题，而不是重新争论公开接口叫什么。
