# fafafa.core.collections.treeSet

## 模块定位
- 提供基于自平衡二叉搜索树（红黑树）的有序集合容器 TreeSet<T>
- 语义参考：C++ std::set / Java TreeSet / Rust BTreeSet（遍历升序、O(log n) 插入/查找）
- 实现现状：已有 `src/fafafa.core.collections.treeset.rb.pas`（TRBTreeSet<T> 原型，哨兵节点，插入/查找/上下界/遍历）

## 设计要点
- 接口优先（中期）：预留 IOrderedSet<T>/ITreeSet<T> 抽象；当前先以类直接使用，后续平滑迁移至接口工厂
- 比较器：复用 `TGenericCollection<T>` 的内部类型感知比较器（支持数值/字符串/指针等）；中期将开放外部比较器注入
- 内存：通过 `TAllocator` 注入；Clear 释放所有节点但不释放分配器
- 迭代：中序遍历，`Iter`/`GetEnumerator` 返回升序序列

## 公开 API（当前原型）
- 构造/析构：Create; Create(Allocator)
- 基础：GetCount; Clear; PtrIter; SerializeToArrayBuffer
- 集合：Insert(const Value: T): Boolean; ContainsKey(const Value: T): Boolean
- 有序：LowerBound(const Value: T; out OutValue: T): Boolean; UpperBound(...): Boolean

## 工厂与门面（计划）
- 门面单元：`src/fafafa.core.collections.pas` 已引入 treeset.rb；后续增加 `MakeTreeSet<T>` 工厂（返回 IOrderedSet/ITreeSet）

## 测试计划（本轮）
- 新建标准化测试工程：`tests/fafafa.core.collections.treeSet/`
  - TTestCase_TRBTreeSet：
    - Test_Create_Destroy
    - Test_Insert_Contains_Duplicate
    - Test_Ordered_Iteration
    - Test_LowerBound_UpperBound
    - Test_AppendUnChecked_Serialize
    - Test_Clear_Zero_Reverse_NoEffect

## 性能与边界
- 插入/查找 O(log n)；严格递增遍历
- Duplicate 不插入；返回 False；计数不变
- DoReverse 对有序集合为 no-op（遍历顺序由迭代器定义）

## 后续路线
- 抽象接口 IOrderedSet/ITreeSet，统一比较器注入
- TreeMap<TKey,TValue>（Set 基于 Map 封装）
- B-Tree 变体以提升缓存友好性

