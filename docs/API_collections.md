# Collections API 索引（IVec / IDeque / IArray）

> See also: 示例总表（TVec/TVecDeque）：docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）


面向使用者的集合子系统概览与快速参考。强调接口优先、可插拔增长策略与显式分配器。

## 模块与命名
- 单元：src/fafafa.core.collections.*.pas
- 主要实现：
  - TVec<T>（动态数组/向量）
  - TVecDeque<T>（双端队列）
  - TArray<T>（固定长度缓冲，面向复制/IO）
- Facade/工厂：当启用集合门面时，提供 Make* 工厂返回接口类型

## 接口与工厂
- IVec<T> / IDeque<T> / IArray<T>：统一的只读/可变操作集合
- 工厂（选）：
  - MakeVec<T>(capacity=0; allocator=nil; growStrategy=nil): IVec<T>
  - MakeVecDeque<T>(capacity=0; allocator=nil; growStrategy=nil): IDeque<T>
  - MakeArr<T>(...): IArray<T>

说明：allocator/growStrategy 可为 nil，表示使用默认分配器与默认增长策略。

提示：若直接使用实现类构造器，allocator 传 nil 也会自动回退到 GetRtlAllocator()。


### IArray<T> 的 Ensure 语义（重要）
- IArray/TArray 的 Ensure(aCount) 语义为：确保“元素数量（Count）”至少为 aCount；因此会改变 Count。
- 注意：这不同于常见的 EnsureCapacity（确保容量）。Arr 并不暴露容量概念，主要用于定长/显式 Resize 的复制与 IO 场景。

## Allocator（显式分配器）
- 统一通过 TAllocator 注入；默认使用 RTL 分配器
- 在容器和元素管理器间透传，支持跨平台/可替换的内存策略

## GrowthStrategy（容量增长策略）
- 预设策略：
  - PowerOfTwo（默认）、Doubling、Factor(f)、GoldenRatio、Fixed(k)、Exact
  - AlignedWrapperStrategy：对任意策略结果做 2 的幂对齐
- 关键设计要点：
  - GetGrowStrategyI 返回“弱包装视图”：仅用于以 IGrowthStrategy 暴露当前策略；不改变底层 TGrowthStrategy 生命周期/引用计数，避免悬垂/双重释放/AV 风险
  - 下界与委派：TGrowthStrategy.GetGrowSize 统一委派至具体策略 DoGetGrowSize，并在基类保证 Result >= aRequiredSize；因此自定义策略在“首轮 Reserve”即可应用下界
  - TVecDeque 特别说明：即使注入任意策略，最终容量仍统一归一到 2 的幂（位掩码优化恒成立）；测试见 tests/fafafa.core.collections.vecdeque/test_strategy_pow2_rounding.pas

## TVec<T> 常用 API（节选）
- 容量：
  - Reserve(n) / TryReserve(n) / ReserveExact(n)
  - Shrink() / ShrinkTo(minCap) / ShrinkToFitExact()
  - EnsureCapacity(n)
- 元素：
  - Add/Insert/Remove/RemoveSwap
  - Get/Put、GetPtr/PeekRange
  - Write/WriteExact/OverWrite/Read（数组/指针/集合多态）
- 查找与算法（与 IArray<T> 协调）：Find/Contains/CountOf/BinarySearch/Sort/ForEach

## 快速示例（TVec + 自定义接口策略）
```pascal
{$CODEPAGE UTF8}
uses
  fafafa.core.collections.vec, fafafa.core.collections.base;

type
  // 一个简单的接口策略：在 required 基础上增加下界 +7
  TMyGrowI = class(TInterfacedObject, IGrowthStrategy)
  public
    function GetGrowSize(aCur, aReq: SizeUInt): SizeUInt; inline;
  end;

function TMyGrowI.GetGrowSize(aCur, aReq: SizeUInt): SizeUInt;
begin
  Result := aReq + 7;
end;

var V: specialize TVec<Integer>;
begin
  V := specialize TVec<Integer>.Create;
  try
    V.SetGrowStrategyI(TMyGrowI.Create);
    V.Reserve(10);
    // 首轮扩张满足下界：Capacity >= 17
  finally
    V.Free;
  end;
end.
```

## 选择策略的小贴士
- 通用：PowerOfTwo / Doubling，摊销 O(1) append
- 控内存：Factor(1.5)、GoldenRatio；需要精确控制时使用 Exact
- 批量 IO：AlignedWrapperStrategy 配合对齐友好的缓冲区

## 参考与深入
- 模块说明：docs/fafafa.core.collections.vec.md
- 系统概览：docs/fafafa.core.collections.md（含“TVec 接口与增长策略要点（重要）”）
- 有序 Map：TRBTreeMap<K,V>
  - 常用 API：docs/partials/collections.orderedmap.apis.md
  - Keys/Values 视图：docs/partials/collections.orderedmap.keys_values.md
  - 区间迭代 IterateRange：启动 O(log n)，步进摊销 O(1)

- Best Practices：docs/partials/collections.best_practices.md（策略组合与实用建议）
  - 示例：Samples（性能演示）：samples/orderedmap_perf_demo.pas 与 samples/Build_perf_demo.bat

- 源码：
  - TVec：src/fafafa.core.collections.vec.pas
  - 策略：src/fafafa.core.collections.base.pas
- 测试：tests/fafafa.core.collections.vec/
  - 回归测试示例：Test_vec_growstrategy_interface_regression.pas（验证接口策略首轮下界）

