# fafafa.core.math 使用指南

## 概述

`fafafa.core.math` 是 fafafa.core 框架的数学运算模块，提供：
- 基础数学函数（Abs, Min, Max, Floor, Ceil, Sqrt 等）
- 安全整数运算（SafeInt）- 防止溢出/下溢
- 浮点数工具函数
- 三角函数和对数函数
- 跨平台数学运算支持

## 快速入门

### 1. 基础数学函数

```pascal
uses
  fafafa.core.math;

var
  X, Y, Result: Double;
begin
  X := -42.7;
  Y := 10.3;

  // 绝对值
  WriteLn(Abs(X));           // 输出: 42.7

  // 最小值/最大值
  WriteLn(Min(X, Y));        // 输出: -42.7
  WriteLn(Max(X, Y));        // 输出: 10.3

  // 夹紧到范围
  Result := Clamp(X, 0, 100);  // 输出: 0

  // 取整函数
  WriteLn(Floor(X));         // 输出: -43
  WriteLn(Ceil(X));          // 输出: -42
  WriteLn(Round(X));         // 输出: -43
  WriteLn(Trunc(X));         // 输出: -42

  // 平方根和平方
  WriteLn(Sqrt(16.0));       // 输出: 4.0
  WriteLn(Sqr(4.0));         // 输出: 16.0
end;
```

### 2. 安全整数运算 - Saturating（饱和）

```pascal
uses
  fafafa.core.math;

var
  A, B, Result: UInt32;
begin
  A := MAX_UINT32 - 10;
  B := 20;

  // 饱和加法：溢出时返回最大值
  Result := SaturatingAdd(A, B);
  WriteLn(Result);  // 输出: MAX_UINT32 (不会溢出)

  // 饱和减法：下溢时返回 0
  Result := SaturatingSub(10, 20);
  WriteLn(Result);  // 输出: 0 (不会下溢)

  // 饱和乘法
  Result := SaturatingMul(MAX_UINT32 div 2, 3);
  WriteLn(Result);  // 输出: MAX_UINT32 (不会溢出)
end;
```

### 3. 安全整数运算 - Checked（检查）

```pascal
uses
  fafafa.core.math,
  fafafa.core.math.base;

var
  A, B: UInt32;
  Result: TOptionalU32;
begin
  A := MAX_UINT32;
  B := 1;

  // 检查加法：溢出时返回 None
  Result := CheckedAddU32(A, B);
  if Result.IsSome then
    WriteLn('Result: ', Result.Value)
  else
    WriteLn('Overflow detected!');  // 输出这个

  // 检查除法：除零时返回 None
  Result := CheckedDivU32(10, 0);
  if Result.IsNone then
    WriteLn('Division by zero!');  // 输出这个
end;
```

### 4. 安全整数运算 - Overflowing（溢出标记）

```pascal
uses
  fafafa.core.math,
  fafafa.core.math.base;

var
  A, B: UInt32;
  Result: TOverflowU32;
begin
  A := MAX_UINT32;
  B := 1;

  // 溢出加法：返回结果和溢出标志
  Result := OverflowingAddU32(A, B);
  WriteLn('Value: ', Result.Value);        // 输出: 0 (环绕结果)
  WriteLn('Overflowed: ', Result.Overflowed);  // 输出: True

  // 可以根据溢出标志采取行动
  if Result.Overflowed then
    WriteLn('Warning: Overflow occurred!');
end;
```

### 5. 安全整数运算 - Wrapping（环绕）

```pascal
uses
  fafafa.core.math;

var
  A, B, Result: UInt32;
begin
  A := MAX_UINT32;
  B := 1;

  // 环绕加法：允许溢出环绕
  Result := WrappingAddU32(A, B);
  WriteLn(Result);  // 输出: 0 (环绕到 0)

  // 环绕乘法（用于哈希计算）
  Result := WrappingMulU32(A, 31);
  WriteLn(Result);  // 输出: 环绕后的结果
end;
```

## 常见使用场景

### 场景 1: 图形处理（使用 Saturating）

```pascal
type
  TColor = record
    R, G, B: Byte;
  end;

function AdjustBrightness(const Color: TColor; Delta: Integer): TColor;
begin
  // 使用饱和运算确保颜色值在 0-255 范围内
  Result.R := SaturatingAdd(Color.R, Byte(Delta));
  Result.G := SaturatingAdd(Color.G, Byte(Delta));
  Result.B := SaturatingAdd(Color.B, Byte(Delta));
end;

var
  Color: TColor;
begin
  Color.R := 200;
  Color.G := 150;
  Color.B := 100;

  // 增加亮度 100
  Color := AdjustBrightness(Color, 100);
  WriteLn('R: ', Color.R);  // 输出: 255 (饱和到最大值)
  WriteLn('G: ', Color.G);  // 输出: 250
  WriteLn('B: ', Color.B);  // 输出: 200
end;
```

### 场景 2: 金融计算（使用 Checked）

```pascal
uses
  fafafa.core.math,
  fafafa.core.math.base;

type
  TAccount = record
    Balance: Int64;  // 以分为单位
  end;

function Deposit(var Account: TAccount; Amount: Int64): Boolean;
var
  NewBalance: TOptionalI64;
begin
  // 使用检查运算防止余额溢出
  NewBalance := CheckedAddI64(Account.Balance, Amount);
  if NewBalance.IsSome then
  begin
    Account.Balance := NewBalance.Value;
    Result := True;
  end
  else
  begin
    WriteLn('Error: Balance overflow!');
    Result := False;
  end;
end;

var
  Account: TAccount;
begin
  Account.Balance := 1000000;  // $10,000.00

  if Deposit(Account, 500000) then
    WriteLn('Deposit successful. New balance: $', Account.Balance / 100:0:2);
end;
```

### 场景 3: 哈希计算（使用 Wrapping）

```pascal
uses
  fafafa.core.math;

function SimpleHash(const S: string): UInt32;
var
  I: Integer;
  Hash: UInt32;
begin
  Hash := 0;
  for I := 1 to Length(S) do
  begin
    // 使用环绕运算实现哈希算法
    Hash := WrappingMulU32(Hash, 31);
    Hash := WrappingAddU32(Hash, Ord(S[I]));
  end;
  Result := Hash;
end;

var
  Hash: UInt32;
begin
  Hash := SimpleHash('Hello, World!');
  WriteLn('Hash: ', Hash);
end;
```

### 场景 4: 数值范围验证

```pascal
uses
  fafafa.core.math;

function ValidateAge(Age: Integer): Boolean;
begin
  // 使用 EnsureRange 确保年龄在有效范围内
  Age := EnsureRange(Age, 0, 150);
  Result := (Age >= 0) and (Age <= 150);
end;

function NormalizePercentage(Value: Double): Double;
begin
  // 夹紧到 0-100 范围
  Result := Clamp(Value, 0.0, 100.0);
end;

var
  Age: Integer;
  Percentage: Double;
begin
  Age := -5;
  Age := EnsureRange(Age, 0, 150);
  WriteLn('Normalized age: ', Age);  // 输出: 0

  Percentage := 150.5;
  Percentage := NormalizePercentage(Percentage);
  WriteLn('Normalized percentage: ', Percentage:0:1);  // 输出: 100.0
end;
```

### 场景 5: 溢出检测和日志记录

```pascal
uses
  fafafa.core.math,
  fafafa.core.math.base;

procedure SafeMultiply(A, B: UInt32);
var
  Result: TOverflowU32;
begin
  Result := OverflowingMulU32(A, B);

  if Result.Overflowed then
  begin
    WriteLn('Warning: Multiplication overflow detected!');
    WriteLn('  A: ', A);
    WriteLn('  B: ', B);
    WriteLn('  Wrapped result: ', Result.Value);
    // 记录到日志系统...
  end
  else
    WriteLn('Result: ', Result.Value);
end;

begin
  SafeMultiply(1000000, 5000);  // 正常
  SafeMultiply(MAX_UINT32 div 2, 3);  // 溢出
end;
```

## 最佳实践

### 1. 选择合适的安全运算策略

✅ **推荐做法**：
```pascal
// 图形/音频处理 -> Saturating
Color := SaturatingAdd(Color, Delta);

// 金融/关键计算 -> Checked
Result := CheckedAddI64(Balance, Amount);
if Result.IsNone then
  raise EOverflow.Create('Balance overflow');

// 需要知道是否溢出 -> Overflowing
Overflow := OverflowingMulU32(A, B);
if Overflow.Overflowed then
  LogWarning('Overflow detected');

// 哈希/循环计数 -> Wrapping
Hash := WrappingMulU32(Hash, 31);
```

❌ **避免做法**：
```pascal
// 不要在金融计算中使用 Wrapping
Balance := WrappingAddI64(Balance, Amount);  // 危险！可能环绕

// 不要在哈希计算中使用 Checked
Result := CheckedMulU32(Hash, 31);  // 不必要的开销
```

### 2. 溢出检查的性能考虑

✅ **推荐做法**：
```pascal
// 性能关键路径：使用 Saturating 或 Wrapping
for I := 1 to 1000000 do
  Sum := SaturatingAdd(Sum, Values[I]);  // 快速

// 非关键路径：使用 Checked 确保安全
Result := CheckedAddI64(TotalRevenue, NewSale);
if Result.IsNone then
  HandleOverflow;
```

❌ **避免做法**：
```pascal
// 不要在性能关键路径使用 Checked
for I := 1 to 1000000 do
begin
  Result := CheckedAddU32(Sum, Values[I]);  // 每次都检查，性能差
  if Result.IsSome then
    Sum := Result.Value;
end;
```

### 3. 浮点数比较

✅ **推荐做法**：
```pascal
const
  EPSILON = 1e-9;

function FloatEquals(A, B: Double): Boolean;
begin
  Result := Abs(A - B) < EPSILON;
end;

var
  X, Y: Double;
begin
  X := 0.1 + 0.2;
  Y := 0.3;

  if FloatEquals(X, Y) then
    WriteLn('Equal (within epsilon)');
end;
```

❌ **避免做法**：
```pascal
// 不要直接比较浮点数
if X = Y then  // 可能因为精度问题失败
  WriteLn('Equal');
```

### 4. 数学函数的边界情况

✅ **推荐做法**：
```pascal
function SafeSqrt(X: Double): Double;
begin
  if X < 0 then
    raise EInvalidArgument.Create('Cannot take square root of negative number');
  Result := Sqrt(X);
end;

function SafeDivide(A, B: Double): Double;
begin
  if Abs(B) < 1e-9 then
    raise EInvalidArgument.Create('Division by zero');
  Result := A / B;
end;
```

❌ **避免做法**：
```pascal
// 不要忽略边界情况
Result := Sqrt(X);  // X 可能为负数
Result := A / B;    // B 可能为 0
```

## 常见陷阱和解决方案

### 陷阱 1: 整数溢出未检测

❌ **问题代码**：
```pascal
var
  A, B, Sum: UInt32;
begin
  A := MAX_UINT32 - 10;
  B := 20;
  Sum := A + B;  // 溢出！Sum = 9
  WriteLn(Sum);
end;
```

✅ **解决方案**：
```pascal
var
  A, B: UInt32;
  Sum: TOptionalU32;
begin
  A := MAX_UINT32 - 10;
  B := 20;

  Sum := CheckedAddU32(A, B);
  if Sum.IsSome then
    WriteLn('Sum: ', Sum.Value)
  else
    WriteLn('Overflow detected!');
end;
```

### 陷阱 2: 浮点数精度问题

❌ **问题代码**：
```pascal
var
  X: Double;
begin
  X := 0.1 + 0.2;
  if X = 0.3 then  // 可能失败！
    WriteLn('Equal');
end;
```

✅ **解决方案**：
```pascal
const
  EPSILON = 1e-9;

var
  X: Double;
begin
  X := 0.1 + 0.2;
  if Abs(X - 0.3) < EPSILON then
    WriteLn('Equal (within epsilon)');
end;
```

### 陷阱 3: 除零错误

❌ **问题代码**：
```pascal
function Average(const Values: array of Integer): Double;
var
  I, Sum: Integer;
begin
  Sum := 0;
  for I := 0 to High(Values) do
    Sum := Sum + Values[I];
  Result := Sum / Length(Values);  // Length 可能为 0！
end;
```

✅ **解决方案**：
```pascal
function Average(const Values: array of Integer): Double;
var
  I, Sum: Integer;
begin
  if Length(Values) = 0 then
    raise EInvalidArgument.Create('Cannot calculate average of empty array');

  Sum := 0;
  for I := 0 to High(Values) do
    Sum := Sum + Values[I];
  Result := Sum / Length(Values);
end;
```

### 陷阱 4: 混用不同的安全运算策略

❌ **问题代码**：
```pascal
var
  A, B, C: UInt32;
begin
  A := SaturatingAdd(X, Y);
  B := WrappingAdd(A, Z);  // 混用策略，语义不清
  C := CheckedAdd(B, W).Value;  // 可能崩溃
end;
```

✅ **解决方案**：
```pascal
var
  A, B, C: UInt32;
begin
  // 统一使用 Saturating 策略
  A := SaturatingAdd(X, Y);
  B := SaturatingAdd(A, Z);
  C := SaturatingAdd(B, W);
end;
```

### 陷阱 5: 忽略 NaN 和 Infinity

❌ **问题代码**：
```pascal
var
  X, Y: Double;
begin
  X := 0.0 / 0.0;  // NaN
  Y := 1.0 / 0.0;  // Infinity

  if X > 0 then  // NaN 比较总是 False
    WriteLn('Positive');
end;
```

✅ **解决方案**：
```pascal
var
  X, Y: Double;
begin
  X := 0.0 / 0.0;
  Y := 1.0 / 0.0;

  if IsNaN(X) then
    WriteLn('X is NaN');

  if IsInfinite(Y) then
    WriteLn('Y is Infinity');
end;
```

## 性能考虑

### 1. 安全运算性能对比

| 策略 | 性能开销 | 适用场景 |
|------|---------|---------|
| Saturating | 1-2 条件分支 | 图形、音频、物理模拟 |
| Checked | 1 条件分支 + Optional 构造 | 金融、关键业务逻辑 |
| Overflowing | 1 条件检查 | 需要知道是否溢出 |
| Wrapping | 0 额外开销 | 哈希、循环计数器 |

### 2. 性能优化建议

✅ **推荐做法**：
```pascal
// 批量操作：使用 Saturating 避免每次检查
procedure ProcessPixels(var Pixels: array of Byte; Delta: Integer);
var
  I: Integer;
begin
  for I := 0 to High(Pixels) do
    Pixels[I] := SaturatingAdd(Pixels[I], Byte(Delta));
end;

// 关键计算：使用 Checked 确保安全
function CalculateTotal(const Items: array of Int64): Int64;
var
  I: Integer;
  Result: TOptionalI64;
begin
  Result := TOptionalI64.Some(0);
  for I := 0 to High(Items) do
  begin
    Result := CheckedAddI64(Result.Value, Items[I]);
    if Result.IsNone then
      raise EOverflow.Create('Total overflow');
  end;
  Result := Result.Value;
end;
```

❌ **避免做法**：
```pascal
// 不要在性能关键路径使用 Checked
for I := 1 to 1000000 do
begin
  Result := CheckedAddU32(Sum, Values[I]);
  if Result.IsSome then
    Sum := Result.Value
  else
    raise EOverflow.Create('Overflow');
end;
```

### 3. 内联函数

```pascal
// 基础数学函数已经内联，性能接近原生操作
function FastCalculation(X, Y: Double): Double; inline;
begin
  Result := Sqrt(Sqr(X) + Sqr(Y));  // 内联，无函数调用开销
end;
```

## 调试和诊断

### 1. 溢出检测

```pascal
{$IFDEF DEBUG}
uses
  fafafa.core.math,
  fafafa.core.math.base;

procedure DebugAdd(A, B: UInt32; const Context: string);
var
  Result: TOverflowU32;
begin
  Result := OverflowingAddU32(A, B);
  if Result.Overflowed then
    WriteLn('[DEBUG] Overflow in ', Context, ': ', A, ' + ', B);
end;
{$ENDIF}
```

### 2. 浮点数诊断

```pascal
procedure DiagnoseFloat(X: Double; const Name: string);
begin
  WriteLn('--- ', Name, ' ---');
  WriteLn('Value: ', X);
  WriteLn('IsNaN: ', IsNaN(X));
  WriteLn('IsInfinite: ', IsInfinite(X));
  WriteLn('Sign: ', Sign(X));
end;

var
  X: Double;
begin
  X := 0.0 / 0.0;
  DiagnoseFloat(X, 'X');
end;
```

## 相关文档

- [fafafa.core.math API 参考](fafafa.core.math.md) - 完整的 API 文档
- [fafafa.core.math.safeint](fafafa.core.math.safeint.md) - SafeInt 详细文档
- [fafafa.core.base 使用指南](fafafa.core.base.guide.md) - 基础类型和异常

## 总结

`fafafa.core.math` 提供了全面的数学运算支持：

1. **基础数学函数**：Abs, Min, Max, Floor, Ceil, Sqrt 等
2. **安全整数运算**：四种策略（Saturating, Checked, Overflowing, Wrapping）
3. **浮点数工具**：NaN/Infinity 检测、符号函数等
4. **三角和对数函数**：Sin, Cos, Tan, Ln, Log10 等

选择合适的安全运算策略，遵循最佳实践，可以编写出既安全又高效的数学运算代码。
