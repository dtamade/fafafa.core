# fafafa.core.result 使用指南

## 概述

`fafafa.core.result` 是 fafafa.core 框架的 Result 类型模块，提供：
- Result<T, E> 类型（Ok/Err）- Rust 风格的错误处理
- 丰富的函数式组合子（Map、MapErr、AndThen、OrElse 等）
- 与 Option 类型的互转
- 避免异常的性能开销和控制流混乱

## 快速入门

### 1. 基础构造和使用

```pascal
uses
  fafafa.core.result;

var
  Res: specialize TResult<Integer, string>;
begin
  // 构造 Ok（成功）
  Res := specialize TResult<Integer, string>.Ok(42);
  WriteLn('IsOk: ', Res.IsOk);        // 输出: True
  WriteLn('Value: ', Res.Unwrap);     // 输出: 42

  // 构造 Err（错误）
  Res := specialize TResult<Integer, string>.Err('Something went wrong');
  WriteLn('IsErr: ', Res.IsErr);      // 输出: True
  WriteLn('Error: ', Res.UnwrapErr);  // 输出: Something went wrong
end;
```

### 2. Map 转换成功值

```pascal
uses
  fafafa.core.result;

function DoubleIt(const N: Integer): Integer;
begin
  Result := N * 2;
end;

var
  Res, Doubled: specialize TResult<Integer, string>;
begin
  Res := specialize TResult<Integer, string>.Ok(21);

  // Map 转换：Ok(21) -> Ok(42)
  Doubled := ResultMap(Res, @DoubleIt);
  WriteLn(Doubled.Unwrap);  // 输出: 42

  // Err 保持不变
  Res := specialize TResult<Integer, string>.Err('Error');
  Doubled := ResultMap(Res, @DoubleIt);
  WriteLn(Doubled.IsErr);  // 输出: True
end;
```

### 3. MapErr 转换错误值

```pascal
uses
  fafafa.core.result;

function FormatError(const Err: string): string;
begin
  Result := 'Error: ' + Err;
end;

var
  Res, Formatted: specialize TResult<Integer, string>;
begin
  // 转换错误信息
  Res := specialize TResult<Integer, string>.Err('File not found');
  Formatted := ResultMapErr(Res, @FormatError);
  WriteLn(Formatted.UnwrapErr);  // 输出: Error: File not found

  // Ok 保持不变
  Res := specialize TResult<Integer, string>.Ok(42);
  Formatted := ResultMapErr(Res, @FormatError);
  WriteLn(Formatted.Unwrap);  // 输出: 42
end;
```

### 4. AndThen 链式操作

```pascal
uses
  fafafa.core.result;

function SafeDivide(const N: Integer): specialize TResult<Integer, string>;
begin
  if N = 0 then
    Exit(specialize TResult<Integer, string>.Err('Division by zero'));
  Result := specialize TResult<Integer, string>.Ok(100 div N);
end;

var
  Res, Divided: specialize TResult<Integer, string>;
begin
  // 成功链式操作
  Res := specialize TResult<Integer, string>.Ok(10);
  Divided := ResultAndThen(Res, @SafeDivide);
  WriteLn(Divided.Unwrap);  // 输出: 10

  // 链式操作返回 Err
  Res := specialize TResult<Integer, string>.Ok(0);
  Divided := ResultAndThen(Res, @SafeDivide);
  WriteLn(Divided.UnwrapErr);  // 输出: Division by zero
end;
```

### 5. Match 模式匹配

```pascal
uses
  fafafa.core.result;

function HandleSuccess(const N: Integer): string;
begin
  Result := 'Success: ' + IntToStr(N);
end;

function HandleError(const Err: string): string;
begin
  Result := 'Failed: ' + Err;
end;

var
  Res: specialize TResult<Integer, string>;
  Message: string;
begin
  // 匹配成功情况
  Res := specialize TResult<Integer, string>.Ok(42);
  Message := ResultMatch(Res, @HandleSuccess, @HandleError);
  WriteLn(Message);  // 输出: Success: 42

  // 匹配错误情况
  Res := specialize TResult<Integer, string>.Err('Network error');
  Message := ResultMatch(Res, @HandleSuccess, @HandleError);
  WriteLn(Message);  // 输出: Failed: Network error
end;
```

## 常见使用场景

### 场景 1: 文件 I/O 错误处理

```pascal
uses
  fafafa.core.result;

type
  TFileError = (feNotFound, fePermissionDenied, feReadError);

function ReadFileContent(const FileName: string): specialize TResult<string, TFileError>;
var
  F: TextFile;
  Line, Content: string;
begin
  if not FileExists(FileName) then
    Exit(specialize TResult<string, TFileError>.Err(feNotFound));

  try
    AssignFile(F, FileName);
    Reset(F);
    try
      Content := '';
      while not Eof(F) do
      begin
        ReadLn(F, Line);
        Content := Content + Line + LineEnding;
      end;
      Result := specialize TResult<string, TFileError>.Ok(Content);
    finally
      CloseFile(F);
    end;
  except
    on E: EInOutError do
      Exit(specialize TResult<string, TFileError>.Err(feReadError));
  end;
end;

// 使用 Match 处理结果
var
  FileResult: specialize TResult<string, TFileError>;
  Content: string;
begin
  FileResult := ReadFileContent('config.txt');
  Content := ResultMatch(
    FileResult,
    function(const S: string): string
    begin
      Result := S;
    end,
    function(const Err: TFileError): string
    begin
      case Err of
        feNotFound: Result := 'File not found';
        fePermissionDenied: Result := 'Permission denied';
        feReadError: Result := 'Read error';
      end;
    end
  );
  WriteLn(Content);
end;
```

### 场景 2: 数据验证链

```pascal
uses
  fafafa.core.result;

type
  TValidationError = string;

// 验证用户名
function ValidateUsername(const Username: string): specialize TResult<string, TValidationError>;
begin
  if Length(Username) < 3 then
    Exit(specialize TResult<string, TValidationError>.Err('Username too short'));
  if Length(Username) > 20 then
    Exit(specialize TResult<string, TValidationError>.Err('Username too long'));
  Result := specialize TResult<string, TValidationError>.Ok(Username);
end;

// 验证邮箱
function ValidateEmail(const Email: string): specialize TResult<string, TValidationError>;
begin
  if Pos('@', Email) = 0 then
    Exit(specialize TResult<string, TValidationError>.Err('Invalid email format'));
  Result := specialize TResult<string, TValidationError>.Ok(Email);
end;

// 验证密码
function ValidatePassword(const Password: string): specialize TResult<string, TValidationError>;
begin
  if Length(Password) < 8 then
    Exit(specialize TResult<string, TValidationError>.Err('Password too short'));
  Result := specialize TResult<string, TValidationError>.Ok(Password);
end;

// 链式验证
type
  TUserData = record
    Username, Email, Password: string;
  end;

function ValidateUserData(const Username, Email, Password: string): specialize TResult<TUserData, TValidationError>;
var
  UserData: TUserData;
begin
  // 链式验证：任何一步失败都会返回错误
  Result := ResultAndThen(
    ValidateUsername(Username),
    function(const U: string): specialize TResult<TUserData, TValidationError>
    begin
      Result := ResultAndThen(
        ValidateEmail(Email),
        function(const E: string): specialize TResult<TUserData, TValidationError>
        begin
          Result := ResultMap(
            ValidatePassword(Password),
            function(const P: string): TUserData
            var
              Data: TUserData;
            begin
              Data.Username := U;
              Data.Email := E;
              Data.Password := P;
              Result := Data;
            end
          );
        end
      );
    end
  );
end;

// 使用示例
var
  ValidationResult: specialize TResult<TUserData, TValidationError>;
begin
  ValidationResult := ValidateUserData('alice', 'alice@example.com', 'password123');
  if ValidationResult.IsOk then
    WriteLn('Validation successful')
  else
    WriteLn('Validation failed: ', ValidationResult.UnwrapErr);
end;
```

### 场景 3: 网络请求错误处理

```pascal
uses
  fafafa.core.result;

type
  THttpError = record
    StatusCode: Integer;
    Message: string;
  end;

  THttpResponse = record
    StatusCode: Integer;
    Body: string;
  end;

function FetchData(const URL: string): specialize TResult<THttpResponse, THttpError>;
var
  Response: THttpResponse;
  Error: THttpError;
begin
  // 模拟 HTTP 请求
  if URL = 'https://api.example.com/data' then
  begin
    Response.StatusCode := 200;
    Response.Body := '{"data": "success"}';
    Exit(specialize TResult<THttpResponse, THttpError>.Ok(Response));
  end;

  if URL = 'https://api.example.com/notfound' then
  begin
    Error.StatusCode := 404;
    Error.Message := 'Not Found';
    Exit(specialize TResult<THttpResponse, THttpError>.Err(Error));
  end;

  Error.StatusCode := 500;
  Error.Message := 'Internal Server Error';
  Result := specialize TResult<THttpResponse, THttpError>.Err(Error);
end;

// 使用 OrElse 提供备用方案
function FetchDataWithFallback(const PrimaryURL, FallbackURL: string): specialize TResult<THttpResponse, THttpError>;
begin
  Result := ResultOrElse(
    FetchData(PrimaryURL),
    function(const Err: THttpError): specialize TResult<THttpResponse, THttpError>
    begin
      WriteLn('Primary failed, trying fallback...');
      Result := FetchData(FallbackURL);
    end
  );
end;

// 使用示例
var
  DataResult: specialize TResult<THttpResponse, THttpError>;
begin
  DataResult := FetchDataWithFallback(
    'https://api.example.com/notfound',
    'https://api.example.com/data'
  );

  if DataResult.IsOk then
    WriteLn('Response: ', DataResult.Unwrap.Body)
  else
    WriteLn('Error: ', DataResult.UnwrapErr.Message);
end;
```

### 场景 4: 数据库操作错误处理

```pascal
uses
  fafafa.core.result;

type
  TDBError = (dbeConnectionFailed, dbeQueryFailed, dbeNoResults);

  TUser = record
    ID: Integer;
    Name: string;
    Email: string;
  end;

function ConnectDatabase: specialize TResult<Boolean, TDBError>;
begin
  // 模拟数据库连接
  if Random(10) > 2 then
    Exit(specialize TResult<Boolean, TDBError>.Ok(True));
  Result := specialize TResult<Boolean, TDBError>.Err(dbeConnectionFailed);
end;

function QueryUser(const UserID: Integer): specialize TResult<TUser, TDBError>;
var
  User: TUser;
begin
  // 模拟数据库查询
  if UserID = 1 then
  begin
    User.ID := 1;
    User.Name := 'Alice';
    User.Email := 'alice@example.com';
    Exit(specialize TResult<TUser, TDBError>.Ok(User));
  end;

  Result := specialize TResult<TUser, TDBError>.Err(dbeNoResults);
end;

// 链式数据库操作
function GetUserEmail(const UserID: Integer): specialize TResult<string, TDBError>;
begin
  Result := ResultAndThen(
    ConnectDatabase,
    function(const Connected: Boolean): specialize TResult<string, TDBError>
    begin
      Result := ResultMap(
        QueryUser(UserID),
        function(const U: TUser): string
        begin
          Result := U.Email;
        end
      );
    end
  );
end;

// 使用示例
var
  EmailResult: specialize TResult<string, TDBError>;
begin
  EmailResult := GetUserEmail(1);
  WriteLn('Email: ', EmailResult.UnwrapOr('no-email@example.com'));
end;
```

### 场景 5: 配置解析错误处理

```pascal
uses
  fafafa.core.result;

type
  TConfigError = string;

  TConfig = record
    Host: string;
    Port: Integer;
    Timeout: Integer;
  end;

function ParsePort(const S: string): specialize TResult<Integer, TConfigError>;
var
  Port, Code: Integer;
begin
  Val(S, Port, Code);
  if Code <> 0 then
    Exit(specialize TResult<Integer, TConfigError>.Err('Invalid port number'));
  if (Port < 1) or (Port > 65535) then
    Exit(specialize TResult<Integer, TConfigError>.Err('Port out of range'));
  Result := specialize TResult<Integer, TConfigError>.Ok(Port);
end;

function ParseTimeout(const S: string): specialize TResult<Integer, TConfigError>;
var
  Timeout, Code: Integer;
begin
  Val(S, Timeout, Code);
  if Code <> 0 then
    Exit(specialize TResult<Integer, TConfigError>.Err('Invalid timeout value'));
  if Timeout < 0 then
    Exit(specialize TResult<Integer, TConfigError>.Err('Timeout cannot be negative'));
  Result := specialize TResult<Integer, TConfigError>.Ok(Timeout);
end;

function LoadConfig(const FileName: string): specialize TResult<TConfig, TConfigError>;
var
  Ini: TIniFile;
  Host, PortStr, TimeoutStr: string;
  Config: TConfig;
begin
  if not FileExists(FileName) then
    Exit(specialize TResult<TConfig, TConfigError>.Err('Config file not found'));

  Ini := TIniFile.Create(FileName);
  try
    Host := Ini.ReadString('Server', 'Host', '');
    if Host = '' then
      Exit(specialize TResult<TConfig, TConfigError>.Err('Host not specified'));

    PortStr := Ini.ReadString('Server', 'Port', '');
    TimeoutStr := Ini.ReadString('Server', 'Timeout', '30');

    // 链式解析配置
    Result := ResultAndThen(
      ParsePort(PortStr),
      function(const Port: Integer): specialize TResult<TConfig, TConfigError>
      begin
        Result := ResultMap(
          ParseTimeout(TimeoutStr),
          function(const Timeout: Integer): TConfig
          var
            Cfg: TConfig;
          begin
            Cfg.Host := Host;
            Cfg.Port := Port;
            Cfg.Timeout := Timeout;
            Result := Cfg;
          end
        );
      end
    );
  finally
    Ini.Free;
  end;
end;

// 使用示例
var
  ConfigResult: specialize TResult<TConfig, TConfigError>;
  Config: TConfig;
begin
  ConfigResult := LoadConfig('app.ini');
  if ConfigResult.IsOk then
  begin
    Config := ConfigResult.Unwrap;
    WriteLn('Host: ', Config.Host);
    WriteLn('Port: ', Config.Port);
    WriteLn('Timeout: ', Config.Timeout);
  end
  else
    WriteLn('Config error: ', ConfigResult.UnwrapErr);
end;
```

## 最佳实践

### 1. 优先使用 Result 而非异常

✅ **推荐做法**：
```pascal
// 使用 Result 表达可能失败的操作
function ParseInt(const S: string): specialize TResult<Integer, string>;
var
  Value, Code: Integer;
begin
  Val(S, Value, Code);
  if Code = 0 then
    Exit(specialize TResult<Integer, string>.Ok(Value));
  Result := specialize TResult<Integer, string>.Err('Invalid integer format');
end;

// 调用者显式处理错误
var
  ParseResult: specialize TResult<Integer, string>;
begin
  ParseResult := ParseInt('123');
  if ParseResult.IsOk then
    WriteLn('Value: ', ParseResult.Unwrap)
  else
    WriteLn('Error: ', ParseResult.UnwrapErr);
end;
```

❌ **避免做法**：
```pascal
// 不要使用异常处理正常的错误情况
function ParseInt(const S: string): Integer;
var
  Value, Code: Integer;
begin
  Val(S, Value, Code);
  if Code <> 0 then
    raise Exception.Create('Invalid integer format');  // 性能开销大
  Result := Value;
end;

// 调用者必须使用 try-except
try
  Value := ParseInt('abc');
except
  on E: Exception do
    WriteLn('Error: ', E.Message);
end;
```

### 2. 使用组合子链式操作

✅ **推荐做法**：
```pascal
// 链式操作，清晰表达数据流
function ProcessUserInput(const Input: string): specialize TResult<string, string>;
begin
  Result := ResultMap(
    ResultAndThen(
      ResultAndThen(
        ParseInt(Input),
        @ValidateRange
      ),
      @CalculateResult
    ),
    @FormatOutput
  );
end;
```

❌ **避免做法**：
```pascal
// 不要使用嵌套 if
function ProcessUserInput(const Input: string): specialize TResult<string, string>;
var
  IntResult: specialize TResult<Integer, string>;
  ValidResult: specialize TResult<Integer, string>;
  CalcResult: specialize TResult<Integer, string>;
begin
  IntResult := ParseInt(Input);
  if IntResult.IsErr then
    Exit(specialize TResult<string, string>.Err(IntResult.UnwrapErr));

  ValidResult := ValidateRange(IntResult.Unwrap);
  if ValidResult.IsErr then
    Exit(specialize TResult<string, string>.Err(ValidResult.UnwrapErr));

  CalcResult := CalculateResult(ValidResult.Unwrap);
  if CalcResult.IsErr then
    Exit(specialize TResult<string, string>.Err(CalcResult.UnwrapErr));

  Result := specialize TResult<string, string>.Ok(FormatOutput(CalcResult.Unwrap));
end;
```

### 3. 使用 Match 统一处理成功和错误

✅ **推荐做法**：
```pascal
// 使用 Match 统一处理
var
  FileResult: specialize TResult<string, TFileError>;
  Message: string;
begin
  FileResult := ReadFile('config.txt');
  Message := ResultMatch(
    FileResult,
    function(const Content: string): string
    begin
      Result := 'File loaded: ' + IntToStr(Length(Content)) + ' bytes';
    end,
    function(const Err: TFileError): string
    begin
      case Err of
        feNotFound: Result := 'File not found';
        fePermissionDenied: Result := 'Permission denied';
        feReadError: Result := 'Read error';
      end;
    end
  );
  WriteLn(Message);
end;
```

❌ **避免做法**：
```pascal
// 不要分别处理成功和错误
var
  FileResult: specialize TResult<string, TFileError>;
begin
  FileResult := ReadFile('config.txt');
  if FileResult.IsOk then
    WriteLn('File loaded: ', Length(FileResult.Unwrap), ' bytes')
  else
  begin
    case FileResult.UnwrapErr of
      feNotFound: WriteLn('File not found');
      fePermissionDenied: WriteLn('Permission denied');
      feReadError: WriteLn('Read error');
    end;
  end;
end;
```

### 4. 使用 OrElse 提供备用方案

✅ **推荐做法**：
```pascal
// 使用 OrElse 提供备用方案
function LoadConfigWithFallback: specialize TResult<TConfig, string>;
begin
  Result := ResultOrElse(
    LoadConfig('config.local.ini'),
    function(const Err: string): specialize TResult<TConfig, string>
    begin
      WriteLn('Local config failed, trying default...');
      Result := LoadConfig('config.default.ini');
    end
  );
end;
```

❌ **避免做法**：
```pascal
// 不要手动检查和重试
function LoadConfigWithFallback: specialize TResult<TConfig, string>;
var
  LocalResult: specialize TResult<TConfig, string>;
begin
  LocalResult := LoadConfig('config.local.ini');
  if LocalResult.IsErr then
  begin
    WriteLn('Local config failed, trying default...');
    Result := LoadConfig('config.default.ini');
  end
  else
    Result := LocalResult;
end;
```

## 常见陷阱和解决方案

### 陷阱 1: 忘记检查 IsOk

❌ **问题代码**：
```pascal
var
  Res: specialize TResult<Integer, string>;
begin
  Res := ParseInt('abc');
  WriteLn(Res.Unwrap);  // 如果是 Err，会抛异常！
end;
```

✅ **解决方案**：
```pascal
var
  Res: specialize TResult<Integer, string>;
begin
  Res := ParseInt('abc');
  if Res.IsOk then
    WriteLn(Res.Unwrap)
  else
    WriteLn('Error: ', Res.UnwrapErr);

  // 或者使用 UnwrapOr
  WriteLn(Res.UnwrapOr(0));
end;
```

### 陷阱 2: 过度使用 Unwrap

❌ **问题代码**：
```pascal
function GetUserAge(const UserID: Integer): Integer;
var
  UserResult: specialize TResult<TUser, string>;
begin
  UserResult := FindUser(UserID);
  Result := UserResult.Unwrap.Age;  // 可能抛异常
end;
```

✅ **解决方案**：
```pascal
function GetUserAge(const UserID: Integer): Integer;
var
  UserResult: specialize TResult<TUser, string>;
begin
  UserResult := FindUser(UserID);
  if UserResult.IsOk then
    Result := UserResult.Unwrap.Age
  else
    Result := 0;  // 默认年龄

  // 或者使用 Map
  Result := ResultMap(
    UserResult,
    function(const U: TUser): Integer
    begin
      Result := U.Age;
    end
  ).UnwrapOr(0);
end;
```

### 陷阱 3: 混淆 Map 和 AndThen

❌ **问题代码**：
```pascal
// 错误：使用 Map 处理返回 Result 的函数
function ProcessInput(const Input: string): specialize TResult<Integer, string>;
begin
  Result := ResultMap(
    ParseInt(Input),
    @SafeDivide  // SafeDivide 返回 Result<Integer, string>，导致嵌套 Result
  );
end;
```

✅ **解决方案**：
```pascal
// 正确：使用 AndThen 处理返回 Result 的函数
function ProcessInput(const Input: string): specialize TResult<Integer, string>;
begin
  Result := ResultAndThen(
    ParseInt(Input),
    @SafeDivide  // AndThen 会自动展平嵌套的 Result
  );
end;
```

### 陷阱 4: 忘记处理 Err 情况

❌ **问题代码**：
```pascal
function CalculateTotal(const Items: array of Integer): Integer;
var
  SumResult: specialize TResult<Integer, string>;
begin
  SumResult := SumItems(Items);
  // 忘记处理 Err 情况
  Result := SumResult.Unwrap;
end;
```

✅ **解决方案**：
```pascal
function CalculateTotal(const Items: array of Integer): Integer;
var
  SumResult: specialize TResult<Integer, string>;
begin
  SumResult := SumItems(Items);
  Result := ResultMatch(
    SumResult,
    function(const Sum: Integer): Integer
    begin
      Result := Sum;
    end,
    function(const Err: string): Integer
    begin
      WriteLn('Error calculating total: ', Err);
      Result := 0;  // 默认值
    end
  );
end;
```

### 陷阱 5: 不必要的 Result 嵌套

❌ **问题代码**：
```pascal
function GetConfig: specialize TResult<specialize TResult<TConfig, string>, string>;
begin
  if FileExists('config.ini') then
  begin
    if ValidConfig then
      Exit(specialize TResult<specialize TResult<TConfig, string>, string>.Ok(
        specialize TResult<TConfig, string>.Ok(LoadConfig)
      ));
  end;
  Result := specialize TResult<specialize TResult<TConfig, string>, string>.Err('Config not found');
end;
```

✅ **解决方案**：
```pascal
function GetConfig: specialize TResult<TConfig, string>;
begin
  if not FileExists('config.ini') then
    Exit(specialize TResult<TConfig, string>.Err('Config file not found'));
  if not ValidConfig then
    Exit(specialize TResult<TConfig, string>.Err('Invalid config'));
  Result := specialize TResult<TConfig, string>.Ok(LoadConfig);
end;
```

## 性能考虑

### 1. Result 性能开销

- **内存开销**：Result<T, E> 比 T 多 1 字节（用于存储 IsOk 标志）+ E 的大小
- **性能开销**：组合子调用有轻微的函数调用开销，但比异常快得多

```pascal
// 性能关键路径：直接检查
if Res.IsOk then
  ProcessValue(Res.GetOkUnchecked);  // 避免双重检查

// 非关键路径：使用组合子
Result := ResultMap(Res, @ProcessValue);
```

### 2. 避免不必要的 Result 构造

✅ **推荐做法**：
```pascal
// 直接返回 Result
function FindValue(const Key: string): specialize TResult<Integer, string>;
begin
  if Map.ContainsKey(Key) then
    Exit(specialize TResult<Integer, string>.Ok(Map[Key]));
  Result := specialize TResult<Integer, string>.Err('Key not found');
end;
```

❌ **避免做法**：
```pascal
// 不要先构造值再包装
function FindValue(const Key: string): specialize TResult<Integer, string>;
var
  Value: Integer;
begin
  if Map.ContainsKey(Key) then
  begin
    Value := Map[Key];
    Exit(specialize TResult<Integer, string>.Ok(Value));  // 不必要的中间变量
  end;
  Result := specialize TResult<Integer, string>.Err('Key not found');
end;
```

### 3. Result vs 异常性能对比

```pascal
// Result: 快速，无栈展开开销
function ParseIntResult(const S: string): specialize TResult<Integer, string>;
begin
  // 返回 Result，性能开销小
end;

// 异常: 慢，有栈展开开销
function ParseIntException(const S: string): Integer;
begin
  // 抛出异常，性能开销大
  raise Exception.Create('Parse error');
end;
```

## 调试和诊断

### 1. 检查 Result 状态

```pascal
procedure DebugResult(const Res: specialize TResult<Integer, string>; const Name: string);
begin
  WriteLn('--- ', Name, ' ---');
  WriteLn('IsOk: ', Res.IsOk);
  WriteLn('IsErr: ', Res.IsErr);
  if Res.IsOk then
    WriteLn('Value: ', Res.Unwrap)
  else
    WriteLn('Error: ', Res.UnwrapErr);
end;

var
  Res: specialize TResult<Integer, string>;
begin
  Res := ParseInt('123');
  DebugResult(Res, 'ParseInt("123")');
end;
```

### 2. 使用 Expect 提供错误信息

```pascal
var
  Res: specialize TResult<Integer, string>;
begin
  Res := ParseInt('abc');
  // Expect 在 Err 时抛出异常，并提供自定义错误信息
  WriteLn(Res.Expect('Failed to parse integer'));
end;
```

### 3. 错误传播追踪

```pascal
function ProcessData(const Input: string): specialize TResult<string, string>;
begin
  Result := ResultAndThen(
    ParseInt(Input),
    function(const N: Integer): specialize TResult<string, string>
    begin
      WriteLn('[DEBUG] Parsed: ', N);
      Result := ResultMap(
        ValidateRange(N),
        function(const V: Integer): string
        begin
          WriteLn('[DEBUG] Validated: ', V);
          Result := FormatOutput(V);
        end
      );
    end
  );
end;
```

## 相关文档

- [fafafa.core.result API 参考](fafafa.core.result.md) - 完整的 API 文档
- [fafafa.core.option 使用指南](fafafa.core.option.guide.md) - Option 类型的使用
- [fafafa.core.base 使用指南](fafafa.core.base.guide.md) - 基础类型和异常

## 总结

`fafafa.core.result` 提供了 Rust 风格的类型安全错误处理：

1. **Result<T, E> 类型**：显式表达操作可能失败，避免异常的性能开销
2. **丰富的组合子**：Map、MapErr、AndThen、OrElse、Match 等函数式操作
3. **与 Option 互转**：无缝集成可选值处理
4. **类型安全**：编译时检查，避免运行时异常

选择合适的组合子，遵循最佳实践，可以编写出清晰、高效、安全的错误处理代码。
