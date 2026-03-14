# fafafa.core.simd Public ABI Stability

> 这页只回答一个问题：**public ABI wrapper 到底承诺什么，不承诺什么。**

## 当前承诺

当前 `fafafa.core.simd` 的 public ABI wrapper 承诺下面这些东西是稳定边界：

- `GetSimdAbiVersionMajor`
- `GetSimdAbiVersionMinor`
- `GetSimdAbiSignature`
- `TryGetSimdBackendPodInfo`
- `GetSimdBackendNamePtr`
- `GetSimdBackendDescriptionPtr`
- `GetSimdPublicApi`

以及对应的 POD 类型：

- `TFafafaSimdBackendPodInfo`
- `TFafafaSimdPublicApi`

当前 ABI 版本：`1.3`（Major=`1`，Minor=`3`）。

对外更具体地说，稳定的是：

- POD struct 的字段语义
- `cdecl` 调用约定
- `fafafa_simd_*` 导出符号名
- backend 状态四层语义
- 已进入 `TFafafaSimdPublicApi` 的那些 high-ROI façade 函数

当前 table 中已明确进入承诺面的 data-plane 函数包括：

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

## 当前不承诺

下面这些东西**不是** public ABI 承诺面：

- `TSimdDispatchTable`
- `TSimdBackendInfo`
- `TSimdBackendOps`
- backend.adapter / backend.iface 的内部组织
- Pascal managed string 的内存布局
- `TVec*` record 的按值 ABI

一句话：

**public ABI wrapper 是外部边界，内部 dispatch contract 不是。**

## backend 状态怎么理解

public ABI wrapper 继续沿用当前已经统一的四层语义：

- `supported_on_cpu`
- `registered`
- `dispatchable`
- `active`

这些语义在 `TFafafaSimdBackendPodInfo.Flags` 里表达。

调用方不应该把一个含糊的 “available” 当成总称。

## data-plane 语义

`GetSimdPublicApi` 返回的是一张**已绑定**的 public API table。

这里承诺的是：

- 调用方可以缓存这个 table
- table 中的函数指针是 `cdecl`
- 正常 data-plane 路径不会每次再去查内部 `TSimdDispatchTable`

也就是说，public wrapper 不是“再包一层重复分发”。

## refresh 语义

当前语义是：

- backend 变化后，内部通过 dispatch hook 重绑 public API table
- `GetSimdPublicApi` 返回的是当前最新绑定结果

调用方如果长时间缓存 table，应该把它理解成：

- **进程内稳定**
- **backend 切换后可刷新**

不要把当前实现理解成“拿一次就永远不会变”。

## 兼容性规则

如果未来继续扩展 public ABI wrapper，遵循下面几条规则：

1. **只追加，不破坏现有字段语义**
   - 现有字段一旦公开，就不要改含义

2. **优先通过 `StructSize` 扩展**
   - 新字段优先往 record 尾部追加
   - 调用方先看 `StructSize`

3. **只扩 high-ROI façade**
   - 优先 `pointer + len` 风格接口
   - 不急着把 vector-by-value 推进 public ABI

4. **签名变化必须显式更新**
   - 如果 public ABI 结构真的变了，就必须同步更新文档、smoke、header 和 machine-readable signature baseline

## 验证方式

当前至少有 4 层验证：

1. 主模块 gate

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

它会带上：

- `contract-signature`
- `publicabi-signature`
- `publicabi-smoke`

2. machine-readable public ABI signature/layout checker

```bash
python3 tests/fafafa.core.simd/check_public_abi_signature.py --summary-line
```

它会同时校验 Pascal public ABI 声明和 `publicabi_smoke.h` 的 consumer contract。

3. Linux external smoke

```bash
bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh test
```

4. Windows external smoke 入口

```bat
tests\fafafa.core.simd.publicabi\BuildOrTest.bat test
```

## 什么时候才考虑扩到 vector ABI

只有在下面三件事同时成立时，才值得把 vector ABI 拉进 public 边界：

- 有明确跨语言用户
- 有真实 workload 证明收益
- 有稳定的跨编译器/跨平台调用约定测试

在那之前，继续保持现在这条边界更稳。
