# fafafa.core.base 使用指南

## 概述

`fafafa.core.base` 是 fafafa.core 框架的基础模块，提供：
- 统一的异常体系
- 泛型函数类型（用于函数式编程）
- 元组类型（用于多返回值）
- 基础常量和类型别名

## 快速入门

### 1. 异常处理

```pascal
uses
  fafafa.core.base;

procedure ProcessData(const Data: TBytes);
begin
  // 参数验证
  if Length(Data) = 0 then
    raise EEmptyCollection.Create('Data cannot be empty');

  // 范围检查
  if Index >= Length(Data) then
    raise EOutOfRange.CreateFmt('Index %d out of range [0..%d)', [Index, Length(Data) - 1]);

  // 处理数据...
end;

// 捕获框架异常
try
  ProcessData(MyData);
except
  on E: ECore do
    WriteLn('Framework error: ', E.Message);
end;
```

### 2. 泛型函数类型

```pascal
uses
  fafafa.core.base;

type
  TIntToStr = specialize TFunc<Integer, string>;
  TIntPredicate = specialize TPredicate<Integer>;

// 定义转换函数
function IntToHex(const N: Integer): string;
begin
  Result := Format('0x%x', [N]);
end;

// 定义谓词函数
function IsEven(const N: Integer): Boolean;
begin
  Result := (N mod 2) = 0;
end;

// 使用函数类型
var
  Mapper: TIntToStr;
  Filter: TIntPredicate;
begin
  Mapper := @IntToHex;
  Filter := @IsEven;

  WriteLn(Mapper(42));        // 输出: 0x2a
  WriteLn(Filter(42));        // 输出: True
end;
```

### 3. 元组类型

```pascal
uses
  fafafa.core.base;

type
  TDivResult = specialize TTuple2<Integer, Integer>;

// 返回多个值
function DivMod(A, B: Integer): TDivResult;
begin
  Result := TDivResult.Create(A div B, A mod B);
end;

// 使用元组
var
  Result: TDivResult;
begin
  Result := DivMod(17, 5);
  WriteLn('Quotient: ', Result.First);   // 输出: 3
  WriteLn('Remainder: ', Result.Second); // 输出: 2
end;
```

## 常见使用场景

### 场景 1: 构建类型安全的集合操作

```pascal
type
  TIntVec = specialize TVec<Integer>;
  TIntMapper = specialize TFunc<Integer, Integer>;
  TIntPredicate = specialize TPredicate<Integer>;

function DoubleValue(const N: Integer): Integer;
begin
  Result := N * 2;
end;

function IsPositive(const N: Integer): Boolean;
begin
  Result := N > 0;
end;

var
  Vec: TIntVec;
  Mapper: TIntMapper;
  Filter: TIntPredicate;
begin
  Vec := TIntVec.Create;
  try
    Vec.Push(1);
    Vec.Push(-2);
    Vec.Push(3);

    Mapper := @DoubleValue;
    Filter := @IsPositive;

    // 使用 Map 和 Filter（假设 TVec 支持这些操作）
    // Vec := Vec.Map(Mapper).Filter(Filter);
  finally
    Vec.Free;
  end;
end;
```

### 场景 2: 错误处理和异常层次

```pascal
// 自定义异常继承自 ECore
type
  EMyModuleError = class(ECore);
  EConfigError = class(EMyModuleError);
  ENetworkError = class(EMyModuleError);

procedure LoadConfig(const FileName: string);
begin
  if not FileExists(FileName) then
    raise EConfigError.CreateFmt('Config file not found: %s', [FileName]);

  // 加载配置...
end;

// 分层捕获异常
try
  LoadConfig('config.ini');
except
  on E: EConfigError do
    WriteLn('Configuration error: ', E.Message);
  on E: EMyModuleError do
    WriteLn('Module error: ', E.Message);
  on E: ECore do
    WriteLn('Framework error: ', E.Message);
end;
```

### 场景 3: 使用元组简化复杂返回值

```pascal
type
  TParseResult = specialize TTuple3<Integer, Boolean, string>;

// 解析整数，返回值、成功标志和错误信息
function ParseInt(const S: string): TParseResult;
var
  Value, Code: Integer;
begin
  Val(S, Value, Code);
  if Code = 0 then
    Result := TParseResult.Create(Value, True, '')
  else
    Result := TParseResult.Create(0, False, 'Invalid integer format');
end;

// 使用解析结果
var
  ParseResult: TParseResult;
begin
  ParseResult := ParseInt('123');
  if ParseResult.Second then
    WriteLn('Parsed value: ', ParseResult.First)
  else
    WriteLn('Error: ', ParseResult.Third);
end;
```

## 最佳实践

### 1. 异常使用原则

✅ **推荐做法**：
```pascal
// 使用具体的异常类型
if Index < 0 then
  raise EOutOfRange.Create('Index cannot be negative');

// 提供有用的错误信息
if not FileExists(Path) then
  raise EInvalidArgument.CreateFmt('File not found: %s', [Path]);
```

❌ **避免做法**：
```pascal
// 不要使用通用异常
raise Exception.Create('Error');

// 不要使用空错误信息
raise ECore.Create('');
```

### 2. 泛型函数类型使用

✅ **推荐做法**：
```pascal
// 使用类型别名提高可读性
type
  TUserMapper = specialize TFunc<TUser, string>;
  TUserFilter = specialize TPredicate<TUser>;

function GetUserName(const User: TUser): string;
begin
  Result := User.Name;
end;

var
  Mapper: TUserMapper;
begin
  Mapper := @GetUserName;
  // 使用 Mapper...
end;
```

❌ **避免做法**：
```pascal
// 不要直接使用复杂的泛型类型
var
  Mapper: specialize TFunc<TUser, string>;  // 难以阅读
```

### 3. 元组使用建议

✅ **推荐做法**：
```pascal
// 为元组创建有意义的类型别名
type
  TDivResult = specialize TTuple2<Integer, Integer>;
  TParseResult = specialize TTuple3<Integer, Boolean, string>;

// 使用描述性的字段名（通过注释）
function DivMod(A, B: Integer): TDivResult;
begin
  // First = Quotient, Second = Remainder
  Result := TDivResult.Create(A div B, A mod B);
end;
```

❌ **避免做法**：
```pascal
// 不要在复杂场景中使用元组
// 超过 3 个字段时，应该定义专用的 record 类型
type
  TComplexResult = specialize TTuple4<Integer, string, Boolean, Double>;  // 太复杂
```

## 常见陷阱和解决方案

### 陷阱 1: 忘记处理 nil 参数

❌ **问题代码**：
```pascal
procedure ProcessData(Data: Pointer);
begin
  // 直接使用 Data，可能导致访问违规
  Move(Data^, Buffer, Size);
end;
```

✅ **解决方案**：
```pascal
procedure ProcessData(Data: Pointer);
begin
  if Data = nil then
    raise EArgumentNil.Create('Data cannot be nil');

  Move(Data^, Buffer, Size);
end;
```

### 陷阱 2: 异常信息不够详细

❌ **问题代码**：
```pascal
if Index >= Count then
  raise EOutOfRange.Create('Index out of range');
```

✅ **解决方案**：
```pascal
if Index >= Count then
  raise EOutOfRange.CreateFmt('Index %d out of range [0..%d)', [Index, Count - 1]);
```

### 陷阱 3: 泛型函数类型的生命周期管理

❌ **问题代码**：
```pascal
function GetMapper: TIntMapper;
var
  LocalVar: Integer;
begin
  // 返回引用局部变量的函数（危险！）
  Result := function(const N: Integer): Integer
  begin
    Result := N + LocalVar;  // LocalVar 在函数返回后失效
  end;
end;
```

✅ **解决方案**：
```pascal
// 使用全局函数或确保捕获的变量生命周期足够长
function DoubleValue(const N: Integer): Integer;
begin
  Result := N * 2;
end;

function GetMapper: TIntMapper;
begin
  Result := @DoubleValue;  // 安全
end;
```

### 陷阱 4: 元组字段混淆

❌ **问题代码**：
```pascal
type
  TCoordinate = specialize TTuple2<Integer, Integer>;

var
  Coord: TCoordinate;
begin
  Coord := TCoordinate.Create(10, 20);
  // First 是 X 还是 Y？容易混淆
  WriteLn(Coord.First, ', ', Coord.Second);
end;
```

✅ **解决方案**：
```pascal
// 使用专用的 record 类型
type
  TCoordinate = record
    X, Y: Integer;
    class function Create(AX, AY: Integer): TCoordinate; static;
  end;

var
  Coord: TCoordinate;
begin
  Coord := TCoordinate.Create(10, 20);
  WriteLn(Coord.X, ', ', Coord.Y);  // 清晰明了
end;
```

## 性能考虑

### 1. 异常性能

- **异常抛出和捕获有性能开销**，不要用于正常控制流
- 在性能关键路径上，优先使用返回值（如 `TResult<T, E>`）而非异常

```pascal
// ❌ 性能敏感代码中避免使用异常
function FindItem(const Items: array of Integer; Value: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(Items) do
    if Items[I] = Value then
      Exit(I);
  raise ENotFound.Create('Item not found');  // 性能开销大
end;

// ✅ 使用返回值表示失败
function FindItem(const Items: array of Integer; Value: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(Items) do
    if Items[I] = Value then
      Exit(I);
  Result := -1;  // 使用特殊值表示未找到
end;
```

### 2. 泛型函数类型性能

- 函数指针调用比直接调用略慢，但通常可以忽略
- 在极端性能敏感的场景中，考虑使用内联函数

```pascal
// 性能关键路径：使用内联函数
function DoubleValue(const N: Integer): Integer; inline;
begin
  Result := N * 2;
end;
```

## 相关文档

- [fafafa.core.option 使用指南](fafafa.core.option.guide.md) - Option 类型的使用
- [fafafa.core.result 使用指南](fafafa.core.result.guide.md) - Result 类型的错误处理
- [API 参考](API_Reference.md) - 完整的 API 文档

## 总结

`fafafa.core.base` 提供了构建类型安全、可维护代码的基础工具：

1. **异常体系**：使用具体的异常类型和详细的错误信息
2. **泛型函数类型**：支持函数式编程模式
3. **元组类型**：简化多返回值场景

遵循本指南的最佳实践，可以编写出清晰、健壮的代码。
