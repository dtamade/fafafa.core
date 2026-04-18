# fafafa.core.option 使用指南

## 概述

`fafafa.core.option` 是 fafafa.core 框架的 Option 类型模块，提供：
- Option<T> 类型（Some/None）- 显式表达"值可能不存在"
- 丰富的函数式组合子（Map、Filter、AndThen、Zip 等）
- 与 Result 类型的互转
- 避免 nil 指针和空值检查的陷阱

## 快速入门

### 1. 基础构造和使用

```pascal
uses
  fafafa.core.option,
  fafafa.core.option.base;

var
  Opt: specialize TOption<Integer>;
begin
  // 构造 Some（包含值）
  Opt := specialize TOption<Integer>.Some(42);
  WriteLn('IsSome: ', Opt.IsSome);      // 输出: True
  WriteLn('Value: ', Opt.Unwrap);       // 输出: 42

  // 构造 None（不包含值）
  Opt := specialize TOption<Integer>.None;
  WriteLn('IsNone: ', Opt.IsNone);      // 输出: True
  WriteLn('Default: ', Opt.UnwrapOr(0)); // 输出: 0（提供默认值）
end;
```

### 2. Map 转换

```pascal
uses
  fafafa.core.option;

function DoubleIt(const N: Integer): Integer;
begin
  Result := N * 2;
end;

var
  Opt, Doubled: specialize TOption<Integer>;
begin
  Opt := specialize TOption<Integer>.Some(21);

  // Map 转换：Some(21) -> Some(42)
  Doubled := OptionMap(Opt, @DoubleIt);
  WriteLn(Doubled.Unwrap);  // 输出: 42

  // None 保持不变
  Opt := specialize TOption<Integer>.None;
  Doubled := OptionMap(Opt, @DoubleIt);
  WriteLn(Doubled.IsNone);  // 输出: True
end;
```

### 3. Filter 过滤

```pascal
uses
  fafafa.core.option;

function IsEven(const N: Integer): Boolean;
begin
  Result := (N mod 2) = 0;
end;

var
  Opt, Filtered: specialize TOption<Integer>;
begin
  // 满足条件：保留值
  Opt := specialize TOption<Integer>.Some(42);
  Filtered := OptionFilter(Opt, @IsEven);
  WriteLn(Filtered.IsSome);  // 输出: True

  // 不满足条件：返回 None
  Opt := specialize TOption<Integer>.Some(43);
  Filtered := OptionFilter(Opt, @IsEven);
  WriteLn(Filtered.IsNone);  // 输出: True
end;
```

### 4. AndThen 链式操作

```pascal
uses
  fafafa.core.option;

function SafeDivide(const N: Integer): specialize TOption<Integer>;
begin
  if N = 0 then
    Exit(specialize TOption<Integer>.None);
  Result := specialize TOption<Integer>.Some(100 div N);
end;

var
  Opt, Divided: specialize TOption<Integer>;
begin
  // 成功链式操作
  Opt := specialize TOption<Integer>.Some(10);
  Divided := OptionAndThen(Opt, @SafeDivide);
  WriteLn(Divided.Unwrap);  // 输出: 10

  // 链式操作返回 None
  Opt := specialize TOption<Integer>.Some(0);
  Divided := OptionAndThen(Opt, @SafeDivide);
  WriteLn(Divided.IsNone);  // 输出: True
end;
```

### 5. 与 Result 互转

```pascal
uses
  fafafa.core.option,
  fafafa.core.result;

var
  Opt: specialize TOption<Integer>;
  Res: specialize TResult<Integer, string>;
begin
  // Option -> Result
  Opt := specialize TOption<Integer>.Some(42);
  Res := OptionToResult(Opt, 'Value not found');
  WriteLn('IsOk: ', Res.IsOk);        // 输出: True
  WriteLn('Value: ', Res.Unwrap);     // 输出: 42

  // None -> Err
  Opt := specialize TOption<Integer>.None;
  Res := OptionToResult(Opt, 'Value not found');
  WriteLn('IsErr: ', Res.IsErr);      // 输出: True
  WriteLn('Error: ', Res.UnwrapErr);  // 输出: Value not found
end;
```

## 常见使用场景

### 场景 1: 配置解析（可选配置项）

```pascal
uses
  fafafa.core.option,
  fafafa.core.ini;

type
  TConfig = record
    Host: string;
    Port: Integer;
    Timeout: specialize TOption<Integer>;  // 可选超时配置
    MaxRetries: specialize TOption<Integer>;  // 可选重试次数
  end;

function LoadConfig(const FileName: string): TConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try
    Result.Host := Ini.ReadString('Server', 'Host', 'localhost');
    Result.Port := Ini.ReadInteger('Server', 'Port', 8080);

    // 可选配置：如果存在则读取，否则为 None
    if Ini.ValueExists('Server', 'Timeout') then
      Result.Timeout := specialize TOption<Integer>.Some(Ini.ReadInteger('Server', 'Timeout', 0))
    else
      Result.Timeout := specialize TOption<Integer>.None;

    if Ini.ValueExists('Server', 'MaxRetries') then
      Result.MaxRetries := specialize TOption<Integer>.Some(Ini.ReadInteger('Server', 'MaxRetries', 0))
    else
      Result.MaxRetries := specialize TOption<Integer>.None;
  finally
    Ini.Free;
  end;
end;

// 使用配置
var
  Config: TConfig;
  Timeout: Integer;
begin
  Config := LoadConfig('app.ini');

  // 使用 UnwrapOr 提供默认值
  Timeout := Config.Timeout.UnwrapOr(30);
  WriteLn('Timeout: ', Timeout);  // 如果配置不存在，使用默认值 30
end;
```

### 场景 2: 数据库查询（可能不存在的记录）

```pascal
uses
  fafafa.core.option;

type
  TUser = record
    ID: Integer;
    Name: string;
    Email: string;
  end;

function FindUserByID(const UserID: Integer): specialize TOption<TUser>;
var
  User: TUser;
begin
  // 模拟数据库查询
  if UserID = 1 then
  begin
    User.ID := 1;
    User.Name := 'Alice';
    User.Email := 'alice@example.com';
    Exit(specialize TOption<TUser>.Some(User));
  end;

  // 用户不存在
  Result := specialize TOption<TUser>.None;
end;

// 使用 Map 转换
function GetUserEmail(const UserID: Integer): specialize TOption<string>;
begin
  Result := OptionMap(
    FindUserByID(UserID),
    function(const U: TUser): string
    begin
      Result := U.Email;
    end
  );
end;

// 使用示例
var
  UserOpt: specialize TOption<TUser>;
  EmailOpt: specialize TOption<string>;
begin
  UserOpt := FindUserByID(1);
  if UserOpt.IsSome then
    WriteLn('Found user: ', UserOpt.Unwrap.Name)
  else
    WriteLn('User not found');

  // 链式操作
  EmailOpt := GetUserEmail(1);
  WriteLn('Email: ', EmailOpt.UnwrapOr('no-email@example.com'));
end;
```

### 场景 3: API 调用（可能失败的操作）

```pascal
uses
  fafafa.core.option,
  fafafa.core.result;

type
  TApiResponse = record
    StatusCode: Integer;
    Body: string;
  end;

// API 调用可能失败，返回 Result
function CallAPI(const URL: string): specialize TResult<TApiResponse, string>;
var
  Response: TApiResponse;
begin
  // 模拟 API 调用
  if URL = 'https://api.example.com/data' then
  begin
    Response.StatusCode := 200;
    Response.Body := '{"data": "success"}';
    Exit(specialize TResult<TApiResponse, string>.Ok(Response));
  end;

  Result := specialize TResult<TApiResponse, string>.Err('Network error');
end;

// 提取响应体（如果成功）
function GetResponseBody(const URL: string): specialize TOption<string>;
var
  ApiResult: specialize TResult<TApiResponse, string>;
begin
  ApiResult := CallAPI(URL);
  // Result -> Option 转换
  Result := OptionMap(
    ResultToOption(ApiResult),
    function(const R: TApiResponse): string
    begin
      Result := R.Body;
    end
  );
end;

// 使用示例
var
  BodyOpt: specialize TOption<string>;
begin
  BodyOpt := GetResponseBody('https://api.example.com/data');
  if BodyOpt.IsSome then
    WriteLn('Response: ', BodyOpt.Unwrap)
  else
    WriteLn('API call failed');
end;
```

### 场景 4: 链式操作（多步骤可能失败）

```pascal
uses
  fafafa.core.option;

// 解析整数
function ParseInt(const S: string): specialize TOption<Integer>;
var
  Value, Code: Integer;
begin
  Val(S, Value, Code);
  if Code = 0 then
    Exit(specialize TOption<Integer>.Some(Value));
  Result := specialize TOption<Integer>.None;
end;

// 验证范围
function ValidateRange(const N: Integer): specialize TOption<Integer>;
begin
  if (N >= 0) and (N <= 100) then
    Exit(specialize TOption<Integer>.Some(N));
  Result := specialize TOption<Integer>.None;
end;

// 链式操作：解析 -> 验证 -> 转换
function ProcessInput(const Input: string): specialize TOption<string>;
begin
  Result := OptionMap(
    OptionAndThen(
      OptionAndThen(
        ParseInt(Input),
        @ValidateRange
      ),
      function(const N: Integer): specialize TOption<Integer>
      begin
        Result := specialize TOption<Integer>.Some(N * 2);
      end
    ),
    function(const N: Integer): string
    begin
      Result := IntToStr(N);
    end
  );
end;

// 使用示例
var
  ResultOpt: specialize TOption<string>;
begin
  ResultOpt := ProcessInput('42');
  WriteLn(ResultOpt.UnwrapOr('Invalid input'));  // 输出: 84

  ResultOpt := ProcessInput('150');
  WriteLn(ResultOpt.UnwrapOr('Invalid input'));  // 输出: Invalid input（超出范围）

  ResultOpt := ProcessInput('abc');
  WriteLn(ResultOpt.UnwrapOr('Invalid input'));  // 输出: Invalid input（解析失败）
end;
```

### 场景 5: Zip 组合多个 Option

```pascal
uses
  fafafa.core.option,
  fafafa.core.base;

type
  TPoint = record
    X, Y: Integer;
  end;

function GetX: specialize TOption<Integer>;
begin
  Result := specialize TOption<Integer>.Some(10);
end;

function GetY: specialize TOption<Integer>;
begin
  Result := specialize TOption<Integer>.Some(20);
end;

// 组合两个 Option 为 Point
function CreatePoint: specialize TOption<TPoint>;
var
  XOpt, YOpt: specialize TOption<Integer>;
  ZippedOpt: specialize TOption<specialize TTuple2<Integer, Integer>>;
begin
  XOpt := GetX;
  YOpt := GetY;

  // Zip 两个 Option
  ZippedOpt := OptionZip(XOpt, YOpt);

  // 转换为 Point
  Result := OptionMap(
    ZippedOpt,
    function(const Tuple: specialize TTuple2<Integer, Integer>): TPoint
    var
      P: TPoint;
    begin
      P.X := Tuple.First;
      P.Y := Tuple.Second;
      Result := P;
    end
  );
end;

// 使用 ZipWith 直接组合
function CreatePointZipWith: specialize TOption<TPoint>;
begin
  Result := OptionZipWith(
    GetX,
    GetY,
    function(const Tuple: specialize TTuple2<Integer, Integer>): TPoint
    var
      P: TPoint;
    begin
      P.X := Tuple.First;
      P.Y := Tuple.Second;
      Result := P;
    end
  );
end;

// 使用示例
var
  PointOpt: specialize TOption<TPoint>;
  P: TPoint;
begin
  PointOpt := CreatePoint;
  if PointOpt.IsSome then
  begin
    P := PointOpt.Unwrap;
    WriteLn('Point: (', P.X, ', ', P.Y, ')');
  end;
end;
```

## 最佳实践

### 1. 优先使用 Option 而非 nil

✅ **推荐做法**：
```pascal
// 使用 Option 表达"可能不存在"
function FindUser(const ID: Integer): specialize TOption<TUser>;
begin
  if UserExists(ID) then
    Exit(specialize TOption<TUser>.Some(GetUser(ID)));
  Result := specialize TOption<TUser>.None;
end;

// 使用 UnwrapOr 提供默认值
var
  User: TUser;
begin
  User := FindUser(123).UnwrapOr(DefaultUser);
end;
```

❌ **避免做法**：
```pascal
// 不要使用 nil 指针
function FindUser(const ID: Integer): PUser;
begin
  if UserExists(ID) then
    Exit(@Users[ID]);
  Result := nil;  // 容易导致空指针异常
end;

// 不要忘记检查 nil
var
  User: PUser;
begin
  User := FindUser(123);
  WriteLn(User^.Name);  // 可能崩溃！
end;
```

### 2. 使用组合子链式操作

✅ **推荐做法**：
```pascal
// 链式操作，避免嵌套 if
function ProcessUserInput(const Input: string): specialize TOption<string>;
begin
  Result := OptionMap(
    OptionFilter(
      OptionAndThen(ParseInt(Input), @ValidateRange),
      @IsEven
    ),
    @FormatOutput
  );
end;
```

❌ **避免做法**：
```pascal
// 不要使用嵌套 if
function ProcessUserInput(const Input: string): specialize TOption<string>;
var
  IntOpt: specialize TOption<Integer>;
  ValidOpt: specialize TOption<Integer>;
begin
  IntOpt := ParseInt(Input);
  if IntOpt.IsSome then
  begin
    ValidOpt := ValidateRange(IntOpt.Unwrap);
    if ValidOpt.IsSome then
    begin
      if IsEven(ValidOpt.Unwrap) then
        Exit(specialize TOption<string>.Some(FormatOutput(ValidOpt.Unwrap)));
    end;
  end;
  Result := specialize TOption<string>.None;
end;
```

### 3. 使用 UnwrapOr 避免异常

✅ **推荐做法**：
```pascal
// 使用 UnwrapOr 提供默认值
var
  Config: TConfig;
  Timeout: Integer;
begin
  Config := LoadConfig('app.ini');
  Timeout := Config.Timeout.UnwrapOr(30);  // 安全，不会抛异常
  WriteLn('Timeout: ', Timeout);
end;
```

❌ **避免做法**：
```pascal
// 不要直接 Unwrap（可能抛异常）
var
  Config: TConfig;
  Timeout: Integer;
begin
  Config := LoadConfig('app.ini');
  Timeout := Config.Timeout.Unwrap;  // 如果是 None，会抛异常！
  WriteLn('Timeout: ', Timeout);
end;
```

### 4. 使用 AndThen 处理可能失败的操作链

✅ **推荐做法**：
```pascal
// 使用 AndThen 链式处理
function ProcessData(const Input: string): specialize TOption<TResult>;
begin
  Result := OptionAndThen(
    OptionAndThen(
      ParseJson(Input),
      @ValidateSchema
    ),
    @TransformData
  );
end;
```

❌ **避免做法**：
```pascal
// 不要手动检查每一步
function ProcessData(const Input: string): specialize TOption<TResult>;
var
  JsonOpt: specialize TOption<TJson>;
  ValidOpt: specialize TOption<TJson>;
begin
  JsonOpt := ParseJson(Input);
  if JsonOpt.IsNone then
    Exit(specialize TOption<TResult>.None);

  ValidOpt := ValidateSchema(JsonOpt.Unwrap);
  if ValidOpt.IsNone then
    Exit(specialize TOption<TResult>.None);

  Result := TransformData(ValidOpt.Unwrap);
end;
```

## 常见陷阱和解决方案

### 陷阱 1: 忘记检查 IsSome

❌ **问题代码**：
```pascal
var
  Opt: specialize TOption<Integer>;
begin
  Opt := FindValue(42);
  WriteLn(Opt.Unwrap);  // 如果是 None，会抛异常！
end;
```

✅ **解决方案**：
```pascal
var
  Opt: specialize TOption<Integer>;
begin
  Opt := FindValue(42);
  if Opt.IsSome then
    WriteLn(Opt.Unwrap)
  else
    WriteLn('Value not found');

  // 或者使用 UnwrapOr
  WriteLn(Opt.UnwrapOr(0));
end;
```

### 陷阱 2: 过度使用 Unwrap

❌ **问题代码**：
```pascal
function GetUserName(const UserID: Integer): string;
var
  UserOpt: specialize TOption<TUser>;
begin
  UserOpt := FindUser(UserID);
  Result := UserOpt.Unwrap.Name;  // 可能抛异常
end;
```

✅ **解决方案**：
```pascal
function GetUserName(const UserID: Integer): string;
var
  UserOpt: specialize TOption<TUser>;
begin
  UserOpt := FindUser(UserID);
  if UserOpt.IsSome then
    Result := UserOpt.Unwrap.Name
  else
    Result := 'Unknown';

  // 或者使用 Map
  Result := OptionMap(
    UserOpt,
    function(const U: TUser): string
    begin
      Result := U.Name;
    end
  ).UnwrapOr('Unknown');
end;
```

### 陷阱 3: 混淆 Map 和 AndThen

❌ **问题代码**：
```pascal
// 错误：使用 Map 处理返回 Option 的函数
function ProcessInput(const Input: string): specialize TOption<Integer>;
begin
  Result := OptionMap(
    ParseInt(Input),
    @SafeDivide  // SafeDivide 返回 Option<Integer>，导致嵌套 Option
  );
end;
```

✅ **解决方案**：
```pascal
// 正确：使用 AndThen 处理返回 Option 的函数
function ProcessInput(const Input: string): specialize TOption<Integer>;
begin
  Result := OptionAndThen(
    ParseInt(Input),
    @SafeDivide  // AndThen 会自动展平嵌套的 Option
  );
end;
```

### 陷阱 4: 忘记处理 None 情况

❌ **问题代码**：
```pascal
function CalculateDiscount(const UserID: Integer): Double;
var
  UserOpt: specialize TOption<TUser>;
begin
  UserOpt := FindUser(UserID);
  // 忘记处理 None 情况
  Result := UserOpt.Unwrap.DiscountRate * 100;
end;
```

✅ **解决方案**：
```pascal
function CalculateDiscount(const UserID: Integer): Double;
var
  UserOpt: specialize TOption<TUser>;
begin
  UserOpt := FindUser(UserID);
  Result := OptionMap(
    UserOpt,
    function(const U: TUser): Double
    begin
      Result := U.DiscountRate * 100;
    end
  ).UnwrapOr(0.0);  // 默认折扣为 0
end;
```

### 陷阱 5: 不必要的 Option 嵌套

❌ **问题代码**：
```pascal
function GetConfig: specialize TOption<specialize TOption<TConfig>>;
begin
  if FileExists('config.ini') then
  begin
    if ValidConfig then
      Exit(specialize TOption<specialize TOption<TConfig>>.Some(
        specialize TOption<TConfig>.Some(LoadConfig)
      ));
  end;
  Result := specialize TOption<specialize TOption<TConfig>>.None;
end;
```

✅ **解决方案**：
```pascal
function GetConfig: specialize TOption<TConfig>;
begin
  if FileExists('config.ini') and ValidConfig then
    Exit(specialize TOption<TConfig>.Some(LoadConfig));
  Result := specialize TOption<TConfig>.None;
end;

// 如果确实需要嵌套，使用 Flatten
var
  NestedOpt: specialize TOption<specialize TOption<TConfig>>;
  FlatOpt: specialize TOption<TConfig>;
begin
  NestedOpt := GetNestedConfig;
  FlatOpt := OptionFlatten(NestedOpt);
end;
```

## 性能考虑

### 1. Option 性能开销

- **内存开销**：Option<T> 比 T 多 1 字节（用于存储 IsSome 标志）
- **性能开销**：组合子调用有轻微的函数调用开销，但通常可以忽略

```pascal
// 性能关键路径：直接检查
if Opt.IsSome then
  ProcessValue(Opt.GetValueUnchecked);  // 避免双重检查

// 非关键路径：使用组合子
Result := OptionMap(Opt, @ProcessValue);
```

### 2. 避免不必要的 Option 构造

✅ **推荐做法**：
```pascal
// 直接返回 Option
function FindValue(const Key: string): specialize TOption<Integer>;
begin
  if Map.ContainsKey(Key) then
    Exit(specialize TOption<Integer>.Some(Map[Key]));
  Result := specialize TOption<Integer>.None;
end;
```

❌ **避免做法**：
```pascal
// 不要先构造值再包装
function FindValue(const Key: string): specialize TOption<Integer>;
var
  Value: Integer;
begin
  if Map.ContainsKey(Key) then
  begin
    Value := Map[Key];
    Exit(specialize TOption<Integer>.Some(Value));  // 不必要的中间变量
  end;
  Result := specialize TOption<Integer>.None;
end;
```

## 调试和诊断

### 1. 检查 Option 状态

```pascal
procedure DebugOption(const Opt: specialize TOption<Integer>; const Name: string);
begin
  WriteLn('--- ', Name, ' ---');
  WriteLn('IsSome: ', Opt.IsSome);
  WriteLn('IsNone: ', Opt.IsNone);
  if Opt.IsSome then
    WriteLn('Value: ', Opt.Unwrap)
  else
    WriteLn('Value: None');
end;

var
  Opt: specialize TOption<Integer>;
begin
  Opt := FindValue(42);
  DebugOption(Opt, 'FindValue(42)');
end;
```

### 2. 使用 Expect 提供错误信息

```pascal
var
  Opt: specialize TOption<Integer>;
begin
  Opt := FindValue(42);
  // Expect 在 None 时抛出异常，并提供自定义错误信息
  WriteLn(Opt.Expect('Value 42 not found in map'));
end;
```

## 相关文档

- [fafafa.core.option API 参考](fafafa.core.option.md) - 完整的 API 文档
- [fafafa.core.result 使用指南](fafafa.core.result.guide.md) - Result 类型的错误处理
- [fafafa.core.base 使用指南](fafafa.core.base.guide.md) - 基础类型和异常

## 总结

`fafafa.core.option` 提供了类型安全的"可能不存在"值表达：

1. **Option<T> 类型**：显式表达值可能不存在，避免 nil 指针
2. **丰富的组合子**：Map、Filter、AndThen、Zip 等函数式操作
3. **与 Result 互转**：无缝集成错误处理
4. **类型安全**：编译时检查，避免运行时空指针异常

选择合适的组合子，遵循最佳实践，可以编写出清晰、安全的函数式代码。
