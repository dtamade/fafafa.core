# fafafa.core.collections - 模块完善计划

**日期**: 2025-10-27  
**目标**: 让 fafafa.core.collections 模块达到完美状态，补全缺失容器类型

---

## 📊 现状分析

### ✅ 已有容器（生产就绪 A/B+ 级）

| 容器类型 | 实现状态 | 测试覆盖 | 集成状态 | 备注 |
|---------|---------|---------|---------|------|
| **Vec<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeVec | 动态数组，O(1)尾部操作 |
| **VecDeque<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeVecDeque | 环形缓冲，O(1)两端操作 |
| **List<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeList | 双向链表 |
| **ForwardList<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeForwardList | 单向链表 |
| **Deque<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeDeque | Deque接口（VecDeque实现） |
| **Queue<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeQueue | FIFO队列 |
| **Stack<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeStack | LIFO栈 |
| **Array<T>** | ✅ 完整 | ✅ 完整 | ✅ MakeArr | 固定长度数组 |
| **HashMap<K,V>** | ✅ 完整 | ✅ 完整 | ✅ MakeHashMap | 开放寻址哈希表 |
| **HashSet<K>** | ✅ 完整 | ✅ 完整 | ✅ MakeHashSet | 哈希集合 |
| **TreeMap<K,V>** | ✅ 完整 | ✅ 完整 | ✅ MakeTreeMap | 红黑树Map |
| **OrderedMap<K,V>** | ✅ 完整 | ✅ 完整 | ❌ 未导出 | 红黑树实现 |
| **OrderedSet<T>** | ✅ 完整 | ✅ 完整 | ❌ 未导出 | 红黑树实现 |
| **LruCache<K,V>** | ✅ 完整 | ✅ 完整 | ✅ MakeLruCache | LRU缓存 |

### ⚠️ 部分完成（需完善）

| 容器类型 | 实现状态 | 问题 | 优先级 |
|---------|---------|------|--------|
| **PriorityQueue<T>** | ⚠️ 90% | 未集成到主模块，无测试 | 🔴 P0 |
| **TreeSet<T>** | ⚠️ 85% | RB树实现存在(set.rb.pas)，但未集成 | 🔴 P0 |

### ❌ 缺失容器（需实现）

| 容器类型 | 重要性 | 实现难度 | 优先级 | 备注 |
|---------|--------|---------|--------|------|
| **LinkedHashMap<K,V>** | 🔵 高 | 中等 | 🟡 P1 | 保持插入顺序的HashMap |
| **BitSet** | 🔵 高 | 简单 | 🟡 P1 | 高效位集合，常用于标记/过滤 |
| **MultiMap<K,V>** | 🟢 中 | 中等 | 🟢 P2 | 一键多值，可基于Map<K,Vec<V>> |
| **MultiSet<T>** | 🟢 中 | 中等 | 🟢 P2 | 可重复集合，可基于Map<T,Count> |
| **SkipList<K,V>** | 🟡 低 | 中等 | 🟣 P3 | 概率平衡，并发友好 |

---

## 🎯 十步完善计划（TDD驱动）

### 阶段一：补全核心缺失容器（P0）

#### **Step 1: TreeSet<T> 完善与集成** ✅ 预期1天

**当前状态**:
- `fafafa.core.collections.set.rb.pas` 存在 TRBTreeSet<T> 实现
- 已有完整红黑树逻辑：插入、删除、查找、上下界、遍历
- 未集成到 `fafafa.core.collections.pas`
- 无单元测试

**TDD流程**:
```pascal
// 1. 红：先写测试（最简单场景）
procedure Test_TreeSet_Insert_Contains_Single;
begin
  var S := specialize MakeTreeSet<Integer>;
  AssertTrue(S.Insert(42));
  AssertTrue(S.ContainsKey(42));
end;

// 2. 绿：取消注释treeset，集成到collections.pas
// - 在collections.pas的uses中添加 fafafa.core.collections.set.rb
// - 实现 MakeTreeSet<T> 工厂函数
// - 运行测试，应通过

// 3. 重构：添加更多测试场景
procedure Test_TreeSet_Insert_Duplicate_ReturnsFalse;
procedure Test_TreeSet_OrderedIteration_Ascending;
procedure Test_TreeSet_LowerBound_UpperBound;
procedure Test_TreeSet_Clear_RemovesAll;
```

**交付物**:
- ✅ `fafafa.core.collections.set.rb.pas` 集成到主模块
- ✅ `MakeTreeSet<T>` 工厂函数
- ✅ 完整测试套件（`tests/fafafa.core.collections.treeSet/`）
- ✅ 文档更新

---

#### **Step 2: PriorityQueue<T> 完善与集成** ✅ 预期1天

**当前状态**:
- `fafafa.core.collections.priorityqueue.pas` 存在完整实现
- 基于二叉堆，O(log n) 插入/删除
- 未集成到主模块，无测试

**TDD流程**:
```pascal
// 1. 红：先写测试
procedure Test_PriorityQueue_Enqueue_Dequeue_MinFirst;
var
  PQ: specialize TPriorityQueue<Integer>;
  function IntCompare(const A, B: Integer): Integer;
  begin Result := A - B; end;
begin
  PQ.Initialize(@IntCompare);
  PQ.Enqueue(5); PQ.Enqueue(2); PQ.Enqueue(8);
  AssertEquals(2, PQ.Dequeue);
  AssertEquals(5, PQ.Dequeue);
  AssertEquals(8, PQ.Dequeue);
end;

// 2. 绿：集成到collections.pas
// - 添加 uses fafafa.core.collections.priorityqueue
// - 可选：包装为接口类型 IPriorityQueue<T>
// - 实现 MakePriorityQueue<T> 工厂

// 3. 重构：边界测试
procedure Test_PriorityQueue_Empty_DequeueThrows;
procedure Test_PriorityQueue_Peek_NoSideEffect;
procedure Test_PriorityQueue_Contains_LinearSearch;
```

**交付物**:
- ✅ `fafafa.core.collections.priorityqueue.pas` 集成
- ✅ `MakePriorityQueue<T>` 工厂
- ✅ 完整测试（`tests/fafafa.core.collections.priorityqueue/`）
- ✅ 接口抽象（可选）

---

### 阶段二：补全实用容器（P1）

#### **Step 3: LinkedHashMap<K,V> 实现** ✅ 预期2天

**设计要点**:
- 基于 HashMap + 双向链表
- 维护插入顺序，支持遍历
- O(1) 插入/查找/删除

**TDD流程**:
```pascal
// 1. 红：先定义接口和测试
type
  generic ILinkedHashMap<K,V> = interface(specialize IHashMap<K,V>)
    function First: TPair<K,V>;
    function Last: TPair<K,V>;
  end;

procedure Test_LinkedHashMap_InsertionOrder_Preserved;
var M: specialize ILinkedHashMap<String, Integer>;
begin
  M := specialize MakeLinkedHashMap<String, Integer>;
  M.Put('a', 1); M.Put('c', 3); M.Put('b', 2);
  var Keys: TArray<String>; // 遍历应返回 a, c, b
  for Key in M.Keys do Keys.Add(Key);
  AssertEquals('a', Keys[0]);
  AssertEquals('c', Keys[1]);
  AssertEquals('b', Keys[2]);
end;

// 2. 绿：实现 TLinkedHashMap<K,V>
// - 内部：HashMap + 双向链表节点
// - 插入时：HashMap存储+链表尾部插入
// - 删除时：HashMap删除+链表节点移除
// - 遍历：沿链表顺序

// 3. 重构：添加访问顺序模式（LRU语义）
```

**交付物**:
- ✅ `fafafa.core.collections.linkedhashmap.pas`
- ✅ `ILinkedHashMap<K,V>` 接口
- ✅ `TLinkedHashMap<K,V>` 实现
- ✅ `MakeLinkedHashMap<K,V>` 工厂
- ✅ 完整测试

---

#### **Step 4: BitSet 实现** ✅ 预期1.5天

**设计要点**:
- 动态扩展的位数组
- 支持位运算：And, Or, Xor, Not
- 常用操作：Set, Clear, Flip, Test

**TDD流程**:
```pascal
// 1. 红：先写测试
procedure Test_BitSet_SetClear_SingleBit;
var BS: TBitSet;
begin
  BS := MakeBitSet(64);
  BS.SetBit(10);
  AssertTrue(BS.Test(10));
  BS.ClearBit(10);
  AssertFalse(BS.Test(10));
end;

// 2. 绿：实现 TBitSet
// - 内部：dynamic array of UInt64（每个存64位）
// - SetBit(N): Bits[N div 64] := Bits[N div 64] or (1 shl (N mod 64))
// - Test(N): (Bits[N div 64] and (1 shl (N mod 64))) <> 0

// 3. 重构：位运算和迭代器
procedure Test_BitSet_And_Intersection;
procedure Test_BitSet_Or_Union;
procedure Test_BitSet_NextSetBit_Iterator;
```

**交付物**:
- ✅ `fafafa.core.collections.bitset.pas`
- ✅ `TBitSet` 类型
- ✅ `MakeBitSet` 工厂
- ✅ 完整测试

---

### 阶段三：高级容器评估（P2）

#### **Step 5: MultiMap<K,V> 评估与设计** ✅ 预期0.5天

**评估维度**:
1. **需求**：是否有实际场景需要一键多值？
2. **实现**：基于 `Map<K, Vec<V>>` 包装即可
3. **接口**：
   ```pascal
   generic IMultiMap<K,V> = interface
     procedure Put(const Key: K; const Value: V);
     function Get(const Key: K): specialize IVec<V>;
     function GetAll(const Key: K; out Values: TArray<V>): Boolean;
   end;
   ```

**决策**:
- 如果无紧急需求，**延后到 P3**
- 如果有需求，参照 Step 3 实现

---

#### **Step 6: MultiSet<T> 评估与设计** ✅ 预期0.5天

**评估维度**:
1. **需求**：是否需要计数集合（允许重复元素）？
2. **实现**：基于 `Map<T, Count>` 包装
3. **接口**:
   ```pascal
   generic IMultiSet<T> = interface
     procedure Add(const Value: T); // count++
     function Remove(const Value: T): Boolean; // count--, if 0 then remove
     function Count(const Value: T): SizeUInt;
   end;
   ```

**决策**:
- 如果无紧急需求，**延后到 P3**

---

### 阶段四：文档与示例（核心）

#### **Step 7: 统一API参考手册** ✅ 预期2天

**结构**:
```markdown
# fafafa.core.collections API Reference

## 1. 顺序容器（Sequential Containers）
### 1.1 Vec<T> - 动态数组
- **接口**: IVec<T>
- **实现**: TVec<T>
- **工厂**: MakeVec<T>
- **时间复杂度**: Push/Pop O(1)*, Get/Set O(1), Insert O(n)
- **使用场景**: 随机访问、尾部频繁操作
- **示例代码**:
  ```pascal
  var V := specialize MakeVec<Integer>(10);
  V.Push(42);
  WriteLn(V.Get(0)); // 42
  ```

### 1.2 VecDeque<T> - 双端队列
...（依此类推，覆盖所有14种容器）

## 2. 关联容器（Associative Containers）
### 2.1 HashMap<K,V>
### 2.2 TreeMap<K,V>
### 2.3 LinkedHashMap<K,V>

## 3. 集合容器（Set Containers）
### 3.1 HashSet<T>
### 3.2 TreeSet<T>
### 3.3 BitSet

## 4. 适配器容器（Container Adapters）
### 4.1 Queue<T>
### 4.2 Stack<T>
### 4.3 PriorityQueue<T>

## 5. 缓存容器（Caching Containers）
### 5.1 LruCache<K,V>

## 附录 A: 容器选择决策树
## 附录 B: 性能对比表
## 附录 C: 最佳实践
```

**交付物**:
- ✅ `docs/collections/api-reference.md`
- ✅ 每种容器的完整API文档
- ✅ 时间/空间复杂度标注
- ✅ 使用场景指导

---

#### **Step 8: 实用示例代码库** ✅ 预期1.5天

**目录结构**:
```
examples/collections/
├── 01_vec_basics.pas          # Vec基础操作
├── 02_hashmap_word_count.pas  # HashMap词频统计
├── 03_treemap_sorted_index.pas # TreeMap有序索引
├── 04_priorityqueue_tasks.pas  # PriorityQueue任务调度
├── 05_lrucache_simple.pas      # LruCache缓存示例
├── 06_bitset_flags.pas         # BitSet标记位
├── 07_performance_comparison.pas # 性能对比
└── README.md
```

**每个示例包含**:
1. 场景说明
2. 完整可编译代码
3. 输出结果
4. 性能注释

---

### 阶段五：质量保证（关键）

#### **Step 9: 生产就绪性验证** ✅ 预期1天

**验证清单**:
```bash
# 1. 运行所有容器测试
cd tests/fafafa.core.collections.vec && ./BuildOrTest.sh
cd tests/fafafa.core.collections.hashmap && ./BuildOrTest.sh
cd tests/fafafa.core.collections.treeset && ./BuildOrTest.sh
cd tests/fafafa.core.collections.priorityqueue && ./BuildOrTest.sh
cd tests/fafafa.core.collections.linkedhashmap && ./BuildOrTest.sh
cd tests/fafafa.core.collections.bitset && ./BuildOrTest.sh

# 2. 内存泄漏检测（heaptrc）
fpc -gh tests_vec.lpr && ./tests_vec

# 3. 性能基准测试
cd benchmark/collections && ./run_all_benchmarks.sh

# 4. 跨平台编译（Linux/Windows/macOS）
```

**更新报告**:
- 更新 `docs/collections-production-ready-report-v2.md`
- 所有容器达到 A/B+ 级

---

#### **Step 10: 统一工厂函数规范** ✅ 预期0.5天

**检查清单**:
- [ ] 所有容器都有 `MakeXxx<T>` 工厂函数
- [ ] 命名规范：`Make` + 容器类型名（驼峰）
- [ ] 参数顺序：`(aCapacity, aAllocator, aGrowStrategy/aCompare)`
- [ ] 返回接口类型（`IXxx<T>`），非类类型
- [ ] 可选参数默认值合理（Capacity=0, Allocator=nil）

**优化示例**:
```pascal
// ❌ 旧风格：返回类类型，参数不一致
function CreateVec<T>(Cap: Integer): TVec<T>;

// ✅ 新风格：返回接口，参数统一
generic function MakeVec<T>(
  aCapacity: SizeUInt = 0;
  aAllocator: IAllocator = nil;
  aGrowStrategy: TGrowthStrategy = nil
): specialize IVec<T>;
```

---

## 📈 预期成果

### 容器完整度
- **核心容器**: 14种 → 18种（+TreeSet, +PriorityQueue, +LinkedHashMap, +BitSet）
- **测试覆盖**: 95%+ 代码覆盖
- **文档完整度**: 100%（每种容器有文档+示例）

### 生产就绪性
| 模块 | 当前 | 目标 |
|------|------|------|
| collections | A级 | **A+级** |
| 测试覆盖 | 90% | 95%+ |
| 文档 | 80% | 100% |
| 示例 | 60% | 100% |

### 开发者体验
- ✅ 统一的工厂函数风格
- ✅ 完整的API文档
- ✅ 丰富的实用示例
- ✅ 清晰的容器选择指南

---

## 🎯 执行策略（TDD严格遵守）

### 核心原则（来自 WARP.md）
1. **红 → 绿 → 重构**：永远先写测试
2. **小步迭代**：每完成一个容器，立即提交
3. **持续验证**：每次修改后运行测试

### 每个容器的标准流程
```
1. 写第一个测试（最简单场景）→ 应该失败 ✓
2. 实现最小代码 → 测试通过 ✓
3. 提交（代码 + 测试）
4. 添加边界/异常测试 → 继续迭代
5. 完成后：更新文档 → 写示例 → 最终提交
```

### 防止上下文抖动
- **当前任务**: 专注完成一个容器（如TreeSet）
- **完成标准**: 实现 + 测试 + 文档 + 示例 + 提交
- **下一任务**: 再开始下一个容器（PriorityQueue）

---

## 📅 时间估算

| 阶段 | 任务 | 预估工时 | 优先级 |
|------|------|---------|--------|
| P0 | Step 1: TreeSet | 1天 | 🔴 立即 |
| P0 | Step 2: PriorityQueue | 1天 | 🔴 立即 |
| P1 | Step 3: LinkedHashMap | 2天 | 🟡 本周 |
| P1 | Step 4: BitSet | 1.5天 | 🟡 本周 |
| P2 | Step 5-6: MultiMap/Set评估 | 1天 | 🟢 下周 |
| 核心 | Step 7: API文档 | 2天 | 🔴 本周 |
| 核心 | Step 8: 示例代码 | 1.5天 | 🟡 本周 |
| 关键 | Step 9: 生产验证 | 1天 | 🔴 本周 |
| 关键 | Step 10: 工厂规范 | 0.5天 | 🟢 本周 |

**总计**: 约 11.5 天（P0+P1+核心任务）

---

## ✅ 检查清单（完成后确认）

### 代码质量
- [ ] 所有新容器有完整单元测试
- [ ] 测试覆盖正常、边界、异常场景
- [ ] 无内存泄漏（heaptrc验证）
- [ ] 编译无警告
- [ ] 代码遵循命名约定

### 文档
- [ ] 每种容器有API文档
- [ ] 每种容器有使用示例
- [ ] 更新主文档 `docs/fafafa.core.collections.md`
- [ ] 更新生产就绪报告

### 集成
- [ ] 所有容器集成到 `fafafa.core.collections.pas`
- [ ] 统一工厂函数风格
- [ ] 接口优先（返回 `IXxx<T>`）

---

## 🚀 开始执行

**下一步**: 立即开始 **Step 1: TreeSet<T> 完善与集成**

**命令**:
```bash
# 1. 创建测试目录
mkdir -p tests/fafafa.core.collections.treeSet

# 2. 先写第一个测试（红）
# 3. 取消注释treeset，集成到collections.pas（绿）
# 4. 运行测试 → 通过 ✓
# 5. 提交
```

---

**最后更新**: 2025-10-27  
**执行原则**: TDD优先，小步迭代，持续验证  
**目标**: 让 fafafa.core.collections 达到 **A+级完美状态** 🎯
