# TRBTreeMap<K,V> 常用 API 清单

实现：基于红黑树（TRBTreeCore），按比较器有序。

- InsertOrAssign(key,value): Boolean
  - True=插入；False=更新
- TryAdd(key,value): Boolean
  - 仅在不存在时插入
- TryUpdate(key,value): Boolean
  - 仅在存在时更新
- TryGetValue(key, out value): Boolean
- ContainsKey(key): Boolean
- Remove(key): Boolean
- Extract(key, out Entry): Boolean
  - 移除并返回条目（Key/Value），适合做“取出并处理”
- LowerBoundKey(key, out Entry): Boolean
  - 返回第一个 >= key 的条目
- UpperBoundKey(key, out Entry): Boolean
  - 返回第一个 > key 的条目
- Keys(): TIter<K>
  - 投影视图，按 key 顺序遍历，支持正/反向
- Values(): TIter<V>
  - 投影视图，与 Keys 同步步进
- IterateRange(L, R, InclusiveRight=False): TPtrIter
  - [L,R) 或 [L,R] 区间迭代，启动 O(log n)，步进摊销 O(1)

使用与注意
- 比较器决定顺序与相等性（如大小写不敏感）
- 迭代器有效性：插入/删除后建议重建迭代器
- 反向遍历：未开始状态可直接 MovePrev；到达 end(nil) 后建议新建迭代器



## 示例

```pascal
var M: specialize TRBTreeMap<string,Integer>; E: specialize TRBTreeMap<string,Integer>.TEntry; got: Integer;
begin
  M := specialize TRBTreeMap<string,Integer>.Create(@CaseInsensitiveCompare);
  try
    // TryAdd / TryUpdate
    AssertTrue(M.TryAdd('a',1));
    AssertFalse(M.TryAdd('A',9));
    AssertTrue(M.TryUpdate('a',2));
    // Extract
    AssertTrue(M.Extract('a', E) and (E.Value=2));
    // 边界查询
    M.InsertOrAssign('b',10);
    if M.LowerBoundKey('a', E) then ;
    if M.UpperBoundKey('b', E) then ;
  finally
    M.Free;
  end;
end;
```

### 轻量性能演示（非基准，仅示例）

```pascal
const N = 20000;
var t1, t2: QWord; i: Integer; M: specialize TRBTreeMap<string,Integer>;
begin
  M := specialize TRBTreeMap<string,Integer>.Create(@CaseInsensitiveCompare);
  for i := 1 to N do M.TryAdd(IntToStr(i), i);
  t1 := GetTickCount64; for i := 1 to N do M.TryAdd(IntToStr(i), i); t1 := GetTickCount64 - t1;
  t2 := GetTickCount64; for i := 1 to N do M.InsertOrAssign(IntToStr(i), i); t2 := GetTickCount64 - t2;
  WriteLn('[perf] TryAdd-hit(ms)=', t1, ' InsertOrAssign-update(ms)=', t2);
  M.Free;
end;
```


## 范围分页/窗口遍历示例
- 需求：从任意起点 key 开始，每次取 N 个，支持下一页/上一页
- 思路：
  - 下一页：IterateRange(StartKey, +inf)，取 N 个；下一页起点可用 lastKey + #1 或 UpperBoundKey(lastKey)
  - 上一页：IterateRange(-inf, StartKey)，先 MoveNext 到尾，再反向 MovePrev 取 N 个后正序输出
- 示例：samples/orderedmap_range_pagination.pas 与 samples/Build_range_pagination.bat


### 策略选择建议（UpperBoundKey vs lastKey + #1）
- 优先使用 UpperBoundKey 的场景：
  - key 非字符串或不具备“+ #1 即严格大于”的语义（如整数、二进制、复合记录键）
  - 比较器存在等价归一（大小写无关、忽略符号/空白等），可能出现不同表示但相同排序位置
  - 需要对“严格大于”具备可移植/可维护的保证
- 可以使用 lastKey + #1 的场景：
  - key 为受控字符串域，且 + #1 保证按比较器严格大于（如固定前缀+数字后缀，或约定字符表）
  - 强调简单实现与最小依赖，且边界已在调用端统一封装
- 建议：对公共库/通用组件，默认采用 UpperBoundKey；在应用侧可用 lastKey + #1 作为轻量替代，但需约定 key 规范并配套测试

- 非字符串键示例：samples/orderedmap_range_pagination_int.lpr（整数键以 UpperBoundKey 续页），一键脚本 samples/Build_range_pagination_int.bat
