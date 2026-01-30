# fafafa.core.result — 结果类型（Result<T,E>）

## 目标

- 提供跨平台、零依赖、现代化的错误处理原语：`Result<T,E>`
- 语义参考 Rust：`Ok`/`Err`、`unwrap`/`expect`、`map`/`and_then`/`or_else`
- 零额外分配（record 承载），接口简洁、可组合

## 快速开始

```pascal
uses fafafa.core.result;

var R: specialize TResult<Integer, String>;
begin
  R := specialize TResult<Integer, String>.Ok(42);
  if R.IsOk then WriteLn(R.Unwrap);

  R := specialize TResult<Integer, String>.Err('bad');
  WriteLn(R.UnwrapOr(0)); // 0
end;
```

## API 总览

### 构造

- `class function Ok(const AValue: T): TResult` — 构造 Ok 变体
- `class function Err(const AError: E): TResult` — 构造 Err 变体

### 查询

- `function IsOk: Boolean` — 是否为 Ok
- `function IsErr: Boolean` — 是否为 Err

### 取值

- `function Unwrap: T` — 取 Ok 值，Err 时抛 `EResultUnwrapError`
- `function UnwrapOr(const ADefault: T): T` — 取 Ok 值或默认值
- `function Expect(const AMsg: string): T` — 取 Ok 值，Err 时抛自定义消息异常
- `function UnwrapErr: E` — 取 Err 值，Ok 时抛异常
- `function ExpectErr(const AMsg: string): E` — 取 Err 值，Ok 时抛自定义消息异常
- `function TryUnwrap(out AValue: T): Boolean` — 安全取值，返回是否成功
- `function TryUnwrapErr(out AError: E): Boolean` — 安全取错误，返回是否成功
- `function UnwrapUnchecked: T` — 无检查取值（仅 DEBUG 时 Assert）

### 字符串表示

- `function ToString: string` — 返回 `'Ok'` 或 `'Err'`
- `function ToString(OkFormat, ErrFormat: string): string` — 自定义格式字符串
- `function ToDebugString(OkPrinter, ErrPrinter): string` — 详细输出如 `'Ok(42)'` 或 `'Err(msg)'`；当所需 Printer 为 nil 时输出占位符：`Ok(?)` / `Err(?)`

### 方法式 API

- `function Inspect(F): TResult` — Ok 时执行副作用，返回自身
- `function InspectErr(F): TResult` — Err 时执行副作用，返回自身
- `function IsOkAnd(Pred): Boolean` — Ok 且满足谓词
- `function IsErrAnd(Pred): Boolean` — Err 且满足谓词
- `function And_(B: TResult): TResult` — Ok 时返回 B，Err 时返回自身（与 Rust `and` 对齐）
- `function Or_(B: TResult): TResult` — Ok 时返回自身，Err 时返回 B（与 Rust `or` 对齐）
- `function Contains(V, Eq): Boolean` — Ok 且值等于 V
- `function ContainsErr(E, Eq): Boolean` — Err 且值等于 E
- `function Equals(Other, EqT, EqE): Boolean` — 比较两个 Result 是否相等

> **弃用提示**: `AndResult`/`OrResult` 已标记为 deprecated，请迁移至 `And_`/`Or_`。

## 顶层组合子

所有组合子参数类型统一为 `reference to`（可传匿名函数或 `@GlobalFunc`）。

> 注意：回调参数按惰性语义处理——仅当需要调用该回调时才要求非 nil；若 nil 回调被实际调用，将抛出 `EArgumentNil('<Name> is nil')`。
> `ToDebugString` / `TErrorCtx.ToDebugString` 的 Printer 允许为 nil（会输出 `?` 占位符）。

### 映射

```pascal
// Map: Ok(T) -> Ok(U), Err 原样传递
R2 := specialize ResultMap<Integer, String, Integer>(R, @IncOne);

// MapErr: Err(E) -> Err(E2), Ok 原样传递
R2 := specialize ResultMapErr<Integer, String, String>(R, @AppendBang);

// MapBoth: 同时映射 Ok 和 Err
R2 := specialize ResultMapBoth<Integer, String, String, Integer>(R, @IntToStr, @StrLen);
```

### 链式

```pascal
// AndThen: Ok 时执行返回 Result 的函数
R2 := specialize ResultAndThen<Integer, String, Integer>(R,
  function(const X: Integer): specialize TResult<Integer, String>
  begin
    if X > 0 then Result := TResult.Ok(X * 2)
    else Result := TResult.Err('negative');
  end);

// OrElse: Err 时执行恢复函数
R2 := specialize ResultOrElse<Integer, String, String>(R,
  function(const E: String): specialize TResult<Integer, String>
  begin Result := TResult.Ok(Length(E)); end);
```

### 提取值

```pascal
// MapOr: Ok 时映射，Err 时返回默认值
U := specialize ResultMapOr<Integer, String, Integer>(R, -1, @Double);

// MapOrElse: Ok/Err 分别处理
U := specialize ResultMapOrElse<Integer, String, Integer>(R,
  function(const E: String): Integer begin Result := -1; end,
  function(const X: Integer): Integer begin Result := X * 2; end);
```

### 匹配

```pascal
// Match/Fold: 模式匹配
U := specialize ResultMatch<Integer, String, Integer>(R,
  function(const X: Integer): Integer begin Result := X * 10; end,
  function(const S: String): Integer begin Result := -1; end);
```

### 其他组合子

```pascal
// Swap: Ok <-> Err
RS := specialize ResultSwap<Integer, String>(R);

// Flatten: Result<Result<T,E>, E> -> Result<T,E>
R := specialize ResultFlatten<Integer, String>(Outer);

// FilterOrElse
R2 := specialize ResultFilterOrElse<Integer, String>(R, @IsPositive, @MakeErr);

// Chain (管道组合：等同于 First.And_(Second))
// First 为 Ok -> 返回 Second；First 为 Err -> 返回 First
R := specialize ResultChain<Integer, String>(First, Second);

// ResultTranspose: Result<Option<T>,E> -> Option<Result<T,E>>
//   Ok(Some(v)) -> Some(Ok(v))
//   Ok(None)    -> None
//   Err(e)      -> Some(Err(e))
var R: specialize TResult<specialize TOption<Integer>, string>;
var O: specialize TOption<specialize TResult<Integer, string>>;
R := specialize TResult<specialize TOption<Integer>, string>.Ok(
       specialize TOption<Integer>.Some(42));
O := specialize ResultTranspose<Integer, string>(R);
// O = Some(Ok(42))

// OptionTransposeResult (逆操作，定义在 fafafa.core.option):
//   Option<Result<T,E>> -> Result<Option<T>,E>
//   None        -> Ok(None)
//   Some(Ok(v)) -> Ok(Some(v))
//   Some(Err(e))-> Err(e)
uses fafafa.core.option;
var O2: specialize TOption<specialize TResult<Integer, string>>;
var R2: specialize TResult<specialize TOption<Integer>, string>;
O2 := specialize TOption<specialize TResult<Integer, string>>.Some(
        specialize TResult<Integer, string>.Ok(42));
R2 := specialize OptionTransposeResult<Integer, string>(O2);
// R2 = Ok(Some(42))
```

### 快速接口（Ensure / FromBool / Zip）

```pascal
// ResultEnsure: 条件为真 -> Ok(Unit)；否则 -> Err(E)
// 其中 TUnit 为 fafafa.core.result.TUnit（空 record）
var Guard: specialize TResult<TUnit, string>;
Guard := specialize ResultEnsure<string>(X > 0, 'X must be positive');

// ResultEnsureWith: 惰性版本，仅在失败时计算 Err
Guard := specialize ResultEnsureWith<string>(X > 0,
  function: string begin Result := 'X must be positive: ' + IntToStr(X); end);

// ResultFromBool: 从布尔构造 Result
var R1: specialize TResult<Integer, string>;
R1 := specialize ResultFromBool<Integer, string>(X > 0, 1, 'bad');

// ResultFromOption / ResultFromOptionElse: Option<T> -> Result<T,E>
var O: specialize TOption<Integer>;
var ROpt: specialize TResult<Integer, string>;
O := specialize TOption<Integer>.Some(42);
ROpt := specialize ResultFromOption<Integer, string>(O, 'none');
// ROpt = Ok(42)

O := specialize TOption<Integer>.None;
ROpt := specialize ResultFromOptionElse<Integer, string>(O,
  function: string begin Result := 'none'; end);
// ROpt = Err('none')

// ResultZip: (Ok(T1), Ok(T2)) -> Ok(TTuple2<T1,T2>)，否则返回首个 Err
// TTuple2<TFirst,TSecond> 字段：First / Second
// 注意：fafafa.core.option 定义了等价的 TPair<TFirst,TSecond>，两者结构相同
var A: specialize TResult<Integer, string>;
var B: specialize TResult<string, string>;
var Z: specialize TResult< specialize TTuple2<Integer, string>, string>;
A := specialize TResult<Integer, string>.Ok(42);
B := specialize TResult<string, string>.Ok('hello');
Z := specialize ResultZip<Integer, string, string>(A, B);
WriteLn(Z.Unwrap.First);  // 42
WriteLn(Z.Unwrap.Second); // hello

// ResultZipWith: 仅在两个都 Ok 时调用映射函数
var Z2: specialize TResult<string, string>;
Z2 := specialize ResultZipWith<Integer, string, string, string>(A, B,
  function(const P: specialize TTuple2<Integer, string>): string
  begin
    Result := IntToStr(P.First) + ':' + P.Second;
  end);
```

### 序列收集（TryCollect）

```pascal
// TryCollectPtrIntoArray: 将 Result<T,E> 序列收集为动态数组
// 全部 Ok 时返回 True，遇到第一个 Err 时返回 False 并输出该错误
var
  Items: array[0..2] of specialize TResult<Integer, string>;
  OutValues: specialize TValueArray<Integer>;
  FirstErr: string;
  Success: Boolean;
begin
  Items[0] := specialize TResult<Integer, string>.Ok(10);
  Items[1] := specialize TResult<Integer, string>.Ok(20);
  Items[2] := specialize TResult<Integer, string>.Ok(30);

  Success := specialize TryCollectPtrIntoArray<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);
  // Success = True, OutValues = [10, 20, 30], FirstErr = ''

  // 如果有 Err:
  Items[1] := specialize TResult<Integer, string>.Err('error');
  Success := specialize TryCollectPtrIntoArray<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);
  // Success = False, OutValues = [], FirstErr = 'error'
end;
```

- 当 `Count > 0` 时，`ItemsPtr` 必须非 nil；否则将抛出异常。
- 当 `Count = 0` 时，允许 `ItemsPtr = nil`。
- `Count` 必须满足 `Count <= High(SizeInt)`；否则抛出 `EOutOfRange('Count is out of range')`。

**注意**: 此 API 返回 `Boolean` 而非 `TResult`，这是为了规避 FPC 3.3.1 的泛型链接器问题。

### 门面单元（result.facade）

如果你偏好更短的函数名，可以使用门面单元：`fafafa.core.result.facade`。

**注意**: 由于 FPC 3.3.1 的泛型链接器问题，目前 Facade 仅导出 `TryCollect` 别名。
其他函数（如 `Ensure`、`Zip` 等）请直接使用 `fafafa.core.result` 中的 `ResultEnsure`、`ResultZip` 等。

## 异常桥接

```pascal
// ResultFromTry: 捕获异常转为 Result
R := specialize ResultFromTry<Integer, String>(
  @WorkThatMightThrow,
  @ExceptionToString);

// ResultToTry: Err 时抛异常
V := specialize ResultToTry<Integer, String>(R, @StringToException);
```

## 错误上下文

### 简单上下文（丢弃原始错误）

```pascal
// ResultContext: 将原始错误替换为上下文字符串
R2 := specialize ResultContext<Integer, Integer>(R, 'file not found');

// ResultWithContext: 惰性生成上下文（仅在 Err 时调用）
R2 := specialize ResultWithContext<Integer, Integer>(R,
  function(const Code: Integer): string begin Result := 'Error: ' + IntToStr(Code); end);
```

### 错误链（保留原始错误）

使用 `TErrorCtx<E>` 可构建错误链，保留原始错误（Inner）及上下文消息（Msg）：

```pascal
type
  TMyErrorCtx = specialize TErrorCtx<Integer>; // Inner 为 Integer 类型
  TCtxResult = specialize TResult<string, TMyErrorCtx>;

var
  R: specialize TResult<string, Integer>;
  R2: TCtxResult;
  Ctx: TMyErrorCtx;
begin
  R := specialize TResult<string, Integer>.Err(404);

  // ResultContextE: Err 时包装为 TErrorCtx<E>，保留原始错误
  R2 := specialize ResultContextE<string, Integer>(R, 'file not found');
  if R2.IsErr then
  begin
    Ctx := R2.UnwrapErr;
    WriteLn(Ctx.Msg);   // 'file not found'
    WriteLn(Ctx.Inner); // 404 (原始错误)
  end;

  // ResultWithContextE: 惰性版本，仅 Err 时调用上下文生成函数
  R2 := specialize ResultWithContextE<string, Integer>(R,
    function(const Code: Integer): string begin Result := 'Error code: ' + IntToStr(Code); end);

  // ToDebugString: 输出完整错误链
  // 需要提供 Inner 类型的打印函数
  WriteLn(Ctx.ToDebugString(
    function(const E: Integer): string begin Result := IntToStr(E); end));
  // 输出: 'file not found (caused by: 404)'
end;
```

**TErrorCtx<E> API**:

- `Msg: string` — 上下文消息
- `Inner: E` — 原始错误（cause）
- `class function Create(AMsg, AInner): TErrorCtx` — 构造函数
- `function ToDebugString(InnerPrinter): string` — 格式化输出 `'Msg (caused by: InnerStr)'`（当 `InnerPrinter=nil` 时输出 `'Msg (caused by: ?)'`）

## 异常语义

- `Unwrap` on Err 抛 `EResultUnwrapError`
- `UnwrapErr` on Ok 抛 `EResultUnwrapError`
- `Expect(AMsg)` 在错误路径抛携带自定义消息的异常
- 当 nil 回调在执行路径被调用时，抛 `EArgumentNil('<Name> is nil')`
- `TryCollectPtrIntoArray` 当 `Count > High(SizeInt)` 时抛 `EOutOfRange('Count is out of range')`

## 实现要点

- 单元路径：`src/fafafa.core.result.pas`
- 依赖：`SysUtils`、`fafafa.core.option.base`（实现中还使用 `fafafa.core.base` 的 `EArgumentNil` / `EOutOfRange`）
- 使用泛型 record + 标志位布局（FIsOk + FOk + FErr）
- 组合子为顶层泛型函数

### 默认初始化语义

未显式初始化的 `TResult<T,E>` 变量默认为 `Err(Default(E))`：

```pascal
var R: specialize TResult<Integer, string>;
// R.IsErr = True, R.UnwrapErr = '' (空字符串，即 Default(string))
```

这是为了防止未初始化变量被误认为 `Ok`。与 Rust 不同（Rust 没有默认值），Pascal 必须处理未初始化情况。

## 最佳实践

1. **优先使用顶层组合子**：如 `ResultMap`、`ResultAndThen`
2. **方法式 API 用于简单场景**：如 `R.And_(B)`、`R.Inspect(...)`
3. **异常桥接仅用于边界**：`ResultFromTry`/`ResultToTry` 用于与传统代码交互
4. **利用错误链追踪**：使用 `TErrorCtx<E>` + `ResultContextE`/`ResultWithContextE` 保留原始错误
