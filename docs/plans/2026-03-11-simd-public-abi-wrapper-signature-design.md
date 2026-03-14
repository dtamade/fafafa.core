# SIMD Public ABI Wrapper / Signature Design

> **Status:** phase-a implemented
>
> **Scope:** define a public ABI boundary for SIMD without promoting the current `TSimdDispatchTable` to a public binary ABI.

## 1. 结论先行

推荐方案：

- 保留现有 `fafafa.core.simd` / `dispatch` / `backend.adapter` 作为**仓库内实现层**
- public ABI wrapper 的**公开入口**仍然放在 `fafafa.core.simd` 单元，遵循 `fafafa.core` 的统一范式
- 如需辅助实现层，可放在非公开 helper/include 中，但**不**新增一个新的公开顶层入口单元来替代 `fafafa.core.simd`
- 该 wrapper 层只暴露：
  - POD metadata
  - ABI version / ABI signature
  - backend capability query
  - 已绑定的 public function table，供外部缓存后直调
  - 少量高 ROI façade 类函数
- **不**直接导出 `TSimdDispatchTable`
- **不**把 `TVec*` record 按值调用当成第一版 public ABI 主面

这是当前最低风险、性能最可控、最不容易把内部实现细节锁死的方案。

## 2. 为什么不该直接公开 `TSimdDispatchTable`

当前仓库内 contract 和外部 ABI 是两件事。

现状：

- `TSimdBackendInfo` 含 `Name: string` / `Description: string`
- `TSimdDispatchTable` 内嵌 `TSimdBackendInfo`
- 因此当前 record layout 带 managed field，不能被当作 public binary ABI

这也是当前仓库已经明确写死的边界：

- `src/fafafa.core.simd.STABLE`
- `docs/fafafa.core.simd.closeout.md`

结论：

- 现有 dispatch table 适合做 **in-repo dispatch contract**
- 不适合直接做 **external/public binary ABI**

如果直接公开，会把下面几类东西一起锁死：

- Pascal record field order
- managed string representation 与生命周期
- backend metadata layout
- 当前内部 dispatch 组织方式
- 未来 adapter / backend.iface 的演进空间

这条路会把“内部实现 contract”错误升级成“外部兼容负债”。

## 3. 性能视角下的核心判断

### 3.1 热路径最怕 hidden copy 和 aggregate ABI 差异

对外 ABI 如果大量使用“按值传递大 struct / vector record”，性能和可移植性都会变差。

Windows x64 官方 calling convention 文档明确指出：

- 不是 `1/2/4/8` 字节大小的 struct/union 会按引用传递

这意味着像 `TVecF32x4`、`TVecF32x8`、`TVecU32x16` 这类向量 record，跨语言 ABI 下很容易出现：

- hidden pointer
- caller/callee copy
- 编译器间不一致的 aggregate lowering

对应源码中已经能看到你们现在非常依赖平台 ABI 细节：

- `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- `src/fafafa.core.simd.sse2.pas`
- `src/fafafa.core.simd.neon.pas`

这些都说明：**内部可以做，外部 ABI 不应直接照搬。**

### 3.2 调用边界开销要让给“大工作量函数”，不要浪费在小粒度向量算子上

对于 public ABI，真正值得暴露的是“每次调用做的事足够大”的函数：

- `MemEqual`
- `MemFindByte`
- `SumBytes`
- `CountByte`
- `BitsetPopCount`
- `Utf8Validate`
- `AsciiIEqual`

这些 API 的共同特点：

- 参数天然是 pointer + len
- 调用边界开销占比低
- 跨语言调用容易绑定
- 平台 ABI 差异小

而像下面这类算子，不适合作为第一阶段 public ABI 主面：

- `VecF32x4Add`
- `VecU64x8Add`
- `VecU32x16Mul`

原因不是它们没价值，而是：

- 每次工作量太小
- ABI lowering 风险高
- hidden copy 容易把 SIMD 核心收益吃掉
- 一旦导出，就会把调用约定和布局承诺一起锁死

### 3.3 不要做“双重分发”

如果 public ABI 变成：

`外部调用 -> public wrapper -> GetDispatchTable -> TSimdDispatchTable 查表 -> 再间接调用`

那就是热点路径里的重复开销。

这类设计的问题有两个：

- 每次调用都多做一次内部 dispatch lookup
- 外部 ABI 层只是把内部调度成本再包一层，没有提供真正稳定的数据面

因此推荐的数据面模型必须是：

- 控制面先做一次绑定
- 返回一个 **POD-only public function table**
- 调用方缓存该表
- 后续直接调用表里的函数指针

也就是说，public ABI wrapper 应该是：

- **入口在 `fafafa.core.simd`**
- **数据面是“绑定后直调”**
- **不是“每次 wrapper 再转进内部 dispatch table”**

### 3.4 metadata 必须冷路径化

backend 名称、描述、能力等 metadata 不该进入热路径。

最好的做法是：

- POD struct 里只放整数/位图/flags/version
- 文本名称通过独立 query function 返回静态 `const char*`
- 或者根本不把字符串放进 ABI metadata 主 struct

这样可以同时满足：

- struct 可 blittable / POD 化
- layout 更容易 static assert
- 语言绑定更简单
- metadata query 不污染热路径

### 3.5 signature 应预计算，不应运行时动态组装

ABI signature 的目的不是安全加密，而是：

- 明确“你拿到的是哪份 ABI 契约”
- 在 smoke test / integration test / plugin load 时快速 fail-fast

所以最佳实践是：

- 在构建期或源码中固化 signature 常量
- 运行时只返回常量，不做动态拼接和哈希

现在仓库内 `check_dispatch_contract_signature.py` 已经验证了这条思路在内部 contract 上可行。

public ABI 也应复制这个思路，而不是在 DLL/SO 每次初始化时重算。

## 4. 推荐的 public ABI 形态

### 4.1 不公开 dispatch table，公开 `fafafa.core.simd` wrapper surface

公开入口应继续保留在：

- `src/fafafa.core.simd.pas`

它的职责不是复刻内部 dispatch，而是提供一个**稳定、最小、POD-only** 的外部边界。

如果实现上需要隔离脏逻辑，可以考虑：

- `fafafa.core.simd` 里声明 public ABI record / getter
- 具体构建逻辑落到非公开 helper/include

但对调用方来说，**范式入口仍然只有 `fafafa.core.simd`**。

### 4.2 推荐的导出面

第一批建议只放 3 类导出：

#### A. ABI / runtime self-description

- `fafafa_simd_abi_version_major()`
- `fafafa_simd_abi_version_minor()`
- `fafafa_simd_abi_signature()`
- `fafafa_simd_runtime_info(out info)`

#### B. backend query / control-plane

- `fafafa_simd_backend_active()`
- `fafafa_simd_backend_is_supported_on_cpu(backend_id)`
- `fafafa_simd_backend_is_dispatchable(backend_id)`
- `fafafa_simd_backend_query(backend_id, out pod_info)`

注意：

- 不建议一开始就公开“强制切 backend”作为跨语言常规 API
- 如果保留，也应清楚标成 control-plane only

#### C. data-plane 高 ROI façade / bound api table

- `fafafa_simd_mem_equal`
- `fafafa_simd_mem_find_byte`
- `fafafa_simd_sum_bytes`
- `fafafa_simd_count_byte`
- `fafafa_simd_bitset_popcount`
- `fafafa_simd_utf8_validate`
- `fafafa_simd_ascii_iequal`

参数统一原则：

- `const void*` / `void*`
- `size_t` / `uint64_t`
- `int32_t` / `uint32_t`
- `bool` 不直接进 ABI struct；优先 `uint8_t` / `uint32_t`

同时建议提供一个“绑定后直调”的 public API table 获取入口，例如：

- `fafafa_simd_get_public_api(out api_table)`

要求：

- 返回的是 **public POD function table**
- 不是当前 `TSimdDispatchTable`
- 调用方可以长期缓存
- backend 切换后若需要刷新，由控制面显式触发重新获取

## 5. POD wrapper 该长什么样

### 5.1 backend info 不要直接复用 `TSimdBackendInfo`

推荐拆成类似：

```c
typedef struct fafafa_simd_backend_pod_info_t {
  uint32_t struct_size;
  uint32_t backend_id;
  uint64_t capability_bits;
  uint32_t flags;
  int32_t priority;
} fafafa_simd_backend_pod_info_t;
```

说明：

- `struct_size` 用于向前/向后兼容
- `backend_id` 替代 Pascal enum layout 暴露
- `capability_bits` 替代 Pascal set layout 暴露
- `flags` 承载 `supported/registered/dispatchable/experimental` 等布尔状态
- `priority` 保留调试/排序信息

### 5.2 字符串单独 query

例如：

- `const char* fafafa_simd_backend_name(uint32_t backend_id);`
- `const char* fafafa_simd_backend_description(uint32_t backend_id);`

要求：

- 返回静态只读字符串
- 生命周期为进程全程有效
- 不要求调用方释放

这样比把字符串塞进 ABI struct 更稳。

## 6. calling convention 建议

原则：

- public ABI 必须显式声明 calling convention
- 内部 Pascal 默认调用约定不能当外部约定使用

当前能确认的点：

- FPC 官方文档建议外部 routine 用正确 calling convention，和 C 编译器互操作时使用 `cdecl`
- FPC 在 x86_64 上提供 `sysv_abi_cdecl`
- Windows x64 的 native calling convention 会把很多 struct 按引用传递，这对 vector-by-value API 很不友好

因此建议：

- façade 类 public ABI：统一用 C ABI 风格导出
- x86_64 SysV 平台优先考虑显式 `sysv_abi_cdecl`
- 其它平台保持与平台 C ABI 对齐
- 不把 vector-by-value 作为第一阶段设计中心

## 7. 推荐的验证方案

### 7.1 仓库内 contract

继续保留现有：

- `check_dispatch_contract_signature.py`
- `DispatchAllSlots` roundtrip test
- `adapter-sync`
- `interface-completeness`

### 7.2 public ABI wrapper

新增后应至少有 4 组验证：

1. **POD layout smoke**
   - `SizeOf`
   - 字段顺序/偏移
   - `struct_size` 协议

2. **signature smoke**
   - 导出 signature 常量
   - 调用方校验签名不匹配时 fail-fast

3. **cross-language smoke**
   - 至少一份 C harness
   - Windows / Linux 各跑一次

4. **semantic parity**
   - public ABI 调 façade
   - 结果与现有 Pascal façade 一致

## 8. 我建议的新阶段切法

不要上来做“完整 public SIMD ABI”。

按最稳路线切：

### 阶段 A：定义 public ABI wrapper 设计与边界

- 明确不公开 `TSimdDispatchTable`
- 明确只公开 POD metadata + signature + 少量 façade
- 明确 backend 状态四层语义在 ABI 里的表达方式

### 阶段 B：先落 metadata + signature + query

- `abi_version`
- `abi_signature`
- `backend_query`
- `active_backend`

当前进展（2026-03-11）：

- 已在 `fafafa.core.simd` 内落下第一版 public ABI skeleton
- 已提供：
  - `TFafafaSimdBackendPodInfo`
  - `TFafafaSimdPublicApi`
  - `GetSimdAbiVersionMajor/Minor`
  - `GetSimdAbiSignature`
  - `TryGetSimdBackendPodInfo`
  - `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr`
  - `GetSimdPublicApi`
- data-plane 已采用“绑定后直调”模式：
  - `GetSimdPublicApi` 返回缓存的 public API table
  - backend 切换后通过 dispatch hook 重绑
  - 不重复查 `TSimdDispatchTable`
- public API table 当前已改为 C ABI shim：
  - table 内函数指针使用 `cdecl`
  - shim 内部调用缓存后的 bound 函数指针
  - 只有异常兜底路径才会直接回读当前 dispatch table

### 阶段 C：再落高 ROI façade 导出

- memory/text/bitset/search 这类 pointer+len API

### 阶段 D：最后再评估是否要导出 vector 算子

只有当：

- 有明确跨语言用户
- 有真实性能收益
- 有稳定的调用约定测试

才考虑继续。

## 9. 性能结论

如果只从性能角度判断，最优路线不是“把现有 dispatch table 直接推出去”，而是：

- **内部继续保留现有 SIMD 架构**
- **外部只暴露少量高工作量 façade**
- **metadata/signature 冷路径化**
- **vector-by-value ABI 延后**

这是当前最像“只留最好的代码”的路线。

## 10. 推荐决策

推荐你批准下面这条设计原则：

> public ABI wrapper 的公开入口放在 `fafafa.core.simd`，但其数据面只暴露新的 POD-only public function table；`TSimdDispatchTable` 继续只做仓库内 dispatch contract。

如果这个原则成立，后续实现会更简单，也更不容易把现在这套内部设计拖进 ABI 包袱。

## 参考资料

- Free Pascal Programmer’s Guide: calling convention modifier  
  https://www.freepascal.org/docs-html/3.0.0/prog/progsu150.html
- Free Pascal Reference: `SYSV_ABI_CDecl`  
  https://www.freepascal.org/docs-html/ref/refsu95.html
- Microsoft x64 calling convention overview  
  https://learn.microsoft.com/en-us/archive/msdn-magazine/2006/may/x64-starting-out-in-64-bit-windows-systems-with-visual-c
