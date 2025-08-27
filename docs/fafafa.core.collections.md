# fafafa.core.collections

## 快速导航
- Collections API 索引：docs/API_collections.md
- TVec 模块文档：docs/fafafa.core.collections.vec.md


> See also: 示例总表（TVec/TVecDeque）：docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）


> Cross-platform, interface-first collection façade for FreePascal. Design aligns with modern libraries (Rust Vec/VecDeque, Go slices/maps idioms, Java Collections/Deque), with explicit Allocator and GrowthStrategy.

## Purpose
- Provide consistent, interface-oriented collection APIs for framework users
- Hide implementation classes behind factories (Make*) to enable replacement and A/B testing
- Offer explicit control of memory (Allocator) and capacity growth (GrowthStrategy)

## Design Principles
- Interface-first: user code depends on IVec<T>, IDeque<T>, IArray<T>, IForwardList<T>, IList<T>, IQueue<T>, IStack<T>
- Factories return interfaces; implementations are internal (TVec<T>, TVecDeque<T>, TForwardList<T>, TList<T>...)
- Cross-platform, no locale/console dependencies (library units avoid Chinese output; tests/examples add {$CODEPAGE UTF8})
- Single macro config: src/fafafa.core.settings.inc
- Favor predictable semantics inspired by:
  - Rust: reserve/reserve_exact, shrink/shrink_to_fit, VecDeque O(1) ends
  - Go: len/cap separation, simple growth model
  - Java: interface stability, interchangeable implementations

## Public API (selected)
- MakeVec<T>(capacity=0; allocator=nil; growStrategy=nil): IVec<T>
- MakeVecDeque<T>(capacity=0; allocator=nil; growStrategy=nil): IDeque<T>
- MakeArr<T>(...): IArray<T> (overloads: empty, from array, from pointer+count, from collection)
- Facade (enabled by FAFAFA_COLLECTIONS_FACADE):
  - MakeForwardList<T>(allocator or source overloads): IForwardList<T>
  - MakeList<T>(allocator or source overloads): IList<T>
  - MakeDeque/MakeQueue/MakeStack (source overloads + capacity-based overloads)

## Capacity & Growth
- Reserve(n): ensure capacity for Count + n (may over-allocate per strategy)
- ReserveExact(n): try to allocate exactly Count + n (may align up internally)
- Ensure(n): in Vec, increases Count to at least n (legacy behavior, covered by tests); in Array, Ensure resizes to n (Array is fixed-length buffer)
- EnsureCapacity(n): Vec-only helper, only grows capacity (does not change Count)
- Shrink(): reduce capacity toward Count; ShrinkTo(minCap): set capacity >= minCap
- GrowthStrategy presets: TDoublingGrowStrategy, TFixedGrowStrategy, TFactorGrowStrategy, TPowerOfTwoGrowStrategy, TGoldenRatioGrowStrategy, TAlignedWrapperStrategy

## Growth Strategy Quick Reference

- PowerOfTwo (default): capacity grows to the next power-of-two >= required; great for bitmasking/ring buffers/CPU-friendly prefetch.
- Doubling: capacity *= 2; classical amortized O(1) appends; may waste more memory in large ranges.
- Factor(f): capacity *= f (e.g., 1.5 like Java ArrayList); balance copies vs. waste.
- GoldenRatio: capacity *= 1.618; good balance for frequent growth.
- Fixed(k): capacity += k; predictable footprint when growth happens in fixed batches.
- Exact: capacity grows exactly to required; minimal waste but may allocate frequently; use when allocation pattern is externally controlled.
- AlignedWrapper(strategy, align): wraps any strategy and rounds up capacity to an alignment (power-of-two); improves cacheline friendliness and SIMD prefetching.



## Try* APIs（非异常变体）

- TArray<T> 的 Try*：见 docs/partials/collections.try_apis.md
- TCollection 的 Try*（LoadFrom/Append 指针与集合重载）：见 docs/partials/collections.try_apis.collection.md

要点：
- Try* 返回 Boolean；错误作为值返回，不抛异常
- Append/LoadFrom 保持原有抛异常的语义不变
- 重叠/不兼容/溢出/内存失败 → Try* 返回 False；指针版 count=0 → TryLoadFrom 清空并 True、TryAppend 直接 True

### TVec 接口与增长策略要点（重要）
- GetGrowStrategyI 返回“弱包装视图”：仅用于以 IGrowthStrategy 暴露当前策略；不会改变底层 TGrowthStrategy 的生命周期/引用计数，避免悬垂/双重释放/AV 风险；调用方无需持有所有权
- 下界与委派：TGrowthStrategy.GetGrowSize 统一委派至具体策略 DoGetGrowSize，并在基类保证 Result >= aRequiredSize；因此自定义策略在“首轮 Reserve”即可应用下界（例如 first Reserve(10) 时满足 >= 17 的策略）

Notes
- Strategies are interchangeable; prefer PowerOfTwo for general purpose and deque-like structures.
- You can SetGrowStrategy(nil) to restore default (PowerOfTwo).
- Best Practices：docs/partials/collections.best_practices.md（策略组合、对齐与归一、测试建议）

## Minimal Examples

Vec (ReserveExact, ShrinkTo)

- ReserveExact grows to exactly Count + n (subject to minimal internal alignment); ShrinkTo reduces capacity to at least the given bound.

VecDeque (PushFront/Back, make_contiguous)

- PushFront/Back wrap around; make_contiguous ensures a linear slice when needed.

Arr (MakeArr from empty/array-of)

- MakeArr<T> can create an empty fixed-length buffer or from an existing array.

示例（UTF-8）：

```pascal
{$CODEPAGE UTF8}
program arr_quickstart;
uses
  fafafa.core.collections, fafafa.core.collections.arr, fafafa.core.collections.base;

var
  A: specialize IArray<Integer>;
  Src: array[0..3] of Integer = (1,2,3,4);
  Buf: specialize TGenericArray<Integer>;
begin
  // 空数组（默认分配器）
  A := specialize MakeArr<Integer>();

  // 从静态数组构造（复制）
  A := specialize MakeArr<Integer>(Src);

  // 基本操作
  A.Put(0, 42);
  if A.Get(0) = 42 then ;
  A.OverWrite(1, Src, Length(Src));
  A.Reverse(0, 4);
  A.Read(0, Buf, 4); // 读到动态数组
end.
```

## Allocator
- All factories accept TAllocator; default is RTL allocator
- Implementations propagate allocator to internal structures and element managers

## Examples (outline)
- Vec: push/reserve/shrink, custom growth strategy
- Vec.Resize initializes newly grown slots; Vec.Ensure increases Count (legacy contract)
- VecDeque: push/pop front/back, wrap-around correctness
- ForwardList: push_front/pop_front, splice/erase_after algorithms


## OrderedMap 概览（TRBTreeMap<K,V>)
- 有序：由 key 比较器决定顺序（可大小写不敏感等）
- 迭代：提供 Keys()/Values() 投影视图，支持正/反向遍历
- 区间：IterateRange(L,R, InclusiveRight) 支持 [L,R) 与 [L,R]
- 复杂度：启动 O(log n)，单步均摊 O(1)
- 详细与示例：docs/partials/collections.orderedmap.keys_values.md
- 分页/窗口遍历：见 docs/partials/collections.orderedmap.apis.md 的“范围分页/窗口遍历示例”，并可直接运行 samples\Build_range_pagination.bat

- 分页策略建议：见 docs/partials/collections.orderedmap.apis.md → “策略选择建议（UpperBoundKey vs lastKey + #1）”



示例：

```pascal
var M: specialize TRBTreeMap<string,Integer>;
    KI: specialize TIter<string>;
    It: TPtrIter;
begin
  M := specialize TRBTreeMap<string,Integer>.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('c',3);

    // Keys 视图迭代（升序）
    KI := M.Keys;
    while KI.MoveNext do ; // 正向读
    while KI.MovePrev do ; // 反向读

    // 区间 [b, c]
    It := M.IterateRange('b','c', True);
    while It.MoveNext do ;
  finally
    M.Free;
  end;
end;
```

Example projects live in examples/fafafa.core.collections (WIP); see BuildOrRun scripts for Debug/Release.

## Tests
- fpcunit tests under tests/fafafa.core.collections/
- One-click scripts: BuildOrTest.bat/.sh (Debug, leak check on)
- Tests cover factories, capacity semantics (Reserve/Exact/Shrink), allocator passthrough

## Roadmap
- Add GrowthStrategy curve tests (PowerOfTwo/Factor/GoldenRatio)
- Add edge-case tests (0/1/large) for reserve/shrink
- Investigate minor leak traces in ForwardList construction/destruction

## Dependency and configuration
- Uses core units: fafafa.core.base, math, mem.allocator, collections.*
- Only settings file: src/fafafa.core.settings.inc

## Notes
- Library units avoid Chinese text output; tests/examples add {$CODEPAGE UTF8}
- TArray.GetMemory returns nil for empty container; users should check Count > 0 before dereferencing
- Keep generics specialization bloat under control with macros (FAFAFA_CORE_TYPE_ALIASES) as needed

