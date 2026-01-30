# fafafa.core.base — 基础约定与统一别名

## 概述

`fafafa.core.base` 是 fafafa.core 框架的基础模块，定义了全框架共享的类型别名、常量、异常体系和工具函数。所有其他模块都依赖此模块。

## 版本

```pascal
const FAFAFA_CORE_BASE_VERSION = '1.0.0';
```

## 统一类型

### 基础类型别名

```pascal
type
  TBytes = array of Byte;      // 全仓唯一字节序列类型
  TStringArray = array of string;
```

### 过程类型

```pascal
type
  TProc = procedure;                           // 普通过程
  TObjProc = procedure of object;              // 对象方法
  TRefProc = reference to procedure;           // 匿名过程 (需 FAFAFA_CORE_ANONYMOUS_REFERENCES)
```

### 泛型元组

```pascal
type
  generic TTuple2<TFirst, TSecond> = record
    First: TFirst;
    Second: TSecond;
    class function Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2; static;
  end;

// 使用示例
var Pair: specialize TTuple2<Integer, string>;
begin
  Pair := specialize TTuple2<Integer, string>.Create(42, 'hello');
  WriteLn(Pair.First, ' ', Pair.Second);  // 输出: 42 hello
end;
```

### 随机数生成器回调

```pascal
type
  TRandomGeneratorFunc = function(aRange: Int64; aData: Pointer): Int64;
  TRandomGeneratorMethod = function(aRange: Int64; aData: Pointer): Int64 of object;
  TRandomGeneratorRefFunc = reference to function(aRange: Int64): Int64;  // 需匿名引用支持
```

## 数值常量

### 最大值常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `MAX_SIZE_INT` | `High(SizeInt)` | 平台相关有符号整数最大值 |
| `MAX_SIZE_UINT` | `High(SizeUInt)` | 平台相关无符号整数最大值 |
| `MAX_UINT8` | 255 | 8 位无符号最大值 |
| `MAX_INT8` | 127 | 8 位有符号最大值 |
| `MAX_UINT16` | 65535 | 16 位无符号最大值 |
| `MAX_INT16` | 32767 | 16 位有符号最大值 |
| `MAX_UINT32` | 4294967295 | 32 位无符号最大值 |
| `MAX_INT32` | 2147483647 | 32 位有符号最大值 |
| `MAX_UINT64` | 18446744073709551615 | 64 位无符号最大值 |
| `MAX_INT64` | 9223372036854775807 | 64 位有符号最大值 |

### 最小值常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `MIN_SIZE_INT` | `Low(SizeInt)` | 平台相关有符号整数最小值 |
| `MIN_INT8` | -128 | 8 位有符号最小值 |
| `MIN_INT16` | -32768 | 16 位有符号最小值 |
| `MIN_INT32` | -2147483648 | 32 位有符号最小值 |
| `MIN_INT64` | -9223372036854775808 | 64 位有符号最小值 |

### 大小常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `SIZE_PTR` | 4 或 8 | 指针大小（平台相关） |
| `SIZE_8` | 1 | 8 位类型大小 |
| `SIZE_16` | 2 | 16 位类型大小 |
| `SIZE_32` | 4 | 32 位类型大小 |
| `SIZE_64` | 8 | 64 位类型大小 |

## 异常体系

所有异常继承自 `ECore`，形成统一的异常层次结构。

```
Exception (RTL)
└── ECore (框架基类)
    ├── EWow              - 意外内部状态
    ├── EArgumentNil      - 参数为 nil
    ├── EEmptyCollection  - 空集合操作
    ├── EInvalidArgument  - 无效参数
    ├── EInvalidResult    - 无效结果
    ├── ETimeoutError     - 操作超时
    ├── EInvalidState     - 无效状态
    ├── EOutOfRange       - 索引越界
    ├── ENotSupported     - 不支持的操作
    ├── ENotCompatible    - 不兼容
    ├── EInvalidOperation - 无效操作
    ├── EOutOfMemory      - 内存分配失败
    └── EOverflow         - 算术溢出
```

### 异常使用示例

```pascal
uses fafafa.core.base;

procedure ProcessData(Data: Pointer);
begin
  if Data = nil then
    raise EArgumentNil.Create('Data cannot be nil');
end;

procedure GetItem(Index: Integer);
begin
  if (Index < 0) or (Index >= Count) then
    raise EOutOfRange.CreateFmt('Index %d out of range [0..%d]', [Index, Count-1]);
end;
```

## 工具函数

### XML 转义

```pascal
function XmlEscape(const S: string): string;
// 转义 XML 特殊字符: & < > " '

function XmlEscapeXML10Strict(const S: string): string;
// 先移除 XML 1.0 无效字符，再转义
```

**转义规则**:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&apos;`

## 使用指引

```pascal
// 基础模块 - 类型、常量、异常
uses fafafa.core.base;

// 需要字节序列操作
uses fafafa.core.base;  // TBytes
uses fafafa.core.bytes; // Hex/端序/构建器

// 命名冲突时使用限定名
fafafa.core.bytes.HexToBytes(...)
```

## 测试覆盖率 (Phase 3.1)

**统计数据** (更新时间: 2026-01-18):
- **测试用例数**: 51 个测试 (从 31 个增长 +64%)
- **测试通过率**: 100%
- **内存泄漏**: 0

**已覆盖功能**:
- ✅ 版本常量 (2个测试)
- ✅ TTuple2 (4个测试)
- ✅ TTuple3 (3个测试) - Phase 3.1 新增
- ✅ TTuple4 (3个测试) - Phase 3.1 新增
- ✅ 常量 (17个测试)
  - MAX_SIZE_INT, MIN_SIZE_INT
  - MAX_INT64, MIN_INT64
  - MAX_UINT8/16/32/64 - Phase 3.1 新增
  - MAX_INT8/16/32 - Phase 3.1 新增
  - MIN_INT8/16/32/64 - Phase 3.1 新增
  - SIZE_PTR, SIZE_8/16/32/64 - Phase 3.1 新增
- ✅ 泛型函数类型 (7个测试) - Phase 3.1 新增
  - TFunc<TArg, TResult>
  - TAction<TArg>
  - TThunk<TResult>
  - TPredicate<T>
  - TComparer<T>
  - TEquality<T>
  - TBiFunc<T1, T2, TResult>
- ✅ 异常层次结构 (14个测试)

**测试质量**:
- ✅ 正常路径覆盖完整
- ✅ 边界情况覆盖完整
- ✅ 错误处理覆盖完整
- ✅ 类型安全验证完整
- ✅ 内存安全验证（HeapTrc）

## 关联文档

- `docs/fafafa.core.bytes.md` — 字节序列 API
- `docs/fafafa.core.option.md` — Option 类型
- `docs/fafafa.core.result.md` — Result 类型
- `docs/framework_design.md` — 统一类型别名策略
