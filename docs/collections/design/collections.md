# fafafa.core.collections 集合模块设计蓝图（内部设计文档）

> 本文件位置：`docs/collections/design/collections.md`

> 快速导航
> - Collections API 索引：`../../API_collections.md`
> - TVec 模块文档：`../../fafafa.core.collections.vec.md`
> - 集合系统概览：`../../fafafa.core.collections.md`
> - 示例总表（TVec/TVecDeque）：`../../EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque）`
> - Best Practices（策略组合与对齐建议）：`../../partials/collections.best_practices.md`
> - 示例索引（一键脚本与示例清单）：`../../../examples/fafafa.core.collections/README.md`

本文档是 `fafafa.core.collections` 模块的统一设计蓝图，整合了该模块下的迭代器框架、通用算法以及未来可能包含的各种容器类型的设计规划。

---
---

# 迭代器框架实现路线图 (原 iter.md)

本文档规划了为 `fafafa.collections` 库实现一个双层、高性能、STL 风格迭代器框架的详细步骤。我们的目标是统一容器接口、提升代码复用性并兼容 FPC 的 `for..in` 循环。

---

## 阶段一: 核心框架定义与基础建设

*目标: 搭建迭代器系统的骨架，定义核心接口和概念。*

- [ ] **1.1. 创建新的单元 `fafafa.collections.iterator.pas`**
    - @remark: 该单元将作为所有迭代器相关接口和辅助类的中心。所有与迭代器相关的定义都应放在这里。

- [ ] **1.2. 定义核心的 `IIterable<TIterator, T>` 接口**
    - @desc: 这是所有可迭代容器需要实现的顶层接口，它承诺提供 `begin` 和 `end` 迭代器。
    - `specialize IIterable<TIterator, T> = interface(IInterface)`

- [ ] **1.3. (可选但推荐) 定义迭代器分类标签 (Iterator Category Tags)**
    - @desc: 借鉴 C++ STL，定义一组空的接口作为标签，用于在编译期确定迭代器的能力，从而支持算法重载和优化。
    - `IInputIteratorTag = interface`
    - `IForwardIteratorTag = interface(IInputIteratorTag)`
    - `IBidirectionalIteratorTag = interface(IForwardIteratorTag)`
    - `IRandomAccessIteratorTag = interface(IBidirectionalIteratorTag)`

---

## 阶段二: `TVec` 的迭代器实现 (概念验证)

*目标: 将迭代器框架应用到第一个具体容器 `TVec` 上，验证设计的可行性。*

- [ ] **2.1. 定义 `TVecIterator<T>` 记录 (Record)**
    - @desc: 创建一个高性能、基于 `record` 的值类型迭代器，用于遍历 `TVec`。
    - `specialize TVecIterator<T> = record`
    - **包含字段**: `FVec: TVec<T>` (所属容器), `FIndex: SizeUInt` (当前索引)。
    - **实现能力**: 它应属于**随机访问迭代器** (`IRandomAccessIteratorTag`)。

- [ ] **2.2. 实现 `TVecIterator<T>` 的核心方法**
    - [ ] `function MoveNext: Boolean;`
    - [ ] `function GetCurrent: T;` (或 `property Current: T;`)
    - [ ] `class operator Equal(a, b): Boolean;`
    - [ ] `class operator NotEqual(a, b): Boolean;`

- [ ] **2.3. 实现 `TVecIterator<T>` 的随机访问方法**
    - [ ] `class operator Add(a: TIterator; b: Integer): TIterator;` (前进 n)
    - [ ] `class operator Subtract(a: TIterator; b: Integer): TIterator;` (后退 n)
    - [ ] `class operator Subtract(a, b: TIterator): PtrInt;` (计算距离)

- [ ] **2.4. 改造 `TVec<T>` 以支持迭代器**
    - [ ] 让 `TVec<T>` 实现 `IIterable<TVecIterator<T>, T>` 接口。
    - [ ] 实现 `function begin: TVecIterator<T>;` (返回指向索引 0 的迭代器)。
    - [ ] 实现 `function end: TVecIterator<T>;` (返回指向 `FCount` 的“哨兵”迭代器)。

- [ ] **2.5. 编写 `TVecIterator` 的单元测试**
    - @desc: 在 `tests/testcase_vec.pas` 中添加新的测试用例。
    - **测试场景**: 空容器 (`begin` 应等于 `end`)、单元素容器、多元素容器、`MoveNext` 越界行为、迭代器比较。

---

## 阶段三: 兼容 FPC RTL 的 `for..in` 循环

*目标: 桥接我们自己的迭代器系统和 FPC 的 `IEnumerable<T>`，实现无缝的 `for..in` 支持。*

- [ ] **3.1. 创建通用的迭代器包装类 `TIteratorWrapper`**
    - @desc: 在 `fafafa.collections.iterator.pas` 中定义一个辅助类，该类实现了 FPC 的 `IEnumerator<T>` 接口，其内部持有一个我们自己的 `record` 迭代器。
    - `specialize TIteratorWrapper<TIterator, T> = class(TInterfacedObject, IEnumerator<T>)`

- [ ] **3.2. 让 `TVec<T>` 实现 `IEnumerable<T>`**
    - [ ] 在 `TVec<T>` 的接口列表中添加 `IEnumerable<T>`。
    - [ ] 实现 `function GetEnumerator: IEnumerator<T>;`，其内部创建并返回一个 `TIteratorWrapper` 实例。

- [ ] **3.3. 编写 `for..in` 的单元测试**
    - @desc: 添加一个测试，使用 `for..in` 语法遍历 `TVec`，并验证结果的正确性。

---

## 阶段四: 开发通用算法 (可选)

*目标: 展示迭代器框架的威力，编写一些能对任何可迭代容器工作的通用算法。*

- [ ] **4.1. 创建新的单元 `fafafa.collections.algorithms.pas`**

- [ ] **4.2. 实现 `Algorithms.Find<TIterator, T>`**
    - @desc: `function Find(aFirst, aLast: TIterator; const aValue: T): TIterator;`

- [ ] **4.3. 实现 `Algorithms.ForEach<TIterator, T>`**
    - @desc: `procedure ForEach(aFirst, aLast: TIterator; const aProc: TProc<T>);`

- [ ] **4.4. 为通用算法编写单元测试**
    - @desc: 使用 `TVec` 的迭代器来测试这些算法。

---

## 阶段五: 推广与未来展望

*目标: 将迭代器模式应用到未来的容器中。*

- [ ] **5.1. 为 `TLinkedList` (如果实现) 添加迭代器支持**
- [ ] **5.2. 为 `TTreeMap` (如果实现) 添加迭代器支持**

---
---

# 通用算法实现路线图 (原 algorithms.md)

本文档规划了 `fafafa.collections` 库的通用算法模块。所有算法都将基于 `iter.md` 中定义的迭代器接口进行设计，使其能够与任何符合规范的容器协同工作。

---

## 阶段一: 基础框架与非修改性算法

*目标: 建立算法单元，并实现第一批最常用的、不改变容器内容的算法。*

- [ ] **1.1. 创建 `fafafa.collections.algorithms.pas` 单元**

  - @remark: 所有通用算法都将作为该单元内的静态方法提供，例如 `TAlgorithms.Find(...)`。
- [ ] **1.2. 实现 `ForEach`**

  - `procedure ForEach<TIterator, T>(aFirst, aLast: TIterator; const aProc: TProc<T>);`
- [ ] **1.3. 实现 `Find` / `FindIf`**

  - `function Find<TIterator, T>(aFirst, aLast: TIterator; const aValue: T): TIterator;`
  - `function FindIf<TIterator>(aFirst, aLast: TIterator; const aPredicate: TPredicate<TIterator.TValue>): TIterator;`
- [ ] **1.4. 实现 `CountIf`**

  - `function CountIf<TIterator>(aFirst, aLast: TIterator; const aPredicate: TPredicate<TIterator.TValue>): SizeUInt;`
- [ ] **1.5. 实现 `Equal` / `Mismatch`**

  - `function Equal<TIter1, TIter2>(aFirst1, aLast1: TIter1; aFirst2: TIter2): Boolean;`
  - `function Mismatch<TIter1, TIter2>(aFirst1, aLast1: TIter1; aFirst2: TIter2): TPair<TIter1, TIter2>;`
- [ ] **1.6. 单元测试**

  - [ ] 创建 `testcase_algorithms.pas`。
  - [ ] 使用 `TVec` 的迭代器对上述所有算法进行充分测试。

---

## 阶段二: 修改性序列算法

*目标: 实现一组会修改容器内容的常用算法。*

- [ ] **2.1. 实现 `Copy` / `CopyIf`**

  - `function Copy<TInputIter, TOutputIter>(aFirst, aLast: TInputIter; aDest: TOutputIter): TOutputIter;`
  - `function CopyIf<TInputIter, TOutputIter>(...): TOutputIter;`
- [ ] **2.2. 实现 `Move`**

  - @remark: 实现一个向后移动 (`MoveBackward`) 版本以处理重叠范围。
  - `function Move<TInputIter, TOutputIter>(aFirst, aLast: TInputIter; aDest: TOutputIter): TOutputIter;`
- [ ] **2.3. 实现 `Transform`**

  - `function Transform<TInputIter, TOutputIter, TConverter>(aFirst, aLast: TInputIter; aDest: TOutputIter; const aConverter: TConverter): TOutputIter;`
- [ ] **2.4. 实现 `Fill` / `Generate`**

  - `procedure Fill<TForwardIter, T>(aFirst, aLast: TForwardIter; const aValue: T);`
  - `procedure Generate<TForwardIter, TGenerator>(aFirst, aLast: TForwardIter; const aGenerator: TGenerator);`
- [ ] **2.5. 实现 `Replace` / `ReplaceIf`**
- [ ] **2.6. 单元测试**

  - [ ] 扩展 `testcase_algorithms.pas`，覆盖所有修改性算法。

---

## 阶段三: 排序与分区算法

*目标: 提供强大且高效的排序功能。*

- [ ] **3.1. 实现 `Sort`**

  - @desc: 针对随机访问迭代器，实现一个高效的不稳定排序算法。**IntroSort** (内省排序) 是最佳选择，它是快速排序、堆排序和插入排序的混合体，能保证 `O(n log n)` 的最坏情况复杂度。
  - `procedure Sort<TRandomAccessIter>(aFirst, aLast: TRandomAccessIter); overload;`
  - `procedure Sort<TRandomAccessIter>(aFirst, aLast: TRandomAccessIter; const aComparer: IComparer<...>); overload;`
- [ ] **3.2. 实现 `StableSort` (稳定排序)**

  - @desc: 针对需要保持相等元素相对顺序的场景。通常使用归并排序 (`MergeSort`) 或其变体。
  - `procedure StableSort<TRandomAccessIter>(...);`
- [ ] **3.3. 实现 `BinarySearch` / `LowerBound` / `UpperBound`**

  - @desc: 为**已排序**的序列提供高效的 `O(log n)` 查找。
  - `function BinarySearch<TForwardIter, T>(...): Boolean;`
  - `function LowerBound<TForwardIter, T>(...): TForwardIter;`
- [ ] **3.4. 单元测试**

  - [ ] 扩展 `testcase_algorithms.pas`，详细测试排序的正确性、稳定性和二分查找的边界情况。
