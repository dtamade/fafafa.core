# fafafa.core.collections.orderedmap.rb

## 本轮进展（2025-08-20）

- 新增 TRBTreeMap<K,V>（红黑树 OrderedMap）
  - 分层：容器薄适配 + TRBTreeCore<TEntry> 引擎
  - API：InsertOrAssign / TryGetValue / ContainsKey / Remove
  - 迭代：PtrIter（Entry*）、IterateRange(L,R,InclusiveRight)
  - 语义：范围遍历支持 [L,R) 与 [L,R]
  - 内存：FinalizeAdapter 直接 Finalize(Entry)；容器负责托管字段生命周期
- 对外门面：src/fafafa.core.collections.pas 增加 uses 导出
- 单元测试：新增 tests/fafafa.core.collections.orderedmap
  - 3 项用例覆盖：插入/覆盖/查询/删除、全序迭代、范围迭代边界
  - 构建与运行已通过

## 设计要点

- Key 比较器采用 TCompareFunc<K>（函数指针），与 TRBTreeCore 的 TCompareMethod 适配由桥接回调完成
- TEntry = record Key:K; Value:V，容器继承 TGenericCollection<TEntry> 以复用迭代/序列化/Append 框架
- 指针迭代器以节点游标驱动，零拷贝读取 Entry
- 范围迭代基于 LowerBoundNode + Successor/Predecessor，O((log N)+K)

## 遇到的问题与解决

- TPtrIter.Init 需要 aOwner: TCollection；初版未继承 TGenericCollection 导致不匹配
  - 方案：TRBTreeMap 继承 TGenericCollection<TEntry>，实现抽象方法
- Finalize 托管字段：初版尝试用 GetElementManager，命名解析不便
  - 方案：Finalize(Entry) 由编译器按托管规则处理
- 比较器签名不一致：由 TCompareMethod<K> 改为 TCompareFunc<K>，在 CompareAdapter 中透传 aData

## 后续计划

- API 增强
  - TryInsert、RemoveEx(out OldValue)
  - Keys/Values 只读视图与迭代器
- 测试扩充
  - 托管类型 K/V（string/interface/dynarray）内存语义
  - 反向遍历与极端边界（空区间、Left>Right）
  - 大规模随机操作 + 引擎一致性校验
- 文档
  - 在 collections 汇总文档中挂接 OrderedMap 概览与示例
  - 范围迭代语义、复杂度说明

