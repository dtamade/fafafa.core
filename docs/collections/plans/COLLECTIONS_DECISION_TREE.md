# Collections 容器选择决策树

**目的**: 帮助开发者快速选择最合适的容器类型  
**更新时间**: 2025-10-28  
**适用版本**: fafafa.core.collections v1.1+

---

## 🚦 快速决策流程

### 第一步：确定数据结构类型

```
你需要存储什么？
│
├─ 键值对（Key-Value）
│  └─→ 进入【映射类型决策】
│
├─ 单一值的序列
│  └─→ 进入【顺序容器决策】
│
├─ 去重的值集合
│  └─→ 进入【集合类型决策】
│
└─ 布尔标记/位操作
   └─→ 使用 BitSet
```

---

## 🗺️ 映射类型决策（Key-Value）

### 决策问题 1：需要保持顺序吗？

```
需要什么顺序？
│
├─ 不需要顺序 → HashMap（性能最优）
│  ✓ 最快的查找/插入（O(1)）
│  ✓ 适合大多数场景
│  ✓ 推荐用于：缓存、配置表、索引
│
├─ 需要键的排序（从小到大）→ TreeMap
│  ✓ 自动维护键的顺序
│  ✓ 支持范围查询（LowerBound, UpperBound）
│  ✓ 推荐用于：排行榜、有序数据、范围查询
│
└─ 需要插入顺序 → LinkedHashMap
   ✓ 保持元素插入的先后顺序
   ✓ 可实现 LRU 缓存
   ✓ 推荐用于：配置文件、命令历史、LRU缓存
```

### 决策问题 2：数据量级如何？

| 数据量 | 推荐容器 | 理由 |
|--------|----------|------|
| < 1,000 | HashMap/TreeMap/LinkedHashMap 都可以 | 性能差异不明显 |
| 1,000 - 100K | HashMap | 最快 |
| > 100K | TreeMap | 避免哈希冲突，稳定性能 |

### 决策问题 3：主要操作是什么？

| 主要操作 | 最佳选择 | 次佳选择 |
|----------|----------|----------|
| 频繁查找 | HashMap | LinkedHashMap |
| 频繁插入 | HashMap | LinkedHashMap |
| 频繁删除 | HashMap | TreeMap |
| 范围查询 | TreeMap | - |
| 按插入顺序遍历 | LinkedHashMap | - |
| 按键排序遍历 | TreeMap | - |

### 示例场景

**场景 1**: 用户会话管理（需要快速查找，无需顺序）
```pascal
// 推荐：HashMap
var LSessionMap := specialize MakeHashMap<string, TSessionInfo>();
```

**场景 2**: 排行榜系统（需要按分数排序）
```pascal
// 推荐：TreeMap
var LLeaderboard := specialize MakeTreeMap<Integer, string>();
```

**场景 3**: 配置文件（需要保持插入顺序）
```pascal
// 推荐：LinkedHashMap
var LConfig := specialize MakeLinkedHashMap<string, string>();
```

---

## 📝 顺序容器决策（单一值序列）

### 决策问题 1：主要操作位置在哪？

```
主要操作在哪里？
│
├─ 尾部追加/删除 → Vec
│  ✓ 最快的尾部操作（O(1)）
│  ✓ 支持高效的随机访问（O(1)）
│  ✓ 推荐用于：日志收集、栈结构、大部分列表场景
│
├─ 两端都操作 → VecDeque
│  ✓ 头部和尾部都是 O(1)
│  ✓ 支持队列和双端队列
│  ✓ 推荐用于：FIFO队列、滑动窗口、环形缓冲
│
└─ 中间频繁插入/删除 → List
   ✓ 中间插入/删除 O(1)（已知位置）
   ✓ 不支持高效随机访问
   ✓ 推荐用于：编辑器、链式结构、频繁插删
```

### 决策问题 2：需要随机访问吗？

```
需要通过索引快速访问元素？
│
├─ 需要（例如 data[100]）
│  └─→ Vec 或 VecDeque（O(1) 访问）
│
└─ 不需要
   └─→ List 或 ForwardList（节省内存）
```

### 决策问题 3：元素数量可预知吗？

| 情况 | 建议 |
|------|------|
| 已知大小 | Vec 预分配容量：`MakeVec<T>(knownSize)` |
| 动态增长 | VecDeque（两端操作）或 Vec（单端操作） |
| 小规模（< 100） | Vec（最简单） |

### 性能对比（100K 元素）

| 操作 | Vec | VecDeque | List |
|------|-----|----------|------|
| 尾部追加 | 1x | 1x | - |
| 头部插入 | 100x | 1x | 1x |
| 随机访问 | 1x | 1x | 100x |
| 中间插入 | 50x | 50x | 1x |

### 示例场景

**场景 1**: 日志收集系统（尾部追加为主）
```pascal
// 推荐：Vec
var LLogs := specialize MakeVec<string>();
LLogs.Append('Log entry');
```

**场景 2**: 任务队列（先进先出）
```pascal
// 推荐：VecDeque
var LQueue := specialize MakeVecDeque<TTask>();
LQueue.PushBack(task);
var LTask := LQueue.PopFront();
```

**场景 3**: 文本编辑器行管理（频繁插入删除）
```pascal
// 推荐：List
var LLines := specialize MakeList<string>();
```

---

## 🎯 集合类型决策（去重集合）

### 决策问题 1：需要有序吗？

```
需要元素排序？
│
├─ 不需要 → HashSet
│  ✓ 最快的查找/插入（O(1)）
│  ✓ 适合大多数去重场景
│  ✓ 推荐用于：ID去重、唯一性检查
│
└─ 需要 → TreeSet
   ✓ 自动排序
   ✓ 支持范围查询
   ✓ 推荐用于：有序去重、排序后遍历
```

### 决策问题 2：元素都是整数吗？

```
元素类型是整数且密集分布？
│
├─ 是，且范围不太大（< 1M）
│  └─→ BitSet（极致内存效率）
│     ✓ 1 bit/元素（相比 HashSet 节省 99%）
│     ✓ 位运算速度快
│     ✓ 推荐用于：权限位、布尔标记、ID集合
│
└─ 否
   └─→ HashSet 或 TreeSet
```

### 内存使用对比（10,000 个整数）

| 容器 | 内存占用 | 优势 |
|------|----------|------|
| BitSet | ~1.25 KB | 极致压缩 |
| HashSet<Integer> | ~160 KB | 通用性好 |
| TreeSet<Integer> | ~240 KB | 自动排序 |

**节省比例**: BitSet 相比 HashSet 节省 **99.2%** 内存！

### 示例场景

**场景 1**: 用户 ID 去重（无需顺序）
```pascal
// 推荐：HashSet
var LUserIDs := specialize MakeHashSet<Integer>();
```

**场景 2**: 用户权限位管理（整数位标记）
```pascal
// 推荐：BitSet
var LPermissions := MakeBitSet();
LPermissions.SetBit(READ_PERM);
LPermissions.SetBit(WRITE_PERM);
if LPermissions.Test(ADMIN_PERM) then ...
```

**场景 3**: 成绩排名（需要排序）
```pascal
// 推荐：TreeSet
var LScores := specialize MakeTreeSet<Integer>();
```

---

## 🔧 特殊容器决策

### PriorityQueue - 优先级队列

**使用时机**:
- 需要始终获取"最小"或"最大"元素
- 任务调度（按优先级处理）
- Dijkstra 算法、A* 寻路

**示例**:
```pascal
var LTaskQueue: specialize TPriorityQueue<TTask>;
LTaskQueue := specialize TPriorityQueue<TTask>.Create(@CompareTaskPriority);
LTaskQueue.Push(task);
var LTopTask := LTaskQueue.Pop(); // 获取最高优先级任务
```

### LruCache - LRU 缓存

**使用时机**:
- 需要固定大小的缓存
- 自动淘汰最久未使用的项
- 内存受限的缓存场景

**示例**:
```pascal
var LCache := specialize MakeLruCache<string, TData>(1000); // 最多1000项
```

---

## 📊 性能速查表

### 时间复杂度对比

| 操作 | HashMap | TreeMap | LinkedHashMap | Vec | VecDeque | List | HashSet | TreeSet | BitSet |
|------|---------|---------|---------------|-----|----------|------|---------|---------|--------|
| 插入 | O(1) | O(log n) | O(1) | O(1)* | O(1) | O(1)** | O(1) | O(log n) | O(1) |
| 查找 | O(1) | O(log n) | O(1) | O(1) | O(1) | O(n) | O(1) | O(log n) | O(1) |
| 删除 | O(1) | O(log n) | O(1) | O(n) | O(n) | O(1)** | O(1) | O(log n) | O(1) |
| 遍历 | O(n) | O(n)*** | O(n)*** | O(n) | O(n) | O(n) | O(n) | O(n)*** | O(n/64) |

*Vec 尾部追加是 O(1) 摊销，中间插入是 O(n)  
**List 已知位置时是 O(1)，否则需要先查找  
***TreeMap/TreeSet/LinkedHashMap 遍历有序

### 空间复杂度对比

| 容器 | 空间开销 | 说明 |
|------|----------|------|
| HashMap | O(n) | 基准 |
| TreeMap | O(n) | +节点指针 |
| LinkedHashMap | O(n) | +双向链表指针 |
| Vec | O(n) | +预留空间 |
| List | O(n) | +节点指针 |
| BitSet | O(n/64) | **极致压缩** |

---

## 💡 实用决策技巧

### 技巧 1：不确定时选 HashMap/Vec

```
不确定选哪个？默认选择：
- 键值对 → HashMap
- 序列 → Vec
- 集合 → HashSet
```

这些是最通用、性能最好的选择。

### 技巧 2：性能优化时才考虑特殊容器

| 优化目标 | 从 | 到 |
|----------|----|----|
| 需要顺序 | HashMap | LinkedHashMap 或 TreeMap |
| 需要排序 | HashMap | TreeMap |
| 节省内存 | HashSet<Integer> | BitSet |
| 两端操作 | Vec | VecDeque |
| 频繁中间插删 | Vec | List |

### 技巧 3：根据数据量选择

```
数据量   推荐容器           理由
< 100    Vec/HashMap        简单高效
< 10K    Vec/HashMap        性能最优
< 100K   HashMap/TreeMap    按需求选
> 100K   TreeMap/BitSet     稳定性能
```

---

## 🎓 学习路径

### 新手推荐顺序

1. **先学 Vec** - 最常用的顺序容器
2. **再学 HashMap** - 最常用的键值容器
3. **了解 VecDeque** - 队列场景
4. **了解 TreeMap** - 有序需求
5. **进阶学习** - LinkedHashMap, BitSet, PriorityQueue

### 常见错误

❌ **错误 1**: 用 List 存储需要随机访问的数据
```pascal
// 不好：List 的随机访问是 O(n)
var LData := specialize MakeList<Integer>();
WriteLn(LData[100]); // 慢！
```

✅ **正确**:
```pascal
// 好：Vec 的随机访问是 O(1)
var LData := specialize MakeVec<Integer>();
WriteLn(LData[100]); // 快！
```

❌ **错误 2**: 用 Vec 频繁头部插入
```pascal
// 不好：Vec 的头部插入是 O(n)
for i := 1 to 10000 do
  LVec.Insert(0, i); // 每次都要移动所有元素
```

✅ **正确**:
```pascal
// 好：VecDeque 的头部插入是 O(1)
for i := 1 to 10000 do
  LDeque.PushFront(i);
```

❌ **错误 3**: 用 HashSet<Integer> 存储大量整数
```pascal
// 不好：内存浪费
var LIDs := specialize MakeHashSet<Integer>();
for i := 0 to 1000000 do
  LIDs.Add(i); // 消耗约 160 MB
```

✅ **正确**:
```pascal
// 好：BitSet 节省 99% 内存
var LIDs := MakeBitSet(1000000);
for i := 0 to 1000000 do
  LIDs.SetBit(i); // 只消耗约 125 KB
```

---

## 📚 更多资源

- **API 参考**: [COLLECTIONS_API_REFERENCE.md](COLLECTIONS_API_REFERENCE.md)
- **最佳实践**: [COLLECTIONS_BEST_PRACTICES.md](COLLECTIONS_BEST_PRACTICES.md)（待创建）
- **性能分析**: [COLLECTIONS_PERFORMANCE_ANALYSIS.md](COLLECTIONS_PERFORMANCE_ANALYSIS.md)（待创建）
- **示例代码**: `examples/collections/`

---

## 🔍 快速查找表

**我需要...**

| 需求 | 推荐容器 |
|------|----------|
| 最快的键值查找 | HashMap |
| 有序的键值对 | TreeMap |
| 保持插入顺序的映射 | LinkedHashMap |
| 最快的列表追加 | Vec |
| 队列（FIFO） | VecDeque |
| 频繁中间插删 | List |
| 去重 | HashSet |
| 有序去重 | TreeSet |
| 权限位管理 | BitSet |
| 优先级队列 | PriorityQueue |
| LRU 缓存 | LruCache |

---

**维护者**: fafafa.core Team  
**最后更新**: 2025-10-28  
**版本**: v1.1

