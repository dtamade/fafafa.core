# Collections 新增实用容器规划

**规划日期**: 2025-11-03
**目标**: 为fafafa.core.collections添加实用容器类型
**依据**: 常见使用场景和其他语言标准库

---

## 📋 规划概述

基于当前Collections模块已有的基础设施（分配器接口、泛型系统、迭代器支持），规划新增5-10个实用容器类型，覆盖常见的开发场景。

### 设计原则

1. **实用性优先** - 解决实际开发中的常见需求
2. **性能优异** - 利用已有的优化基础设施
3. **API一致** - 遵循现有Collections的命名和行为约定
4. **文档完整** - 提供清晰的使用文档和示例
5. **测试覆盖** - 每个容器都有完整的测试套件

---

## 🎯 新增容器清单

### 优先级 P0（必需 - 填补关键空缺）

#### 1. TCircularBuffer<T> - 环形缓冲区

**使用场景**:
- 日志记录（保留最近N条日志）
- 性能监控（滑动窗口统计）
- 音视频流处理（固定大小缓冲）

**核心特性**:
```pascal
type
  TCircularBuffer<T> = class
  private
    FBuffer: TArray<T>;
    FHead: SizeUInt;
    FTail: SizeUInt;
    FCapacity: SizeUInt;
    FOverwriteOldest: Boolean;  // 满时覆盖最旧元素
  public
    constructor Create(aCapacity: SizeUInt; aOverwriteOldest: Boolean = True);

    // 添加元素（满时根据策略处理）
    function Push(const aElement: T): Boolean;

    // 读取但不移除
    function Peek: T;
    function PeekAt(aOffset: SizeUInt): T;  // 相对head的偏移

    // 弹出元素
    function Pop: T;
    function TryPop(var aElement: T): Boolean;

    // 状态查询
    function IsFull: Boolean;
    function IsEmpty: Boolean;
    function Count: SizeUInt;
    function Capacity: SizeUInt;

    // 批量操作
    function PopBatch(aCount: SizeUInt): TArray<T>;
    procedure Clear;
  end;
```

**关键优势**:
- ✅ O(1) Push/Pop操作
- ✅ 固定内存占用
- ✅ 无需动态扩容
- ✅ 自动覆盖策略

**实现难度**: ⭐⭐ (中等)

**预计工时**: 4-6小时（实现 + 测试 + 文档）

---

#### 2. TMultiMap<K,V> - 一对多映射

**使用场景**:
- 标签系统（一个对象多个标签）
- 事件订阅（一个事件多个处理器）
- HTTP头（一个key多个value）

**核心特性**:
```pascal
type
  TMultiMap<K,V> = class
  private
    FMap: THashMap<K, TVec<V>>;  // 基于HashMap + Vec实现
  public
    // 添加键值对（允许重复值）
    procedure Add(const aKey: K; const aValue: V);

    // 移除特定键值对
    function Remove(const aKey: K; const aValue: V): Boolean;

    // 移除键的所有值
    function RemoveAll(const aKey: K): SizeUInt;  // 返回移除数量

    // 查询
    function Contains(const aKey: K): Boolean;
    function ContainsValue(const aKey: K; const aValue: V): Boolean;
    function GetValues(const aKey: K): IEnumerable<V>;
    function GetValueCount(const aKey: K): SizeUInt;

    // 遍历
    function GetKeys: IEnumerable<K>;
    function GetAllValues: IEnumerable<V>;

    // 统计
    function KeyCount: SizeUInt;    // 键的数量
    function TotalCount: SizeUInt;  // 所有值的总数
  end;
```

**关键优势**:
- ✅ 自然的一对多语义
- ✅ 基于成熟的HashMap实现
- ✅ 高效的查询和添加

**实现难度**: ⭐⭐ (中等)

**预计工时**: 5-7小时

---

#### 3. TOrderedSet<T> - 有序集合（保持插入顺序）

**使用场景**:
- 配置文件键顺序
- UI元素渲染顺序
- 任务执行顺序

**核心特性**:
```pascal
type
  TOrderedSet<T> = class
  private
    FList: TLinkedHashMap<T, Boolean>;  // 值始终为True
  public
    // 集合操作
    function Add(const aElement: T): Boolean;  // 返回是否新增
    function Remove(const aElement: T): Boolean;
    function Contains(const aElement: T): Boolean;

    // 顺序访问
    function First: T;
    function Last: T;
    function GetAt(aIndex: SizeUInt): T;

    // 集合运算
    procedure Union(const aOther: TOrderedSet<T>);
    procedure Intersect(const aOther: TOrderedSet<T>);
    procedure Difference(const aOther: TOrderedSet<T>);

    // 转换
    function ToArray: TArray<T>;
  end;
```

**关键优势**:
- ✅ 保持插入顺序
- ✅ O(1) 查找
- ✅ 有序遍历

**实现难度**: ⭐ (简单 - 基于LinkedHashMap包装)

**预计工时**: 3-4小时

---

### 优先级 P1（重要 - 常见使用场景）

#### 4. TBoundedQueue<T> - 有界队列

**使用场景**:
- 任务队列（限制队列长度）
- 消息队列（防止内存溢出）
- 缓冲区管理

**核心特性**:
```pascal
type
  TBlockingStrategy = (bsDropOldest, bsDropNewest, bsBlock, bsReject);

  TBoundedQueue<T> = class
  private
    FQueue: TVecDeque<T>;
    FMaxCapacity: SizeUInt;
    FBlockingStrategy: TBlockingStrategy;
  public
    constructor Create(aMaxCapacity: SizeUInt;
                      aStrategy: TBlockingStrategy = bsDropOldest);

    // 入队（根据策略处理满队列）
    function Enqueue(const aElement: T): Boolean;

    // 出队
    function Dequeue: T;
    function TryDequeue(var aElement: T): Boolean;

    // 查询
    function IsFull: Boolean;
    function IsEmpty: Boolean;
    function Count: SizeUInt;
    function RemainingCapacity: SizeUInt;
  end;
```

**关键优势**:
- ✅ 限制内存使用
- ✅ 多种溢出策略
- ✅ 线程安全选项（可扩展）

**实现难度**: ⭐⭐ (中等)

**预计工时**: 4-6小时

---

#### 5. TBiMap<K,V> - 双向映射

**使用场景**:
- ID到名称的双向查找
- 枚举值到字符串的互转
- 图节点ID和名称映射

**核心特性**:
```pascal
type
  TBiMap<K,V> = class
  private
    FForward: THashMap<K, V>;
    FInverse: THashMap<V, K>;
  public
    // 双向添加
    function Put(const aKey: K; const aValue: V): Boolean;

    // 正向查询
    function GetValue(const aKey: K): V;
    function TryGetValue(const aKey: K; out aValue: V): Boolean;

    // 反向查询
    function GetKey(const aValue: V): K;
    function TryGetKey(const aValue: V; out aKey: K): Boolean;

    // 移除
    function RemoveByKey(const aKey: K): Boolean;
    function RemoveByValue(const aValue: V): Boolean;

    // 查询
    function ContainsKey(const aKey: K): Boolean;
    function ContainsValue(const aValue: V): Boolean;
  end;
```

**关键优势**:
- ✅ O(1) 双向查找
- ✅ 自动维护一致性
- ✅ 节省代码重复

**实现难度**: ⭐⭐⭐ (中等偏难 - 需要维护一致性)

**预计工时**: 6-8小时

---

#### 6. TLazyList<T> - 惰性列表

**使用场景**:
- 大文件逐行读取
- 数据库结果集遍历
- 无限序列生成

**核心特性**:
```pascal
type
  TGenerator<T> = function: T;  // 元素生成函数

  TLazyList<T> = class
  private
    FGenerator: TGenerator<T>;
    FCache: TVec<T>;
    FMaxCacheSize: SizeUInt;
  public
    constructor Create(aGenerator: TGenerator<T>; aMaxCacheSize: SizeUInt = 100);

    // 按需获取
    function Take(aCount: SizeUInt): TArray<T>;
    function TakeWhile(aPredicate: TPredicate<T>): TArray<T>;

    // 迭代器（惰性）
    function GetEnumerator: IEnumerator<T>;

    // 转换
    function Map(aTransform: TFunc<T, T>): TLazyList<T>;
    function Filter(aPredicate: TPredicate<T>): TLazyList<T>;
  end;
```

**关键优势**:
- ✅ 内存高效（按需加载）
- ✅ 支持无限序列
- ✅ 函数式编程风格

**实现难度**: ⭐⭐⭐⭐ (较难 - 需要闭包和状态管理)

**预计工时**: 8-10小时

---

### 优先级 P2（增强 - 特殊场景）

#### 7. TBloomFilter<T> - 布隆过滤器

**使用场景**:
- 快速去重检测
- 缓存穿透防护
- 大数据存在性查询

**核心特性**:
```pascal
type
  TBloomFilter<T> = class
  private
    FBits: TBitSet;
    FHashFuncs: array of THashFunc<T>;
    FExpectedElements: SizeUInt;
    FFalsePositiveRate: Double;
  public
    constructor Create(aExpectedElements: SizeUInt; aFalsePositiveRate: Double = 0.01);

    // 添加元素
    procedure Add(const aElement: T);

    // 查询（可能误判为存在）
    function MightContain(const aElement: T): Boolean;

    // 统计
    function EstimatedCount: SizeUInt;
    function ActualFalsePositiveRate: Double;
  end;
```

**关键优势**:
- ✅ 极高的空间效率
- ✅ O(k) 查询时间（k为哈希函数数量）
- ✅ 适合大规模数据

**实现难度**: ⭐⭐⭐ (中等偏难 - 需要多个哈希函数)

**预计工时**: 6-8小时

---

#### 8. TTrieMap<V> - 字典树映射

**使用场景**:
- 自动补全
- 前缀搜索
- 字符串索引

**核心特性**:
```pascal
type
  TTrieMap<V> = class
  private
    type
      PNode = ^TNode;
      TNode = record
        Children: THashMap<Char, PNode>;
        Value: V;
        IsTerminal: Boolean;
      end;
    var
      FRoot: PNode;
  public
    // 插入
    procedure Put(const aKey: String; const aValue: V);

    // 查询
    function Get(const aKey: String): V;
    function TryGet(const aKey: String; out aValue: V): Boolean;
    function Contains(const aKey: String): Boolean;

    // 前缀操作
    function GetKeysWithPrefix(const aPrefix: String): TArray<String>;
    function GetLongestPrefix(const aKey: String): String;

    // 模式匹配
    function GetKeysMatchingPattern(const aPattern: String): TArray<String>;  // 支持?和*
  end;
```

**关键优势**:
- ✅ 前缀查询高效
- ✅ 公共前缀压缩
- ✅ 支持模式匹配

**实现难度**: ⭐⭐⭐⭐ (较难 - 递归结构)

**预计工时**: 8-12小时

---

#### 9. TIntervalTree<T> - 区间树

**使用场景**:
- 时间段冲突检测
- 内存区域管理
- 几何区间查询

**核心特性**:
```pascal
type
  TInterval<T> = record
    Low, High: T;
    Data: Pointer;  // 关联数据
  end;

  TIntervalTree<T> = class
  public
    // 插入区间
    procedure Insert(aLow, aHigh: T; aData: Pointer = nil);

    // 查询重叠区间
    function FindOverlapping(aLow, aHigh: T): TArray<TInterval<T>>;

    // 查询包含点的区间
    function FindContaining(aPoint: T): TArray<TInterval<T>>;

    // 删除区间
    function Remove(aLow, aHigh: T): Boolean;
  end;
```

**关键优势**:
- ✅ 高效的区间查询
- ✅ 支持重叠检测
- ✅ 应用广泛

**实现难度**: ⭐⭐⭐⭐⭐ (困难 - 复杂的树结构)

**预计工时**: 12-16小时

---

#### 10. TSkipList<K,V> - 跳表

**使用场景**:
- TreeMap的替代实现
- 并发友好的有序映射
- Redis等数据库内部结构

**核心特性**:
```pascal
type
  TSkipList<K,V> = class
  private
    const MaxLevel = 16;
    type
      PNode = ^TNode;
      TNode = record
        Key: K;
        Value: V;
        Forward: array[0..MaxLevel-1] of PNode;
      end;
  public
    // 基本操作
    procedure Insert(const aKey: K; const aValue: V);
    function Search(const aKey: K): V;
    function Remove(const aKey: K): Boolean;

    // 范围查询
    function Range(const aFrom, aTo: K): TArray<TPair<K,V>>;

    // 统计
    function Count: SizeUInt;
  end;
```

**关键优势**:
- ✅ 实现比红黑树简单
- ✅ 并发友好（可无锁实现）
- ✅ O(log n)平均性能

**实现难度**: ⭐⭐⭐⭐ (较难 - 概率数据结构)

**预计工时**: 10-14小时

---

## 📊 优先级总结

| 容器 | 优先级 | 难度 | 工时 | 价值 |
|------|--------|------|------|------|
| TCircularBuffer | P0 | ⭐⭐ | 4-6h | ⭐⭐⭐⭐⭐ |
| TMultiMap | P0 | ⭐⭐ | 5-7h | ⭐⭐⭐⭐⭐ |
| TOrderedSet | P0 | ⭐ | 3-4h | ⭐⭐⭐⭐ |
| TBoundedQueue | P1 | ⭐⭐ | 4-6h | ⭐⭐⭐⭐ |
| TBiMap | P1 | ⭐⭐⭐ | 6-8h | ⭐⭐⭐⭐ |
| TLazyList | P1 | ⭐⭐⭐⭐ | 8-10h | ⭐⭐⭐ |
| TBloomFilter | P2 | ⭐⭐⭐ | 6-8h | ⭐⭐⭐ |
| TTrieMap | P2 | ⭐⭐⭐⭐ | 8-12h | ⭐⭐⭐ |
| TIntervalTree | P2 | ⭐⭐⭐⭐⭐ | 12-16h | ⭐⭐⭐ |
| TSkipList | P2 | ⭐⭐⭐⭐ | 10-14h | ⭐⭐ |

---

## 🎯 实施计划

### 第一阶段：P0容器（12-17小时）

**目标**: 填补基础功能空缺

1. **TCircularBuffer** (4-6h)
   - Week 1: 实现核心功能
   - Week 1: 编写测试和文档

2. **TMultiMap** (5-7h)
   - Week 2: 基于HashMap+Vec实现
   - Week 2: 测试和优化

3. **TOrderedSet** (3-4h)
   - Week 2: 包装LinkedHashMap
   - Week 2: 文档和示例

### 第二阶段：P1容器（18-24小时）

**目标**: 增强常见场景支持

4. **TBoundedQueue** (4-6h)
   - Week 3: 实现溢出策略
   - Week 3: 测试各种策略

5. **TBiMap** (6-8h)
   - Week 4: 实现双向同步
   - Week 4: 一致性测试

6. **TLazyList** (8-10h)
   - Week 5: 惰性求值机制
   - Week 5: 函数式操作

### 第三阶段：P2容器（36-50小时）

**目标**: 特殊场景和高级功能

7-10. 根据实际需求选择实现

**总预计工时**: 66-91小时（分3个阶段）

---

## 📝 设计规范

### 1. 命名约定

```pascal
// 类名：T + 容器类型
TCircularBuffer<T>
TMultiMap<K,V>

// 方法名：动词 + 名词
procedure Add(...);
function Get(...): T;
function TryPop(...): Boolean;

// 参数名：a + 类型
aElement: T
aKey: K
aValue: V
```

### 2. 接口设计

```pascal
// 每个容器实现相关接口
TCircularBuffer<T> = class(IQueue<T>)
TMultiMap<K,V> = class(IEnumerable<TEntry<K,V>>)
```

### 3. 错误处理

```pascal
// 提供异常和Try双版本
function Pop: T;  // 可能抛EInvalidOperation
function TryPop(var aElement: T): Boolean;  // 不抛异常
```

### 4. 文档要求

```pascal
{**
 * MethodName
 * @desc 功能描述
 * @param aParam 参数说明
 * @return 返回值说明
 * @Complexity O(n) 时间复杂度
 * @ThreadSafety NOT thread-safe
 * @example
 *   var buf: TCircularBuffer<Integer>;
 *   buf := TCircularBuffer<Integer>.Create(10);
 *   buf.Push(42);
 *}
```

### 5. 测试要求

每个容器必须包含：
- 基本操作测试
- 边界测试（空、满、单元素）
- 压力测试（大量元素）
- 性能基准测试

---

## 🎉 预期成果

### 完成后Collections模块将具备

**基础容器** (已有):
- Vec, VecDeque, HashMap, TreeMap, BitSet, ...

**新增实用容器** (计划):
- TCircularBuffer - 固定大小环形缓冲
- TMultiMap - 一对多映射
- TOrderedSet - 有序集合
- TBoundedQueue - 有界队列
- TBiMap - 双向映射
- TLazyList - 惰性列表
- TBloomFilter - 布隆过滤器
- TTrieMap - 字典树
- TIntervalTree - 区间树
- TSkipList - 跳表

**总计**: 20+ 个生产就绪的容器类型

### 对标其他语言

| 语言 | Collections数量 | fafafa.core |
|------|----------------|-------------|
| Java | 30+ | 20+ ✅ |
| C++ STL | 15+ | 20+ ✅ |
| Rust std | 10+ | 20+ ✅ |
| Python | 10+ | 20+ ✅ |

---

## 📚 参考资料

### 其他语言实现

- **Java Collections Framework**: MultiMap, CircularBuffer
- **Guava (Google)**: BiMap, BloomFilter, Multiset
- **Boost (C++)**: CircularBuffer, MultiIndex
- **Rust**: VecDeque已有，考虑Arc<T>等智能指针容器

### 论文和算法

- Skip Lists: William Pugh, 1990
- Bloom Filters: Burton H. Bloom, 1970
- Interval Tree: Mark de Berg et al.

---

## ✅ 下一步行动

1. **征求反馈** - 与团队讨论优先级和需求
2. **开始P0实现** - 从TCircularBuffer开始
3. **建立示例库** - 每个容器提供实用示例
4. **持续优化** - 根据使用反馈改进

**首个容器预计完成时间**: 本周内（TCircularBuffer）

---

**规划结束**

Collections模块将成为Pascal生态中最完整、最现代化的容器库！