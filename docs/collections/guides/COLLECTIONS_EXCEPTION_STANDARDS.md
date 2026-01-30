# fafafa.core.collections 异常处理规范

**创建日期**: 2025-12-03  
**Phase**: 3 - Exception Handling Unification  
**状态**: ✅ 完成

---

## 1. 标准异常类型

| 异常类型 | 使用场景 | 示例 |
|----------|----------|------|
| `EOutOfRange` | 索引/范围越界 | `TVec.Get: index out of bounds` |
| `EEmptyCollection` | 空集合上的非法操作 | `TArrayStack: collection is empty` |
| `EInvalidOperation` | 非法状态下的操作 | `HashMap is full` |
| `EInvalidArgument` | 参数值无效 | `capacity must be > 0` |
| `EArgumentNil` | nil 参数 | `source cannot be nil` |
| `ENotCompatible` | 类型不兼容 | `Cannot append to incompatible container` |
| `EOverflow` | 数值溢出 | `capacity overflow` |
| `EOutOfMemory` | 内存分配失败 | (系统异常) |
| `ENotSupported` | 不支持的操作 | `HashMap: please provide hasher` |

---

## 2. 消息格式规范

```
格式: "<ClassName>.<Method>: <描述>"
```

### 示例
```pascal
// ✅ 正确
raise EOutOfRange.Create('TVec.Get: index out of bounds');
raise EEmptyCollection.Create('TArrayStack: collection is empty');
raise EInvalidArgument.Create('TVecDeque.Create: capacity must be > 0');

// ❌ 避免
raise Exception.Create('index out of range');  // 太通用
raise EArgumentOutOfRangeException.Create('out of range');  // 非标准
```

---

## 3. Phase 3 变更记录

### 3.1 已完成的统一

| 原异常 | 新异常 | 涉及文件 |
|--------|--------|----------|
| `EArgumentOutOfRangeException('Deque is empty')` | `EEmptyCollection('TArrayDeque: collection is empty')` | deque.pas |
| `EArgumentOutOfRangeException('Stack is empty')` | `EEmptyCollection('TArrayStack: collection is empty')` | stack.pas |
| `EArgumentOutOfRangeException('Vector is empty')` | `EEmptyCollection('TVec: collection is empty')` | vec.pas |
| `EArgumentOutOfRangeException('...out of range')` | `EOutOfRange('...')` | deque.pas, vecdeque.pas, vec.pas |

### 3.2 统计
- 替换数量: 23 处
- 涉及文件: 4 个
- 测试验证: 50/50 通过

---

## 4. 保留的特殊异常

| 异常类型 | 用途 | 文件 |
|----------|------|------|
| `EWow` | 内部不变量检查（调试用） | forwardList.pas |

> `EWow` 用于检测内部数据结构损坏（如链表 tail 不变量），属于断言性质，正常使用不应触发。

---

## 5. 最佳实践

### 5.1 优先使用 Try* 方法
```pascal
// ✅ 推荐：使用 Try* 避免异常
if not Map.Get(Key, Value) then
  HandleNotFound;

// ⚠️ 可能抛异常
Value := Vec.Get(Index);  // EOutOfRange if index invalid
```

### 5.2 异常文档
所有可能抛出异常的 public 方法应有 `@Exceptions` 文档：
```pascal
{**
 * @desc 获取指定索引的元素
 * @param aIndex 索引
 * @return 元素值
 * @Exceptions EOutOfRange 索引越界时抛出
 *}
function Get(aIndex: SizeUInt): T;
```

---

**审计人**: Warp AI  
**最后更新**: 2025-12-03
