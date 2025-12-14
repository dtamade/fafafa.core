# fafafa.core.collections

> **Production-Ready** | 47,617 行代码 | 648 测试 | 10 核心类型内存安全验证通过

现代化的 FreePascal 集合库，设计灵感来自 Rust/Go/Java。

## 快速开始

```pascal
uses fafafa.core.collections.vec, fafafa.core.collections.hashmap;

var
  V: specialize TVec<Integer>;
  M: specialize THashMap<string, Integer>;
begin
  // 向量 (动态数组)
  V := specialize TVec<Integer>.Create;
  try
    V.Push(1);
    V.Push(2);
    V.Push(3);
    WriteLn('Count: ', V.Count);  // 3
    WriteLn('First: ', V.Get(0)); // 1
  finally
    V.Free;
  end;

  // 哈希表
  M := specialize THashMap<string, Integer>.Create;
  try
    M.Put('one', 1);
    M.Put('two', 2);
    if M.ContainsKey('one') then
      WriteLn('one = ', M.Get('one')); // 1
  finally
    M.Free;
  end;
end.
```

## 容器选择指南

| 需求 | 推荐容器 | 复杂度 |
|-----|---------|-------|
| 动态数组 | `TVec<T>` | Push/Pop O(1), Get O(1) |
| 双端队列 | `TVecDeque<T>` | PushFront/Back O(1) |
| 键值映射 | `THashMap<K,V>` | Get/Put O(1) 均摊 |
| 有序映射 | `TTreeMap<K,V>` | Get/Put O(log n) |
| 键值集合 | `THashSet<T>` | Add/Contains O(1) 均摊 |
| 有序集合 | `TTreeSet<T>` | Add/Contains O(log n) |
| 优先队列 | `TPriorityQueue<T>` | Push/Pop O(log n) |
| LRU 缓存 | `TLruCache<K,V>` | Get/Put O(1) |
| 保序映射 | `TLinkedHashMap<K,V>` | 保持插入顺序 |
| 位集合 | `TBitSet` | SetBit O(1) |

## 核心 API 模式

### TVec<T> - 向量

```pascal
V.Push(item);           // 添加到末尾
V.Pop;                  // 移除末尾
V.Get(index);           // 获取元素
V.Put(index, item);     // 设置元素
V.Insert(index, item);  // 插入
V.Delete(index);        // 删除
V.Clear;                // 清空
V.Reserve(n);           // 预分配容量
```

### THashMap<K,V> - 哈希表

```pascal
M.Put(key, value);      // 添加/更新
M.Get(key);             // 获取值
M.TryGet(key, value);   // 安全获取
M.ContainsKey(key);     // 检查键
M.Remove(key);          // 删除
M.Clear;                // 清空
```

### TTreeMap<K,V> - 有序映射

```pascal
M.Put(key, value);      // 添加
M.Get(key);             // 获取
M.FirstKey;             // 最小键
M.LastKey;              // 最大键
// 支持区间迭代
for Pair in M.IterateRange(fromKey, toKey) do ...
```

## 内存管理

所有容器正确管理托管类型（如 `string`），无需手动 Finalize：

```pascal
var V: specialize TVec<string>;
begin
  V := specialize TVec<string>.Create;
  try
    V.Push('Hello');
    V.Push('World');
  finally
    V.Free;  // 自动释放所有字符串
  end;
end.
```

## 运行测试

```bash
cd tests/fafafa.core.collections
bash BuildOrTest.sh test
# 期望输出: Time:xx.xxx N:648 E:0 F:0 I:0
```

## 文档

- [API 索引](../docs/API_collections.md)
- [设计蓝图](../docs/collections.md)
- [内存安全报告](../docs/COLLECTIONS_MEMORY_SAFETY_VERIFICATION_REPORT.md)
- [各容器详细文档](../docs/collections/)

## 质量保证

- ✅ **测试覆盖**: 648 测试用例全部通过
- ✅ **内存安全**: 10 核心类型 HeapTrc 验证，0 泄漏
- ✅ **生产就绪**: 可安全部署到生产环境
