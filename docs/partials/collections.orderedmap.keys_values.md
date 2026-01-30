# OrderedMap Keys/Values 视图与区间迭代最佳实践

适用实现：TRBTreeMap<K,V>（基于红黑树，按比较器有序）。

## 概览
- Keys(): TIter<K>
  - 迭代顺序：由 Key 比较器决定（默认升序；自定义比较器可改变顺序、大小写敏感性）
  - 复杂度：
    - 首次 MoveNext/MovePrev 启动 O(log n)
    - 单步 MoveNext/MovePrev 摊销 O(1)
- Values(): TIter<V>
  - 与 Keys 同步步进，顺序与对应的 Key 一致
  - 复杂度同上

## 使用要点
- 反向遍历
  - 迭代器初始位置是“未开始”。可以直接调用 MovePrev 从尾部开始反向遍历；无需先 MoveNext 到末尾
- 失效规则（Iterator Validity）
  - 与底层树结构一致：
    - 插入/删除可能影响当前或相邻位置；跨结构修改期间建议重建迭代器
    - 遍历期间不应释放 Map 本身
- 比较器与顺序
  - 大小写不敏感：传入 CaseInsensitive 比较器，Keys 顺序由 CompareText 决定
  - 自定义比较器的传入方式：构造 TRBTreeMap<K,V>.Create(@MyCmp)

## 区间迭代 IterateRange(L,R, InclusiveRight)
- 语义
  - 半开区间 [L, R)：InclusiveRight=False
  - 全闭区间 [L, R]：InclusiveRight=True
  - 边界：当 L > R 时，区间为空（即 MoveNext 立即返回 False）
- 复杂度
  - 启动：O(log n)（LowerBound/UpperBound 寻址）
  - 步进：摊销 O(1)

## 代码示例

大小写不敏感 Key，验证 Keys 升序、Values 与 Keys 对齐：

```pascal
var M: specialize TRBTreeMap<string,Integer>; KI: specialize TIter<string>; VI: specialize TIter<Integer>;
    lastK, curK: string; lastV: Integer;
begin
  M := specialize TRBTreeMap<string,Integer>.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('c',3);

    // Keys：升序
    KI := M.Keys;
    lastK := '';
    while KI.MoveNext do begin
      curK := KI.GetCurrent;
      if lastK<>'' then AssertTrue(CompareText(curK, lastK) > 0);
      lastK := curK;
    end;

    // Values：与 Keys 同步
    VI := M.Values;
    lastV := -MaxInt;
    while VI.MoveNext do begin
      lastV := VI.GetCurrent;
      AssertTrue(lastV >= 1);
    end;
  finally
    M.Free;
  end;
end;
```

反向遍历与顺序对齐（无需先 MoveNext 到尾）：

```pascal
var KI: specialize TIter<string>; VI: specialize TIter<Integer>;
    KList: array[0..2] of string; VList: array[0..2] of Integer; I: Integer;
...
  KI := M.Keys;
  I := 2;
  while KI.MovePrev do begin
    KList[I] := KI.GetCurrent;
    Dec(I);
  end;
  // KList = ['a','b','c'] 的反向填充（索引 0..2）

  VI := M.Values;
  I := 2;
  while VI.MovePrev do begin
    VList[I] := VI.GetCurrent;
    Dec(I);
  end;
  // VList = [1,2,3] 的反向填充，与 KList 对齐
```

## 诊断与常见误区
- MovePrev 失败：若先用 MoveNext 走到了 end(nil)，多数实现上同一迭代器可能无法再回退。建议重新获取一个新迭代器再反向遍历，或直接从未开始状态调用 MovePrev。
- InclusiveRight 设置错误：R 命中端点但 InclusiveRight=False，会导致最后一个元素被排除，注意与需求一致。
- 比较器与期望排序不一致：确认自定义比较函数返回约定（负/零/正）与大小写/区域性行为。

