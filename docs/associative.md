# 关联式容器实现路线图 (associative.md)

本文档规划了为 `fafafa.collections` 库实现一套完整的高性能关联式容器（键值对 Map 和集合 Set）的详细步骤。

---

## 阶段一: 哈希表 (Hash-Table) 容器

*目标: 实现基于哈希表的高性能 `O(1)` 平均时间复杂度的查找、插入和删除。*

- [ ] **1.1. 设计并实现 `THashMap<TKey, TValue>`**
    - [ ] **1.1.1. 核心设计决策**:
        - [ ] **冲突解决策略**: 详细评估并选择一种策略。**开放地址法 (Open Addressing)** 因其更好的缓存局部性通常是首选，但需要处理删除标记；**链地址法 (Separate Chaining)** 实现更直接。需作出权衡并记录原因。
        - [ ] **哈希函数**: 依赖外部注入的 `IEqualityComparer<TKey>` 来获取哈希码，不内置任何特定的哈希算法。
    - [ ] **1.1.2. 实现动态扩容 (Rehashing)**:
        - [ ] 定义默认的**负载因子 (Load Factor)**，例如 `0.75`。
        - [ ] 当元素数量超过 `Capacity * LoadFactor` 时，自动触发 Rehashing 过程（创建一个更大的内部数组并重新插入所有元素）。
    - [ ] **1.1.3. 实现核心 API**:
        - [ ] `Add(const aKey: TKey; const aValue: TValue)`
        - [ ] `Remove(const aKey: TKey): Boolean`
        - [ ] `ContainsKey(const aKey: TKey): Boolean`
        - [ ] `TryGetValue(const aKey: TKey; out aValue: TValue): Boolean`
        - [ ] `property Items[const aKey: TKey]: TValue read GetValue write SetValue;` (Default indexed property)

- [ ] **1.2. 设计并实现 `THashSet<T>`**
    - [ ] **复用 `THashMap`**: 将 `THashSet<T>` 设计为 `THashMap<T, Byte>` 的一个轻量级包装。这能最大化地复用代码。
    - [ ] **实现核心 API**: `Add`, `Remove`, `Contains`。

- [ ] **1.3. 迭代器支持**
    - [ ] 为 `THashMap` 和 `THashSet` 实现符合 `iter.md` 规范的迭代器。
    - [ ] 迭代器将遍历键值对 (`TPair<TKey, TValue>`) 或键 (`TKey`)。

- [ ] **1.4. 单元测试**
    - [ ] 创建 `testcase_hashmap.pas` 和 `testcase_hashset.pas`。
    - [ ] 测试基本操作、哈希冲突、Rehashing、边界情况（空、单元素）和迭代器。

---

## 阶段二: 有序树 (Tree-based) 容器

*目标: 实现基于自平衡二叉搜索树的 `O(log n)` 时间复杂度的有序存储和查找。*

- [ ] **2.1. 设计并实现 `TTreeMap<TKey, TValue>`**
    - [ ] **2.1.1. 核心设计决策**:
        - [ ] **树类型选择**: 评估并选择一种自平衡树。**红黑树 (Red-Black Tree)** 是工业标准，实现相对复杂但性能稳定。
    - [ ] **2.1.2. 依赖 `IComparer<TKey>`**:
        - [ ] 所有比较操作都必须通过外部注入的比较器接口进行，如果未提供，则使用 `TComparer<TKey>.Default`。
    - [ ] **2.1.3. 实现核心 API**:
        - [ ] `Add`, `Remove`, `ContainsKey`, `TryGetValue`。
        - [ ] `Min: TPair<TKey, TValue>`, `Max: TPair<TKey, TValue>` (获取最小/最大键值对)。

- [ ] **2.2. 设计并实现 `TTreeSet<T>`**
    - [ ] **复用 `TTreeMap`**: 将 `TTreeSet<T>` 设计为 `TTreeMap<T, Byte>` 的包装。

- [ ] **2.3. 迭代器支持**
    - [ ] 实现中序遍历 (In-order Traversal) 的迭代器，以保证遍历结果是有序的。

- [ ] **2.4. 单元测试**
    - [ ] 创建 `testcase_treemap.pas` 和 `testcase_treeset.pas`。
    - [ ] 测试基本操作、树的平衡与旋转、有序性、边界情况和迭代器。