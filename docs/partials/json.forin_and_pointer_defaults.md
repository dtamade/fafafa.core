# JSON for-in 遍历与 Pointer 默认值（快速参考）

本节给出在 fafafa.core.json 中使用 for-in 枚举器与 JSON Pointer + 默认值的最小示例与注意事项。

## for-in 遍历数组

```pascal
for V in JsonArrayItems(R.GetObjectValue('arr')) do
  Writeln('item = ', V.GetInteger);
```

## for-in 遍历对象键值

```pascal
for P in JsonObjectPairs(R.GetObjectValue('obj')) do
  Writeln('key = ', P.Key, ' value = ', P.Value.GetString);
```

- UTF-8 键场景，可使用 JsonObjectPairsUtf8：

```pascal
for U in JsonObjectPairsUtf8(R.GetObjectValue('u')) do
  if U.Key = UTF8String('你好') then
    Writeln('value = ', U.Value.GetInteger);
```

## JSON Pointer + 默认值

```pascal
I64 := JsonGetIntOrDefaultByPtr(R, '/arr/9', -1);
S   := JsonGetStrOrDefaultByPtr(R, '/obj/k', 'default');
```

- 若路径不存在或类型不匹配，返回提供的默认值

## UTF-8 键访问

```pascal
Key := UTF8String('你好');
if JsonHasKeyUtf8(UObj, Key) then
  V := JsonGetValueUtf8(UObj, Key);
```

- 测试/示例源文件建议添加：

```pascal
{$CODEPAGE UTF8}
```

以确保源码中的中文常量按 UTF-8 编译，避免断言或比较失败。

