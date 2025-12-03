# Collections 模块 API 一致性审查报告

**审查日期**: 2025-11-03
**审查范围**: fafafa.core.collections 核心类型API
**审查目标**: 确保API命名、行为、参数一致性

---

## 📋 执行摘要

Collections模块整体API设计优秀，遵循Rust风格现代化设计。发现了一些命名和行为的小不一致，提出具体改进建议。

**评分**: ⭐⭐⭐⭐ (4.0/5.0)

---

## 🔍 API一致性分析

### 1. 命名约定一致性

#### ✅ 优秀的一致性

**双端操作命名**:
```pascal
// Vec
procedure Push(const aElement: T);        // 尾部添加
function Pop: T;                          // 尾部移除

// VecDeque
procedure PushFront(const aElement: T);  // 头部添加
procedure PushBack(const aElement: T);   // 尾部添加
function PopFront: T;                     // 头部移除
function PopBack: T;                      // 尾部移除
```
✅ **一致性**: 使用 `Push/Pop` 前缀，方向用 `Front/Back` 后缀

**容量管理命名**:
```pascal
// 所有容器
procedure Reserve(aCapacity: SizeUInt);   // 预留容量
procedure ShrinkToFit;                    // 收缩到实际大小
function Capacity: SizeUInt;              // 获取容量
function Count: SizeUInt;                 // 获取元素数量
```
✅ **一致性**: 容量管理方法命名统一

**查询方法命名**:
```pascal
// 所有容器
function IsEmpty: Boolean;
function Contains(const aElement: T): Boolean;
function IndexOf(const aElement: T): Integer;
```
✅ **一致性**: 使用 `Is` 前缀表示布尔查询

#### ⚠️ 需要改进的不一致

**问题 1**: `Add` vs `Push` vs `Insert`

```pascal
// Vec
procedure Push(const aElement: T);  // 尾部添加

// HashMap
function Add(const AKey: K; const AValue: V): Boolean;  // 添加键值对

// TreeMap
function Insert(const AKey: K; const AValue: V): Boolean;  // 插入

// VecDeque
procedure Add(const aElement: T);  // 添加（实际是PushBack）
```

⚠️ **不一致**: 三个不同的动词表示"添加元素"

**建议**:
- **Vec**: 保持 `Push`（Rust风格）
- **HashMap/TreeMap**: 统一为 `Insert` 或都用 `Add`
- **VecDeque**: `Add` 应该废弃或明确为 `PushBack` 的别名

**问题 2**: `Remove` 返回值不一致

```pascal
// Vec
function Remove(aIndex: SizeUInt): T;  // 返回被移除的元素

// HashMap
function Remove(const AKey: K): Boolean;  // 返回是否成功移除

// VecDeque
function Remove(aIndex: SizeUInt): T;  // 返回被移除的元素
```

⚠️ **不一致**:
- 顺序容器返回 `T`（被移除的元素）
- 关联容器返回 `Boolean`（是否成功）

**建议**: 保持当前设计，但在文档中明确说明差异原因
- 顺序容器: 按索引删除，元素必存在，返回元素有意义
- 关联容器: 按键删除，键可能不存在，返回成功状态更合理

**问题 3**: `Get` 方法命名

```pascal
// Vec
function Get(aIndex: SizeUInt): T;

// HashMap
function GetValue(const AKey: K): V;           // 可能抛异常
function TryGetValue(const AKey: K; out AValue: V): Boolean;

// VecDeque
function Get(aIndex: SizeUInt): T;
```

⚠️ **不一致**: HashMap 使用 `GetValue`，Vec/VecDeque 使用 `Get`

**建议**:
- 保持当前设计（语义不同）
- 或者HashMap也提供 `Get` 作为 `GetValue` 别名

---

### 2. 参数命名一致性

#### ✅ 良好的一致性

**参数前缀**:
```pascal
// 统一使用 'a' 前缀
procedure Push(const aElement: T);
procedure Reserve(aCapacity: SizeUInt);
function Get(aIndex: SizeUInt): T;
```
✅ **一致性**: 所有参数使用 `a` 前缀

**const 使用**:
```pascal
const aElement: T    // 复杂类型（String, Record, Object）
aIndex: SizeUInt     // 简单类型（Integer, Boolean）
```
✅ **一致性**: 按类型大小合理使用 `const`

#### ⚠️ 需要改进的不一致

**问题 4**: 大小写不统一

```pascal
// Vec/VecDeque (小写)
aIndex: SizeUInt
aElement: T

// HashMap (大写)
AKey: K
AValue: V
```

⚠️ **不一致**: HashMap使用大写参数前缀，其他使用小写

**建议**: 统一为小写 `a` 前缀

---

### 3. 异常 vs Try 版本一致性

#### ✅ 优秀的设计模式

```pascal
// 双版本模式
function Pop: T;                          // 可能抛异常
function TryPop(var aElement: T): Boolean;  // 不抛异常，返回成功状态

function Get(aIndex: SizeUInt): T;        // 可能抛异常
function TryGet(aIndex: SizeUInt; var aElement: T): Boolean;  // 安全版本
```

✅ **一致性**: 大部分方法都提供 Try 版本

#### ⚠️ 缺失的Try版本

**Vec**:
- ✅ `TryPop`
- ✅ `TryGet`
- ❌ 缺少 `TryRemove`

**HashMap**:
- ✅ `TryGetValue`
- ❌ 缺少 `TryRemove`（虽然Remove本身返回Boolean）

**建议**: 补充缺失的Try版本方法

---

### 4. 迭代器接口一致性

#### ✅ 统一的迭代器支持

```pascal
// 所有容器支持 for-in 循环
for Item in Vec do
  WriteLn(Item);

for Item in VecDeque do
  WriteLn(Item);

for Entry in HashMap do
  WriteLn(Entry.Key, ' = ', Entry.Value);
```

✅ **一致性**: 所有容器实现统一的迭代器接口

#### ⚠️ 缺失的迭代器方法

**反向迭代**:
```pascal
// 期望API（Rust风格）
for Item in Vec.Iter do       // 正向
for Item in Vec.IterRev do    // 反向
```

⚠️ **缺失**: 大部分容器缺少反向迭代器

**建议**: 添加反向迭代支持

---

### 5. 错误处理一致性

#### ✅ 异常类型使用合理

```pascal
// 索引越界
raise EOutOfRange.CreateFmt('Index %d >= Count %d', [aIndex, FCount]);

// 无效操作
raise EInvalidOperation.Create('Cannot pop from empty vec');

// 参数错误
raise EArgumentError.Create('Capacity must be positive');
```

✅ **一致性**: 异常类型选择合理

#### ⚠️ 错误消息格式不统一

```pascal
// Vec
raise EOutOfRange.CreateFmt('Index %d >= Count %d', [aIndex, FCount]);

// VecDeque
raise EOutOfRange.CreateFmt('Index out of range: %d', [aIndex]);

// HashMap
raise EInvalidOperation.Create('Key not found');
```

⚠️ **不一致**: 错误消息格式和详细程度不同

**建议**: 统一错误消息格式
```pascal
// 标准格式
'{ClassName}.{MethodName}: {Description} (参数信息)'

// 示例
'TVec.Get: Index 10 out of range [0..5)'
'THashMap.Remove: Key not found (key = "test")'
```

---

## 📊 一致性评分

| 方面 | 评分 | 说明 |
|------|------|------|
| 命名约定 | ⭐⭐⭐⭐ | 整体一致，有小问题 |
| 参数命名 | ⭐⭐⭐⭐ | 基本一致，大小写需统一 |
| 异常处理 | ⭐⭐⭐⭐ | Try版本覆盖较好 |
| 迭代器 | ⭐⭐⭐⭐ | 统一支持，缺少反向迭代 |
| 错误消息 | ⭐⭐⭐ | 格式不统一 |

**总体评分**: ⭐⭐⭐⭐ (4.0/5.0)

---

## 🎯 改进建议优先级

### P0 (关键)

1. **统一参数命名大小写**
   ```pascal
   // 修改前 (HashMap)
   function Add(const AKey: K; const AValue: V): Boolean;

   // 修改后
   function Add(const aKey: K; const aValue: V): Boolean;
   ```

2. **标准化错误消息格式**
   ```pascal
   // 统一格式
   raise EOutOfRange.CreateFmt(
     '%s.%s: Index %d out of range [0..%d)',
     [Self.ClassName, 'Get', aIndex, FCount-1]
   );
   ```

### P1 (重要)

3. **补充缺失的Try方法**
   ```pascal
   function TryRemove(aIndex: SizeUInt; var aElement: T): Boolean;
   ```

4. **明确Add/Push/Insert语义**
   - 在文档中解释为什么使用不同的动词
   - 或者提供别名统一命名

5. **添加反向迭代器**
   ```pascal
   function GetReverseIterator: IIterator;
   // 或使用Rust风格
   function Rev: IIterator;
   ```

### P2 (可选)

6. **提供方法别名**
   ```pascal
   // HashMap
   function Get(const aKey: K): V; // GetValue的别名

   // VecDeque
   procedure PushBack(const aElement: T); // Add的显式版本
   ```

7. **国际化错误消息**
   ```pascal
   type
     TErrorCode = (ecOutOfRange, ecInvalidOp, ...);

   function GetErrorMessage(aCode: TErrorCode): String;
   ```

---

## 📝 具体API审查

### Vec API

#### ✅ 优点
- Rust风格命名（Push/Pop/Reserve）
- 完整的Try版本
- 清晰的容量管理

#### ⚠️ 需要改进
- 缺少 `TryRemove`
- 缺少反向迭代器

#### 推荐API补充
```pascal
// 安全移除
function TryRemove(aIndex: SizeUInt; var aElement: T): Boolean;

// 反向迭代
function Rev: IIterator;

// 批量操作
procedure Extend(const aOther: IVec<T>);
procedure AppendRange(const aElements: array of T);
```

### VecDeque API

#### ✅ 优点
- 完整的双端操作
- 丰富的排序算法选择
- Rotate/Split/Merge高级操作

#### ⚠️ 需要改进
- `Add` 方法语义不清（应该是PushBack）
- 缺少反向迭代器

#### 推荐API补充
```pascal
// 明确废弃或提供别名
procedure Add(const aElement: T); deprecated 'Use PushBack instead';

// 反向迭代
function RevIter: IIterator;

// 双端批量操作
procedure ExtendFront(const aOther: IVecDeque<T>);
procedure ExtendBack(const aOther: IVecDeque<T>);
```

### HashMap API

#### ✅ 优点
- 清晰的键值操作语义
- TryGetValue提供安全访问
- 负载因子自动管理

#### ⚠️ 需要改进
- 参数命名大小写不一致（`AKey` vs `aKey`）
- 缺少 `Get` 方法（只有`GetValue`）

#### 推荐API补充
```pascal
// 提供Get别名
function Get(const aKey: K): V; inline;
begin
  Result := GetValue(aKey);
end;

// 统一参数命名
function Add(const aKey: K; const aValue: V): Boolean;

// 批量操作
procedure InsertAll(const aOther: IHashMap<K,V>);
function RemoveAll(const aKeys: array of K): SizeUInt;
```

### TreeMap API

#### ✅ 优点
- 范围查询支持（LowerBound/UpperBound）
- 自动排序维护
- O(log n)性能保证

#### ⚠️ 需要改进
- `Insert` vs `Add` 命名不一致（与HashMap不同）
- 缺少批量插入方法

#### 推荐API补充
```pascal
// 统一命名（与HashMap一致）
function Add(const aKey: K; const aValue: V): Boolean;  // Insert的别名

// 范围操作增强
function GetRange(const aFrom, aTo: K): IEnumerable<TEntry>;
procedure RemoveRange(const aFrom, aTo: K);

// 批量操作
procedure InsertAll(const aEntries: array of TEntry);
```

---

## 🔧 实施计划

### 第一步：参数命名统一（1-2小时）

1. 搜索所有 `AKey`, `AValue`, `AIndex` 等大写参数
2. 批量替换为小写 `aKey`, `aValue`, `aIndex`
3. 运行测试确保无破坏

### 第二步：错误消息标准化（2-3小时）

1. 定义标准错误消息格式
2. 创建错误消息生成辅助函数
3. 逐个模块更新错误消息
4. 更新测试用例（如果依赖错误消息）

### 第三步：补充Try方法（3-4小时）

1. 识别缺失的Try版本方法
2. 实现Try方法
3. 添加测试用例
4. 更新文档

### 第四步：API别名和废弃标记（1-2小时）

1. 添加推荐的别名方法
2. 标记不推荐的方法为 `deprecated`
3. 更新文档和迁移指南

**预计总耗时**: 7-11小时

---

## 📚 参考标准

### Rust Collections API

```rust
// Vec
vec.push(x);           // 添加到尾部
vec.pop();             // 从尾部移除
vec.get(i);            // 安全访问
vec[i];                // 不安全访问

// VecDeque
deque.push_front(x);   // 头部添加
deque.push_back(x);    // 尾部添加
deque.pop_front();     // 头部移除
deque.pop_back();      // 尾部移除

// HashMap
map.insert(k, v);      // 插入
map.get(&k);           // 安全获取
map.remove(&k);        // 移除

// BTreeMap (类似TreeMap)
map.insert(k, v);
map.range(start..end); // 范围查询
```

**启示**:
- 使用 `push/pop` 而非 `add/remove`（顺序容器）
- 使用 `insert` 而非 `add`（关联容器）
- 提供 `get` 方法（安全）和索引操作符（不安全）

---

## ✅ 总结

### 当前状态

**优势**:
- 整体API设计优秀
- 遵循Rust现代化设计
- 命名基本一致
- 错误处理合理

**不足**:
- 参数命名大小写不统一
- 错误消息格式不一致
- 部分Try方法缺失
- 缺少反向迭代器

### 改进后预期

通过实施改进计划（7-11小时），API一致性评分可提升到：

**目标评分**: ⭐⭐⭐⭐⭐ (4.8/5.0)

### 下一步行动

1. **立即执行**: 参数命名统一（P0）
2. **本周完成**: 错误消息标准化（P0）
3. **下周完成**: 补充Try方法（P1）
4. **本月完成**: API别名和迭代器增强（P1/P2）

---

**报告结束**

Collections模块API设计已经很优秀，通过小幅改进可达到近乎完美的一致性。