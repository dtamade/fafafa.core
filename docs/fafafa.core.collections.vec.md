# fafafa.core.collections.vec

## 快速导航
> See also: 示例总表（TVec/TVecDeque）：docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）


- Collections API 索引：docs/API_collections.md
- 集合系统概览：docs/fafafa.core.collections.md


## 模块定位
- 动态数组（向量）实现：在 IArray<T> 之上提供可增长语义与更丰富的算法


## 设计要点
- 接口：实现 IVec<T> 与 IArray<T> 必要成员
- 容量管理：
  - 默认增长策略为 TFactorGrowStrategy(1.5)，在内存与重分配次数间取得平衡；需要位运算友好/对齐时，可使用 EnableAlignedGrowth 或显式配置 TPowerOfTwoGrowStrategy
  - 支持 TryReserve（失败不抛）、ReserveExact、ShrinkToFit
  - 允许通过 TGrowthStrategy/TPowerOfTwoGrowStrategy/TAlignedWrapperStrategy 注入与包装
  - 接口路径：GetGrowStrategyI 返回“弱包装视图”（不改变底层 TGrowthStrategy 生命周期/引用计数），避免类→接口转换带来的悬垂/双重释放/AV 风险；调用方无需持有其所有权
  - 下界与委派：TGrowthStrategy.GetGrowSize 统一委派至具体策略 DoGetGrowSize，并在基类保证 Result >= aRequiredSize；这确保自定义策略在“首轮扩张”也能应用下界

- 内存分配：TAllocator 注入，跨平台
- UnChecked 合同：批量操作与无检查路径由调用方保证边界

## 常用 API（摘要）
- Add/Insert/Remove/RemoveSwap
- Ensure/Reserve/TryReserve/ReserveExact/Shrink/ShrinkToFit
- Write/WriteExact/OverWrite/Read
- Find/Contains/CountOf/BinarySearch/Sort（与 IArray<T> 协调）

完整签名以源码为准（src/fafafa.core.collections.vec.pas）。

提示：最小示例与一键脚本：examples/fafafa.core.collections.vec/BuildOrTest_Examples.(bat|sh)

## 使用示例（UTF-8）
```pascal
{$CODEPAGE UTF8}
program vec_quickstart;
uses
  fafafa.core.collections.vec, fafafa.core.collections.base;

type
  TIntVec = specialize TVec<Integer>;
var
  V: TIntVec;
begin
  // 缺省增长策略：TFactorGrowStrategy(1.5)
  V := TIntVec.Create; // 也可传入 GetRtlAllocator
  try
    V.Push(1);
    V.Push(2);
    V.Insert(0, 0);

    // 预留容量（不抛异常）
    if not V.TryReserve(1024) then ; // 可根据返回值降级处理

    // 精确预留与收缩
    V.ReserveExact(2048);
    V.ShrinkToFit;
  finally
    V.Free;
  end;
end.
```

## 测试建议
- 容量语义：Reserve/TryReserve/ReserveExact 与 Shrink/ShrinkToFit 的边界（小/大/近满）
- 插入/删除：InsertElement/Remove/RemoveSwap 的正确性与复杂度热点
- 查找/排序/二分：在已排序/未排序数组上验证正确性
- UnChecked：Write/Copy/Swap/Reverse 等不做检查的性能路径

## 性能与实践
- 大量 append 场景使用 Reserve 预留，降低扩容次数
- 如需与 VecDeque 交替使用，注意二者接口一致性（有助共享算法）
- 对齐包装策略（TAlignedWrapperStrategy）在批量 I/O 热路径可能更有益

## 注意事项
- 所有测试均应打开 Debug 与 heaptrc；{$CODEPAGE UTF8}
- 禁止内联变量写法；所有宏从 src/fafafa.core.settings.inc 引入

## 参考
- 源码：src/fafafa.core.collections.vec.pas
- 增长策略：src/fafafa.core.collections.base.pas
- UnChecked 合同：docs/UnChecked_Methods_Summary.md
- Best Practices：docs/partials/collections.best_practices.md（策略组合与测试建议）

