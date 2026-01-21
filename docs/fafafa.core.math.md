
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math

## Abstract 摘要

Provides a set of basic, cross-platform mathematical routines without external dependencies.
提供一组不依赖外部单元的、跨平台的基础数学函数。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.

---

## Module Documentation 模块文档

### Design Philosophy 设计哲学

fafafa.core.math 提供 Rust 风格的安全数学运算，强调：
1. **显式错误处理**：使用 TOptional 和 TOverflow 类型而非异常
2. **跨平台一致性**：所有平台行为一致，无外部依赖
3. **性能优化**：Phase 4.3 优化达到 3.75x-33.0x 性能提升
4. **零成本抽象**：内联函数和编译器优化确保零开销

fafafa.core.math provides Rust-style safe arithmetic operations, emphasizing:
1. **Explicit error handling**: Using TOptional and TOverflow types instead of exceptions
2. **Cross-platform consistency**: Consistent behavior across all platforms, no external dependencies
3. **Performance optimization**: Phase 4.3 optimization achieved 3.75x-33.0x performance improvements
4. **Zero-cost abstractions**: Inline functions and compiler optimizations ensure zero overhead

### Core Concepts 核心概念

#### 1. 安全算术运算策略 (Safe Arithmetic Strategies)

**Saturating Operations (饱和运算)**:
- 溢出时返回类型的最大/最小值
- 适用场景：图形处理、音频处理、颜色计算
- 示例：`SaturatingAdd(High(UInt32), 1)` → `High(UInt32)`

**Checked Operations (检查运算)**:
- 返回 `TOptional<T>`，溢出时返回 None
- 适用场景：金融计算、关键业务逻辑
- 示例：`CheckedMulU32(a, b)` → `Some(result)` 或 `None`

**Overflowing Operations (溢出运算)**:
- 返回 `(value, overflowed)` 元组
- 适用场景：多字算术、密码学
- 示例：`OverflowingAddU32(High(UInt32), 1)` → `(0, True)`

**Wrapping Operations (环绕运算)**:
- 2 补码环绕，不检测溢出
- 适用场景：哈希函数、校验和
- 示例：`WrappingAddU32(High(UInt32), 1)` → `0`

#### 2. 欧几里得除法 (Euclidean Division)

与 Pascal 标准除法的区别：
- Pascal: `-7 div 4 = -1`, `-7 mod 4 = -3` (截断除法)
- Euclidean: `DivEuclidI32(-7, 4) = -2`, `RemEuclidI32(-7, 4) = 1`
- 不变式：`a = DivEuclid(a,b) * b + RemEuclid(a,b)`
- 保证：`0 <= RemEuclid(a,b) < |b|` (余数始终非负)

#### 3. 扩展乘法 (Widening Multiplication)

永不溢出的乘法：
- `WideningMulU32`: UInt32 × UInt32 → UInt64
- `WideningMulU64`: UInt64 × UInt64 → TUInt128
- 适用场景：高精度计算、密码学

#### 4. 进位/借位运算 (Carrying/Borrowing Operations)

用于多字算术：
- `CarryingAddU32(a, b, carry_in)` → `(sum, carry_out)`
- `BorrowingSubU32(a, b, borrow_in)` → `(diff, borrow_out)`
- 适用场景：大整数运算、任意精度算术

### Usage Patterns 使用模式

#### 1. 安全的整数运算

```pascal
// 检查加法溢出
var result: TOptionalU32;
result := CheckedAddU32(a, b);
if result.Valid then
  WriteLn('Sum: ', result.Value)
else
  WriteLn('Overflow detected!');

// 饱和加法（图形处理）
var color: UInt32;
color := SaturatingAdd(baseColor, increment);  // 永不溢出

// 环绕加法（哈希函数）
var hash: UInt32;
hash := WrappingAddU32(hash, value);  // 2 补码环绕
```

#### 2. 欧几里得除法

```pascal
// 标准除法 vs 欧几里得除法
var q, r: Int32;

// Pascal 标准除法（截断）
q := -7 div 4;   // -1
r := -7 mod 4;   // -3

// 欧几里得除法（余数非负）
q := DivEuclidI32(-7, 4);  // -2
r := RemEuclidI32(-7, 4);  // 1

// 验证不变式
Assert((-7) = q * 4 + r);  // -7 = -2 * 4 + 1 = -8 + 1 = -7 ✓
Assert((r >= 0) and (r < 4));  // 1 >= 0 and 1 < 4 ✓
```

#### 3. 多字算术

```pascal
// 128 位加法（使用 64 位字）
var a_lo, a_hi, b_lo, b_hi: UInt64;
var low, high: TCarryResultU64;

// 低位加法
low := CarryingAddU64(a_lo, b_lo, False);

// 高位加法（传播进位）
high := CarryingAddU64(a_hi, b_hi, low.Carry);

WriteLn('Result: ', high.Value, low.Value);
WriteLn('Overflow: ', high.Carry);
```

#### 4. 浮点数运算

```pascal
// 基础浮点运算
var x, y, result: Double;
result := Sqrt(x * x + y * y);  // 欧几里得距离

// 特殊值处理
if IsNaN(result) then
  WriteLn('Invalid calculation')
else if IsInfinite(result) then
  WriteLn('Result is infinite')
else
  WriteLn('Result: ', result:0:2);

// 角度转换
var radians, degrees: Double;
radians := DegToRad(45.0);  // π/4
degrees := RadToDeg(PI);    // 180.0
```

### Performance Characteristics 性能特点

#### Phase 4.3 优化成果

| 函数 | 优化前 | 优化后 | 提升倍数 | 优化策略 |
|------|--------|--------|----------|----------|
| `DivEuclidI32` | 60.61 Mops/s | **2000 Mops/s** | **33.0x** | 条件编译 + 位运算 |
| `RemEuclidI32` | 153.85 Mops/s | **2000 Mops/s** | **13.0x** | 消除除法 + XOR |
| `CheckedMulU32` | 533.33 Mops/s | **2000 Mops/s** | **3.75x** | 移除 Debug 检查 |

**关键优化技术**：
1. **条件编译**：Debug 模式保留检查，Release 模式移除
2. **位运算优化**：XOR 替代复杂条件判断
3. **编译器智能优化**：简化代码让编译器全局优化
4. **内联函数**：零开销抽象

### Best Practices 最佳实践

#### 1. 选择正确的运算策略

```pascal
// ✅ 金融计算：使用 Checked 运算
var total: TOptionalU32;
total := CheckedAddU32(price, tax);
if not total.Valid then
  raise EOverflow.Create('Price overflow');

// ✅ 图形处理：使用 Saturating 运算
var brightness: UInt8;
brightness := SaturatingAdd(pixel, adjustment);

// ✅ 哈希函数：使用 Wrapping 运算
var hash: UInt32;
hash := WrappingMulU32(hash, 31);
hash := WrappingAddU32(hash, Ord(ch));

// ❌ 避免：未检查的运算
var result: UInt32;
result := a + b;  // 可能溢出！
```

#### 2. 欧几里得除法的使用场景

```pascal
// ✅ 需要非负余数时使用欧几里得除法
function PositiveMod(a, b: Int32): Int32;
begin
  Result := RemEuclidI32(a, b);  // 保证 >= 0
end;

// ✅ 循环索引计算
var index: Int32;
index := RemEuclidI32(offset, arrayLength);  // 始终有效

// ❌ 避免：标准 mod 可能返回负数
var index: Int32;
index := offset mod arrayLength;  // 可能为负！
```

#### 3. 性能优化建议

```pascal
// ✅ Release 模式：零开销
{$IFDEF RELEASE}
var result: UInt32;
result := CheckedAddU32(a, b).Value;  // 编译器优化为直接加法
{$ENDIF}

// ✅ 使用内联函数
function FastAdd(a, b: UInt32): UInt32; inline;
begin
  Result := a + b;  // 内联后零开销
end;

// ❌ 避免：不必要的检查
if not IsAddOverflow(a, b) then
  result := a + b  // 两次计算！
else
  HandleOverflow;

// ✅ 改进：一次计算
var temp: TOverflowU32;
temp := OverflowingAddU32(a, b);
if not temp.Overflowed then
  result := temp.Value
else
  HandleOverflow;
```

#### 4. 跨平台一致性

```pascal
// ✅ 使用 fafafa.core.math 确保一致性
var result: Int32;
result := DivEuclidI32(a, b);  // 所有平台行为一致

// ❌ 避免：直接使用 RTL Math
var result: Int32;
result := a div b;  // 不同平台可能不同

// ✅ 使用类型安全的函数
var result: Int64;
result := Floor(x);  // 返回 Int64，不会截断

// ❌ 避免：RTL 函数可能返回 Integer
var result: Integer;
result := System.Trunc(x);  // 32 位限制
```

### Module Structure 模块结构

fafafa.core.math 是一个门面模块，重新导出以下子模块：

- **fafafa.core.math.base**: 基础类型定义（TOptional, TOverflow）
- **fafafa.core.math.float**: 浮点运算（三角函数、对数、指数）
- **fafafa.core.math.safeint**: 安全整数运算（Checked, Saturating, Wrapping）
- **fafafa.core.math.intutil**: 整数工具（对齐、2 的幂次、向上取整）
- **fafafa.core.math.dispatch**: 运行时分发（SIMD 优化）
- **fafafa.core.math.arrays**: 数组运算（向量化操作）

### Related Modules 相关模块

- **fafafa.core.option**: Option 类型用于 Checked 运算
- **fafafa.core.result**: Result 类型用于错误处理
- **fafafa.core.simd**: SIMD 优化的数学运算

### Version History 版本历史

- **v1.0.0** (2026-01-19): Phase 4.3 性能优化完成 (+3.75x-33.0x)
- **v0.9.0** (2026-01-18): 添加欧几里得除法和扩展乘法
- **v0.8.0** (2026-01-17): 添加 Rust 风格安全算术运算

---
