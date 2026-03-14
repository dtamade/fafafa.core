# fafafa.core.simd Public ABI Wrapper

> 本页描述的是 `fafafa.core.simd` 对外暴露的 **public ABI wrapper**。
>
> 它不是当前 `TSimdDispatchTable` 的直接公开版本。`TSimdDispatchTable` 仍然只是仓库内 dispatch contract。
>
> 如果你想看“到底承诺什么”，请继续看 `docs/fafafa.core.simd.publicabi.stability.md`。

## 目标

这个 wrapper 解决的是两个问题：

- 给外部调用方一个 **POD-only**、可验证的稳定边界
- 避免热点路径出现“public wrapper 每次再去查内部 `TSimdDispatchTable`”的重复开销

因此它的原则是：

- 公开入口仍然在 `fafafa.core.simd`
- metadata 走 POD struct + 独立字符串查询
- data-plane 走 **绑定后直调**

## 现在提供了什么

当前可用的 public ABI wrapper 入口：

- `GetSimdAbiVersionMajor`
- `GetSimdAbiVersionMinor`
- `GetSimdAbiSignature`
- `TryGetSimdBackendPodInfo`
- `GetSimdBackendNamePtr`
- `GetSimdBackendDescriptionPtr`
- `GetSimdPublicApi`

对应 POD 类型：

- `TFafafaSimdBackendPodInfo`
- `TFafafaSimdPublicApi`

当前 ABI 版本：`1.3`（Major=`1`，Minor=`3`）。

## 后端元数据

`TFafafaSimdBackendPodInfo` 只保留 POD 字段：

- `StructSize`
- `BackendId`
- `CapabilityBits`
- `Flags`
- `Priority`

这里的 `Flags` 反映 4 层 backend 状态：

- `supported_on_cpu`
- `registered`
- `dispatchable`
- `active`

以及一层成熟度标志：

- `experimental`

字符串名称/描述不放进 struct，而是通过：

- `GetSimdBackendNamePtr`
- `GetSimdBackendDescriptionPtr`

单独查询。

## Public API Table

`GetSimdPublicApi` 返回的是一张新的 public API table，不是当前内部 `TSimdDispatchTable`。

当前已绑定这些高 ROI façade：

- `MemEqual`
- `MemFindByte`
- `MemDiffRange`
- `SumBytes`
- `CountByte`
- `BitsetPopCount`
- `Utf8Validate`
- `AsciiIEqual`
- `BytesIndexOf`
- `MemCopy`
- `MemSet`
- `ToLowerAscii`
- `ToUpperAscii`
- `MemReverse`
- `MinMaxBytes`

这些函数指针使用 `cdecl`，适合外部 C ABI 调用。

## 性能语义

这张表的核心语义是：

- 初始化/切换后端时，内部通过 dispatch hook 重绑
- 调用方拿到表后可以缓存
- 正常 data-plane 调用直接走已绑定函数指针

也就是说，**不会在每次外部调用时重复查内部 dispatch table**。

只有极少数兜底路径，才会回读当前 dispatch table。

### 热点路径建议

推荐模式只有一个：

```pascal
var
  LApi: PFafafaSimdPublicApi;
begin
  LApi := GetSimdPublicApi;
  while ... do
    LApi^.MemEqual(...);
end;
```

不要把下面这种写法当成热点路径标准范式：

```pascal
while ... do
  GetSimdPublicApi^.MemEqual(...);
```

它是可用的，但不是推荐的 hot-loop 风格。

如果你想看当前仓库里对这件事的直接 benchmark，可以跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke
```

或：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --bench-only
```

其中会输出这些 public ABI 热点对照行：

- `HotMemEqPubCache`
- `HotMemEqPubGet`
- `HotMemEqDispGet`
- `HotSumPubCache`
- `HotSumPubGet`
- `HotSumDispGet`

它们用 32-byte 小负载对比：

- façade 调用
- 缓存后的 public API table 直调
- 循环内重复 `GetSimdPublicApi`
- 循环内重复 `GetDispatchTable`

目的不是追求某个固定倍数，而是持续守住“缓存 table 后直调”这条使用范式。

当前 `perf-smoke` 也已经把这件事纳入自动检查：

- `PubCache` 不能明显慢于 `PubGet`
- `PubGet` 必须明显快于 `DispGet`

也就是说，public ABI 热点路径现在不只是靠人工看 benchmark。

## 使用建议

### Pascal 侧

```pascal
var
  LApi: PFafafaSimdPublicApi;
  LHi, LLo: UInt64;
begin
  LApi := GetSimdPublicApi;
  GetSimdAbiSignature(LHi, LLo);

  if Assigned(LApi) and Assigned(LApi^.MemEqual) then
    if LApi^.MemEqual(@Buf1[0], @Buf2[0], Length(Buf1)) then
      WriteLn('equal');
end;
```

### C ABI smoke

仓库内已有最小 external smoke：

```bash
bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh test
```

它会完成：

- 构建 shared library
- 校验导出符号（`readelf --wide --dyn-syms`）
- 通过 `dlopen + dlsym` 获取 public API table
- 对高 ROI façade 做最小 parity smoke

如果你只想先验证导出符号，不跑 C harness：

```bash
bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh validate-exports
```

Windows 侧已有对等入口：

```bat
tests\fafafa.core.simd.publicabi\BuildOrTest.bat validate-exports
tests\fafafa.core.simd.publicabi\BuildOrTest.bat test
```

Windows smoke 通过 `publicabi_smoke.ps1` 完成：

- 校验 `fafafa_simd_*` 导出符号
- 调用 ABI version / signature / backend query
- 获取 public API table
- 执行最小 data-plane parity smoke

### Machine-readable contract guard

除了 external smoke，仓库内现在还有一条 **machine-readable public ABI signature/layout checker**：

```bash
python3 tests/fafafa.core.simd/check_public_abi_signature.py --summary-line
```

它会守住这些基线：

- `TSimdBackend` / `TSimdCapability` 的枚举顺序
- `TFafafaSimdBackendPodInfo` / `TFafafaSimdPublicApi` 的声明与字段顺序
- public ABI getter / export alias 声明
- ABI flag / version / signature 常量
- `tests/fafafa.core.simd.publicabi/publicabi_smoke.h` 的 consumer-side struct/function typedef

也就是说，当前 public ABI 不再只靠 smoke 才能发现漂移。

主模块日常门禁里也已经带上这条验证：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

其中会自动执行：

- `publicabi-signature`
- `publicabi-smoke`

## 当前边界

当前 **没有**做的事情：

- 不公开 `TSimdDispatchTable`
- 不公开 `TVec*` 按值 ABI
- 不把 Pascal managed string 带进 public ABI struct

如果未来要继续扩展，优先顺序应是：

1. 扩更多 pointer+len façade
2. 扩大 machine-readable contract 覆盖面（例如更多外部 consumer）
3. 再评估是否值得引入 vector ABI
