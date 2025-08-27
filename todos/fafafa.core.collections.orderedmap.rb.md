# TODOS - fafafa.core.collections.orderedmap.rb

## 近期（M1）
- 增强 API
  - TryInsert(key)
  - RemoveEx(key, out OldValue)
  - GetOrAdd(key, default)
- 视图与迭代
  - Keys(): 迭代 K（基于 Entry 指针迭代器投影）
  - Values(): 迭代 V（同上）
  - 反向迭代（验证 MovePrev 覆盖率）
- 范围迭代
  - 左闭右开与全闭边界用例细化（空区间、越界、Left>Right）
- 测试
  - K/V 托管类型（string/interface/dynarray）生命周期验证
  - 大规模随机插入/删除/查询一致性

## 中期（M2）
- 性能与内存
  - 批量载入 AppendUnChecked 优化（保序或乱序策略）
  - 迭代器逃逸/内联检查（Release 编译选项下）
- API 完整性
  - LowerBound/UpperBound 返回 Entry 指针接口
  - Min/Max 返回 Entry 指针接口

## 文档
- report/fafafa.core.collections.orderedmap.rb.md 增补示例与复杂度表
- 在 collections 总览文档中挂接 OrderedMap 部分

