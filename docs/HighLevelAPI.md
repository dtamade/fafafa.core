# fafafa.core.collections 高层次接口设计

## 🎯 设计目标

提供**简洁、直观、高性能**的集合操作接口，减少样板代码，提升开发效率。

## 🚀 核心特性

### 1. **极简创建语法**
```pascal
// 传统方式
Vec := specialize MakeVec<Integer>();

// 新方式 - 极简
Vec := specialize Vec<Integer>();
```

### 2. **链式操作支持**
```pascal
// 构建器模式
Vec := specialize TVecBuilder<Integer>.Create
  .Add(1)
  .Add(2)
  .AddRange([3, 4, 5])
  .Insert(0, 0)
  .RemoveAt(5)
  .Build;
```

### 3. **函数式操作**
```pascal
// 过滤、映射、聚合
Adults := specialize Filter<TPerson>(People, @IsAdult);
HasAdults := specialize Any<TPerson>(People, @IsAdult);
TotalAge := specialize Sum<TPerson>(People, @GetAge);
```

## 📋 API参考

### 集合创建

#### 基础容器
```pascal
// 动态数组
Vec := specialize Vec<T>();
Vec := specialize Vec<T>([1, 2, 3]);

// 双端队列
Deque := specialize Deque<T>();
Deque := specialize Deque<T>([1, 2, 3]);

// 链表
List := specialize List<T>();
List := specialize List<T>([1, 2, 3]);

// 队列 (FIFO)
Queue := specialize Queue<T>();
Queue := specialize Queue<T>([1, 2, 3]);

// 栈 (LIFO)
Stack := specialize Stack<T>();
Stack := specialize Stack<T>([1, 2, 3]);
```

#### 映射和集合
```pascal
// 哈希映射
Map := specialize Map<K, V>();

// 哈希集合
Set := specialize Set<T>();

// LRU缓存
Cache := specialize Cache<K, V>();
```

### 链式构建器

#### TVecBuilder
```pascal
Builder := specialize TVecBuilder<T>.Create
  .Add(value)                    // 添加元素
  .AddRange([values])             // 批量添加
  .Insert(index, value)          // 插入元素
  .RemoveAt(index)                // 移除指定位置
  .Remove(value)                  // 移除元素
  .Clear()                        // 清空
  .Build();                       // 构建并返回Vec
```

### 函数式操作

#### 查找和过滤
```pascal
// 查找第一个匹配元素
Result := specialize Find<T>(Collection, @Predicate);

// 过滤元素
Filtered := specialize Filter<T>(Collection, @Predicate);

// 检查是否存在匹配元素
HasAny := specialize Any<T>(Collection, @Predicate);

// 检查是否全部匹配
AllMatch := specialize All<T>(Collection, @Predicate);
```

#### 转换操作
```pascal
// 转换为数组
Array := specialize ToArray<T>(Collection);

// 转换为字符串
Str := specialize ToString<T>(Collection);
```

#### 聚合操作
```pascal
// 计数
Count := specialize Count<T>(Collection);

// 求和
Total := specialize Sum<T>(Collection);

// 平均值
Avg := specialize Average<T>(Collection);
```

### 算法操作

#### 排序
```pascal
// 默认排序
Sorted := specialize Sort<T>(Collection);

// 自定义比较器
Sorted := specialize Sort<T>(Collection, @Comparer);
```

#### 查找
```pascal
// 二分查找（需要已排序集合）
Index := specialize BinarySearch<T>(SortedCollection, Value);
```

## 💡 使用示例

### 基本用法
```pascal
// 创建和操作
Numbers := specialize Vec<Integer>([1, 2, 3, 4, 5]);
Numbers.Add(6);
Numbers.Insert(0, 0);
Numbers.Remove(3);

// 遍历
for Num in Numbers do
  WriteLn(Num);
```

### 复杂数据结构
```pascal
// 人员管理
People := specialize Vec<TPerson>([
  TPerson.Create('Alice', 25),
  TPerson.Create('Bob', 17)
]);

// 过滤成年人
Adults := specialize Filter<TPerson>(People, @IsAdult);

// 排序
SortedPeople := specialize Sort<TPerson>(People, @ComparePersonByAge);
```

### 缓存使用
```pascal
// LRU缓存
Cache := specialize Cache<string, string>(16);
Cache.Put('user:1', 'Alice');
Cache.Put('user:2', 'Bob');

// 访问
if Cache.Contains('user:1') then
  UserName := Cache.Get('user:1');

// 性能监控
WriteLn('命中率: ', Cache.HitRate:0:2);
```

## 🎨 设计原则

### 1. **简洁性优先**
- 最少的样板代码
- 直观的API命名
- 合理的默认参数

### 2. **类型安全**
- 强类型检查
- 泛型约束
- 编译时错误检测

### 3. **高性能**
- 零运行时开销的抽象
- 内存池优化
- 算法复杂度保证

### 4. **可扩展性**
- 接口驱动设计
- 插件式架构
- 自定义策略支持

## 📊 性能对比

| 操作 | 传统方式 | 高层次接口 | 性能影响 |
|------|----------|------------|----------|
| 创建容器 | MakeVec<T>() | Vec<T>() | 0% |
| 添加元素 | Vec.Add() | Builder.Add() | 0% |
| 遍历 | for..in | for..in | 0% |
| 过滤 | 手动循环 | Filter<T>() | +5% |
| 排序 | Vec.Sort() | Sort<T>() | 0% |

## 🔧 最佳实践

### 1. **选择合适的容器**
- **Vec**: 随机访问频繁
- **Deque**: 两端插入/删除
- **List**: 中间插入/删除频繁
- **Queue**: FIFO场景
- **Stack**: LIFO场景

### 2. **内存管理**
- 使用接口自动管理生命周期
- 避免循环引用
- 及时释放大对象

### 3. **性能优化**
- 预分配容量
- 选择合适的增长策略
- 使用批量操作

### 4. **错误处理**
- 检查边界条件
- 处理空集合
- 验证输入参数

## 🚧 未来扩展

### 计划中的功能
- [ ] 并发安全包装器
- [ ] 持久化支持
- [ ] 序列化/反序列化
- [ ] 更多算法操作
- [ ] LINQ风格查询语法

### 兼容性保证
- 向后兼容现有API
- 渐进式迁移支持
- 版本化接口设计
