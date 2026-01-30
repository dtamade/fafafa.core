# ForwardList 语义补充与安全约束说明

本补充文档记录 forwardList 在工程内的约定语义与新加入的防御性检查，便于使用者与维护者参照。

## before_begin 语义（InsertAfter 系列）

- 迭代器 Iter 初始状态（未启动且 Data=nil）被视为 “before_begin”。
- 本库工程语义：
  - 非空链表：InsertAfter(before_begin, x) 表示“在头结点之后插入 x”，即 x 成为第二个元素。
  - 空链表：InsertAfter(before_begin, x) 表示“将 x 作为首元素插入”，x 成为新的头结点。
- 该语义适用于 InsertAfter 的所有重载（单元素、计数、数组、范围）。

## Splice 系列的防御性约束

为避免结构破坏与未定义行为，已在实现中加入以下检查：

- 目标归属：aPosition 必须属于目标链表 Self。否则抛出 EInvalidArgument。
- 源归属：
  - Splice(aPosition; var aOther; aFirst) 中，aFirst（若 Data 非 nil）必须属于 aOther，否则抛出 EInvalidArgument。
  - Splice(aPosition; var aOther; aFirst, aLast) 中，aFirst 必须属于 aOther；aLast（若 Data 非 nil）也必须属于 aOther，否则抛出 EInvalidArgument。
- 自拼接：@aOther = @Self 将抛出 EInvalidOperation，当前版本不支持自拼接。

## EraseAfter(range) 可达性检查（调试）

- 在 DEBUG 构建下建议进行 aLast 可达性的断言检查：若 aLast 指向某节点，但从 aPosition 后并不可达，则断言失败以暴露问题。
- Release 构建保持当前“删除直到尾部或到达 aLast（不含）”的语义。

## 迭代器失效与复杂度提醒

- 迭代器失效规则保持不变：
  - InsertAfter/EraseAfter 仅影响局部邻接；指向被删除节点的迭代器失效，其他节点保持有效。
  - Splice/Merge/Unique/Sort/Reverse 可能重连整表；仍存在的节点指针保持有效，但顺序可能改变。
- 复杂度：
  - InsertAfter/EraseAfter/PushFront/PopFront/Front：O(1)
  - Splice: O(n)（取决于区间长度与是否需要寻找前驱）

## 建议

- 如需自拼接语义，请以复制-插入-删除的方式表达，或提交需求进行安全自拼接实现评估。
- 对 EraseAfter(range) 的严格语义可根据需要在 DEBUG 下启用断言检查。

