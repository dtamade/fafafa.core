# HashMap 模块修复计划

## 当前状态
HashMap 模块无法编译，主要问题：
1. 缺失 `TGenericCollection<T>` 的多个抽象方法实现
2. `THashSet` 的 Contains 方法签名不匹配
3. 迭代器未实现

## 必须实现的抽象方法

### 1. IsOverlap
```pascal
function IsOverlap(const aSrc: Pointer; aElementCount: SizeUInt): Boolean;
```
- 检查给定的内存区域是否与当前 HashMap 的 buckets 数组重叠
- HashMap 使用动态数组，所以需要检查指针范围

### 2. PtrIter
```pascal
function PtrIter: TPtrIter;
```
- 返回底层指针迭代器
- 需要遍历所有 bsOccupied 状态的 bucket
- 跳过 bsEmpty 和 bsTombstone

### 3. SerializeToArrayBuffer
```pascal
procedure SerializeToArrayBuffer(aDst: Pointer; aCount: SizeUInt);
```
- 将 HashMap 中的所有 Entry 序列化到连续内存缓冲区
- 只序列化 Occupied 的 entries

### 4. AppendUnChecked (Pointer variant)
```pascal
procedure AppendUnChecked(const aSrc: Pointer; aElementCount: SizeUInt);
```
- 从指针数组追加 entries 到 HashMap
- 假设是 TMapEntry<K,V> 数组

### 5. AppendToUnChecked
```pascal
procedure AppendToUnChecked(const aDst: TCollection);
```
- 将当前 HashMap 的所有元素追加到目标集合
- 目标必须是兼容的容器

### 6. DoZero
```pascal
procedure DoZero;
```
- 清空 HashMap 但保留容量
- 所有 bucket 设置为 Empty

### 7. DoReverse
```pascal
procedure DoReverse;
```
- 反转 HashMap（对于哈希表，此操作无意义）
- 可以实现为空操作或抛出 ENotSupported

## THashSet Contains 签名问题

当前问题：
```pascal
// 基类要求：
function Contains(const aElement: T; aEquals: TEqualsFunc<T>; aData: Pointer): Boolean;

// TEqualsFunc<T> 定义：
TEqualsFunc<T> = function (const aLeft, aRight: T; aData: Pointer): Boolean;

// 但 THashSet 使用了不匹配的签名：
// 在调用 inherited Contains 时，传递了错误的 aEquals 类型
```

解决方案：
- THashSet 继承的 Contains 重载必须正确调用基类方法
- 不能直接传递 `TEqualsFunc<K>` 因为它没有 aData 参数

## 实施步骤

### 阶段 1: 实现基本抽象方法（2-3小时）
1. ✅ IsOverlap - 简单的指针范围检查
2. ✅ DoZero - 调用 Clear 然后保留容量
3. ✅ DoReverse - 抛出 ENotSupported（HashMap 不支持反转）
4. ✅ SerializeToArrayBuffer - 遍历并复制 Occupied entries
5. ✅ AppendUnChecked - 批量插入 entries

### 阶段 2: 实现迭代器（2-3小时）
1. ✅ PtrIter - 创建指针迭代器结构
2. ✅ 实现 MoveNext/MovePrev 逻辑
3. ✅ 实现 GetCurrent 返回当前 Entry

### 阶段 3: 修复 THashSet（1小时）
1. ✅ 移除 Contains 重载，只保留基本版本
2. ✅ 或者正确实现 Contains 重载（创建包装函数）

### 阶段 4: 测试（2-3小时）
1. ✅ 编写基本操作测试
2. ✅ 编写迭代器测试
3. ✅ 编写冲突和扩容测试
4. ✅ 性能基准测试

### 阶段 5: 文档和优化（1-2小时）
1. ✅ XML 文档注释
2. ✅ 使用示例
3. ✅ 性能特性说明

## 预期工作量
- 总计：8-12 小时
- 优先级：高（阻塞其他模块使用）

## 设计决策

### HashMap 不支持的操作
以下操作对 HashMap 无意义或不适用：
- `DoReverse` - HashMap 无序，反转无意义
- 基于索引的访问 - HashMap 是关联容器

### 兼容性考虑
- HashMap 的 Entry 类型为 `TMapEntry<K,V>`
- 迭代器返回 Entry，不是单独的 Key 或 Value
- AppendUnChecked 假设源是 Entry 数组

## 替代方案
如果当前设计过于复杂，可以考虑：
1. 不继承 TGenericCollection，自己实现简化版接口
2. 使用组合而非继承
3. 创建独立的 HashMap 实现（不依赖 collections framework）

当前倾向：完成当前设计的完整实现，保持框架一致性。
