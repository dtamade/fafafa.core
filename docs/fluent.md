# Fluent JSON API (fafafa.core.json.fluent)

目标：在不破坏现有过程式 API 的前提下，提供现代化、链式、类型更安全的接口层，提升开发体验。

## 快速开始

读取 + 指针 + 类型安全访问 + 序列化

```pascal
uses fafafa.core.json.fluent;

var D: IJsonDocF;
begin
  D := JsonF.Parse('{"o":{"k":"v"}}');
  Writeln(D.View('/o/k').AsStrOrDefault(''));
  Writeln(D.AsJson([jwfPretty], 2));
end.
```

构造嵌套对象并保存

```pascal
var B: TJsonBuilderF;
begin
  B := JsonF.NewBuilder(nil).Obj
        .BeginObj('user').PutStr('name','a')
          .BeginArr('roles').AddStr('dev').ArrAddObj.PutStr('k','v').EndObj.EndArr
        .EndObj;
  Writeln(B.ToJson([jwfPretty]));
  B.SaveToFile('out.json', [jwfPretty]);
end.
```

## 主要类型与方法

- IJsonDocF/TJsonDocF（不可变文档包装）
  - Root(): PJsonValue
  - Ptr(path): PJsonValue
  - View(path): TJsonNodeF（类型安全视图）
  - NodeRoot(): TJsonNodeF
  - AsJson(flags=[], indent=0): String
  - SaveToFile(path, flags=[]): Boolean

- TJsonNodeF（类型安全视图）
  - IsNull/IsBool/IsNum/IsStr/IsArr/IsObj
  - TryAsBool/Int/Real/Str
  - AsBoolOrDefault/AsIntOrDefault/AsRealOrDefault/AsStrOrDefault

- TJsonBuilderF（可变文档构造器）
  - Obj/Arr：设置根并移动游标
  - PutStr/PutInt/PutBool：对象字段
  - AddStr/AddInt/AddBool：数组元素
  - BeginObj(Key)/EndObj：对象下新建子对象并下沉/回退
  - BeginArr(Key)/EndArr：对象下新建子数组并下沉/回退
  - ArrAddObj/ArrAddArr：数组下追加子对象/子数组并下沉
  - ToJson(flags=[], indent=0): String
  - SaveToFile(path, flags=[], indent=0): Boolean
  - Detach(): TJsonMutDocument（转移文档所有权）

- JsonF（门面）
  - Parse(text) / Parse(text, flags, allocator, out err)
  - ParseFile(path) / ParseFile(path, flags, allocator, out err)
  - ParseStream(stream) / ParseStream(stream, flags, allocator, out err)
  - NewBuilder(allocator)

## 设计原则

- 不破坏现有 API：过程式/指针型接口保持不变
- Pascal 风格命名与参数顺序（输入在前，可选在后）
- 明确内存所有权：
  - IJsonDocF 采用接口引用计数自动释放
  - TJsonBuilderF.Detach 将 TJsonMutDocument 所有权转交调用者
- 错误处理：
  - Parse 系列同时提供不抛异常的 out err 版本
  - Pointer/Patch 等仍保持现有返回风格（ok/err 或 nil）

## 注意事项

- ToJson/SaveToFile 基于当前根（Obj/Arr 调用后已设置）。若未设置根，ToJson 返回 "null"。
- Begin*/End* 为链式构造语法糖；请成对使用，避免游标错位。调试场景可考虑加断言。
- Builder 输出当前为内存字符串实现；后续版本会加入 Streaming Writer 以降低大文档内存峰值。

## 对照：过程式 vs Fluent（片段）

- 过程式

```pascal
M := JsonMutDocNew(GetRtlAllocator());
R := JsonMutObj(M); JsonMutDocSetRoot(M, R);
JsonMutObjAddStr(M, R, 'k', 'v');
```

- Fluent

```pascal
B := JsonF.NewBuilder(nil).Obj.PutStr('k','v');
```


## 过程式 → Fluent 迁移对照（常见场景）

- 构造根对象/数组

```pascal
// 过程式
M := JsonMutDocNew(GetRtlAllocator());
R := JsonMutObj(M); JsonMutDocSetRoot(M, R);
A := JsonMutArr(M); // 若需要数组根

// Fluent
B := JsonF.NewBuilder(nil).Obj; // 或 .Arr
```

- 嵌套对象/数组

```pascal
// 过程式（对象下新建子对象/子数组）
U := JsonMutObjAddObj(M, R, 'user');
Roles := JsonMutObjAddArr(M, U, 'roles');
JsonMutArrAppend(Roles, JsonMutStr(M, 'dev'));

// Fluent（等价）
B := JsonF.NewBuilder(nil).Obj
  .BeginObj('user')
    .BeginArr('roles').AddStr('dev').EndArr
  .EndObj;
```

- 设置字段/追加数组

```pascal
// 过程式
JsonMutObjAddStr(M, U, 'name', 'alice');
JsonMutArrAppend(Roles, JsonMutUint(M, 1));

// Fluent（等价）
B.BeginObj('user').PutStr('name','alice').EndObj;
B.BeginArr('roles').AddInt(1).EndArr;
```

- 序列化/保存

```pascal
// 过程式
var Len: SizeUInt; P: PChar; S: String;
P := JsonWrite(Doc, [jwfPretty], Len);
if Assigned(P) then SetString(S, P, Len);
JsonWriteFile('out.json', Doc, [jwfPretty], GetRtlAllocator(), Err);

// Fluent
S := B.ToJson([jwfPretty]);
B.SaveToFile('out.json', [jwfPretty]);
```

- 解析（字符串/文件/流）

```pascal
// 过程式
Doc := JsonRead(PChar(Text), Length(Text), []);
Doc := JsonReadFile('in.json', [], GetRtlAllocator(), Err);

// Fluent
D := JsonF.Parse(Text);
D := JsonF.ParseFile('in.json');
D := JsonF.ParseStream(MemStream);
```

- 指针读取 + 类型安全 TryAs

```pascal
// 过程式
V := JsonPtrGet(JsonDocGetRoot(Doc), '/user/name');
if Assigned(V) and JsonIsStr(V) then
  SetString(S, JsonGetStr(V), JsonGetLen(V));

// Fluent
S := JsonF.ParseFile('in.json').View('/user/name').AsStrOrDefault('');
```


## 调试与断言说明

- 为提高链式构造的可维护性，Fluent Builder 在调试构建下对父子类型进行断言：
  - BeginObj/BeginArr 要求当前游标为“对象”，否则触发断言（消息包含具体方法名）
  - ArrAddObj/ArrAddArr 要求当前游标为“数组”，否则触发断言
- 在发布构建（Release）下，上述检查以“安全返回 Self”的方式处理，不抛异常、不中断链式写法。
- 建议：团队开发阶段启用 Debug 构建，尽早暴露链式误用；上线前使用 Release 构建以获得最佳性能。

## 兼容性

- FPC/Lazarus：已验证
- Delphi：建议通过条件编译适配，后续提供 dpr/dproj 示例

## 未来计划

- Streaming Writer（IJsonSink + JsonWriteTo）
- 更多便捷方法：DocF.AsJsonToFile、ParseFromFile/Stream 的更多重载
- Fluent Builder 的更多类型方法（如 PutReal/AddReal 等）

