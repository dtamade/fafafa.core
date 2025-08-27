# fafafa.core.result — 结果类型（Result<T,E>）

目标
- 提供跨平台、零依赖、现代化的错误处理原语：Result<T,E>
- 语义参考 Rust：Ok/Err、unwrap/expect、map/and_then/or_else
- 零额外分配（record 承载），接口简洁、可组合

快速开始
```pascal
uses fafafa.core.result;
最佳实践说明
- 函数式门面（ResultXxx 顶层函数）为“规范接口”，默认推荐使用；方法式仅在需要链式风格时开启宏 FAFAFA_CORE_RESULT_METHODS。
- 受管类型（如 string、动态数组、接口）建议保持默认双字段布局；仅当 T/E 明确为非受管类型时，才考虑启用变体布局宏（见下）。
- 异常桥接仅用于边界与适配层（ResultFromTry / ResultToTry），领域逻辑内部优先保持 Result 流。

变体布局宏与使用边界
- 默认：安全双字段布局（FIsOk + FOk + FErr）
- 可选宏：
  - FAFAFA_RESULT_VARIANT_LAYOUT：启用变体记录布局以降低占用（仅当 T/E 均为非受管类型）
  - FAFAFA_RESULT_ASSUME_NO_MANAGED：强化“不含受管类型”的假设，避免 RC/生命周期问题
- 建议：如需启用变体布局，请在模块级/工程级确保 T/E 为非受管类型，并用单测约束

API 总览（精选）
- 基础：Ok/Err/IsOk/IsErr/Unwrap/UnwrapOr/UnwrapOrElse/Expect/UnwrapErr
- 组合：Map/MapErr/AndThen/OrElse/MapOr/MapOrElse/MapBoth/Flatten/Swap
- 谓词/观察：IsOkAnd/IsErrAnd/Inspect/InspectErr
开启方法式 API（可选）
- 编辑 src\fafafa.core.settings.inc，取消注释以下宏：
```
{.$DEFINE FAFAFA_CORE_RESULT_METHODS}
```
改为：
```
{$DEFINE FAFAFA_CORE_RESULT_METHODS}
```
- 重新构建后，可使用 And/Or/Contains*/FilterOrElse/ToTry 等方法式链路。

- 扩展：And/Or、Contains/ContainsErr、FilterOrElse、Equals（默认 =）、ResultToTry
- 匹配：Match/Fold
- 互操作：OkOpt/ErrOpt、OptionToResult/ResultToOption/ResultErrOption、ResultTransposeOption、OptionTransposeResult


var R: specialize TResult<Integer,String>;
方法式 API 速览（需开启 FAFAFA_CORE_RESULT_METHODS）
```pascal
var Rb: specialize TResult<Integer,String>;
Rb := specialize TResult<Integer,String>.Ok(1)
        .And(specialize TResult<Integer,String>.Err('x'))
        .Or(specialize TResult<Integer,String>.Ok(9));
try
  WriteLn(Rb.ToTry(function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end));
except on Ex: Exception do WriteLn(Ex.Message); end;
```

begin
  R := specialize TResult<Integer,String>.Ok(42);
  if R.IsOk then WriteLn(R.Unwrap);

  R := specialize TResult<Integer,String>.Err('bad');
  WriteLn(R.UnwrapOr(0)); // 0
end;
```

如何运行示例
- 运行链式示例：examples\fafafa.core.result\BuildOrRun.bat
- 运行 Filter/ToTry/Transpose 示例：examples\fafafa.core.result\BuildOrRun.bat filters


API 概览
注意：ToString 仅输出标签（Ok/Err），调试打印建议使用 ToDebugString 传入打印器以获得详细输出。

- 构造：class function Ok/Err
- 查询：IsOk/IsErr
- 取值：Unwrap/UnwrapOr/Expect/UnwrapErr（错误路径抛出 EResultUnwrapError）
- 组合子（顶层泛型函数）：
  - ResultMap / ResultMapErr
  - ResultAndThen / ResultOrElse
  - ResultMapOr / ResultMapOrElse
  - ResultInspect / ResultInspectErr（副作用，返回原值）
  - ResultMatch / ResultFold（Ok 走 Fok；Err 走 Ferr）
- 谓词：ResultIsOkAnd / ResultIsErrAnd
- 扩展：
  - ResultAnd / ResultOr（非闭包直连组合子）
  - ResultContains / ResultContainsErr（带比较器/指针重载）
  - ResultFilterOrElse（Ok 且谓词不满足 -> 生成 Err）
  - ResultEquals 默认重载（当 T/E 支持 = 运算）
  - ResultToTry（Err -> raise 映射异常；Ok -> 返回值）
  - 与 Option 互操作：OkOpt/ErrOpt、OptionToResult/ResultToOption/ResultErrOption、ResultTransposeOption、OptionTransposeResult


异常语义
- Unwrap on Err 与 UnwrapErr on Ok 都会抛出 EResultUnwrapError
- Expect(AMsg) 在错误路径抛出携带自定义消息的 EResultUnwrapError

实现要点
- 单元路径：src/fafafa.core.result.pas
- 依赖：SysUtils；包含 {$I fafafa.core.settings.inc}
- 使用泛型 record + 标志位；组合子为顶层泛型函数以便复用

可选优化（默认关闭）
- variant 布局：仅在定义 FAFAFA_RESULT_VARIANT_LAYOUT 宏时启用
- 安全前提：若再定义 FAFAFA_RESULT_ASSUME_NO_MANAGED，则表示 T/E 均非管理型类型（如整型/枚举/小记录），可启用“判别联合”布局降低体积与引用计数噪音
- 默认行为：不定义上述宏，维持双字段布局，确保管理型类型安全

组合子示例
```pascal
var R: specialize TResult<Integer,String>;
var S: Integer;
R := specialize TResult<Integer,String>.Ok(5);
// MapOr: Ok -> f(T), Err -> 默认值 -1
S := specialize ResultMapOr<Integer,String,Integer>(R, -1,
  function (const X: Integer): Integer begin Result := X*2; end);
// MapOrElse: Ok -> f_ok(T), Err -> f_err(E)
S := specialize ResultMapOrElse<Integer,String,Integer>(R,
  function (const E: String): Integer begin Result := -2; end,
  function (const X: Integer): Integer begin Result := X+3; end);
// Inspect: 在 Ok 路径做副作用，不改变 R

匹配与折叠（Match / Fold）
```pascal
var R: specialize TResult<Integer,String>;
var U: Integer;
R := specialize TResult<Integer,String>.Ok(3);
U := specialize ResultMatch<Integer,String,Integer>(R,
  function (const X: Integer): Integer begin Result := X*10; end,
  function (const S: String): Integer begin Result := -1; end);
// U = 30
```


异常桥接（ResultFromTry）
```pascal
var U: Integer;
U := specialize ResultFromTry<Integer,String>(
  function: Integer begin Result := 7; end,
  function (const Ex: Exception): String begin Result := Ex.Message; end
).Unwrap;
```

等值比较（ResultEquals）
```pascal
var R1, R2: specialize TResult<Integer,String>;
R1 := specialize TResult<Integer,String>.Ok(42);
R2 := specialize TResult<Integer,String>.Ok(42);
if specialize ResultEquals<Integer,String>(R1, R2,
  function (const A,B: Integer): Boolean begin Result := A=B; end,
  function (const A,B: String): Boolean begin Result := A=B; end) then
  WriteLn('equal');
```

谓词（Predicates）
```pascal
var ROk, RErr: specialize TResult<Integer,String>;
CheckTrue(specialize ResultIsOkAnd<Integer,String>(ROk,
  function (const X: Integer): Boolean begin Result := X>0; end));
CheckTrue(specialize ResultIsErrAnd<Integer,String>(RErr,
  function (const S: String): Boolean begin Result := S<>''; end));
```

R := specialize ResultInspect<Integer,String>(R,
  procedure (const X: Integer) begin WriteLn('ok=', X); end);
```

调试输出（ToDebugString）
```pascal
var R1: specialize TResult<Integer,String> := specialize TResult<Integer,String>.Ok(9);
var R2: specialize TResult<Integer,String> := specialize TResult<Integer,String>.Err('oops');

过滤与生成错误（FilterOrElse）
```pascal
var R, R2: specialize TResult<Integer,String>;
R := specialize TResult<Integer,String>.Ok(3);
R2 := specialize ResultFilterOrElse<Integer,String>(R,
  function (const X: Integer): Boolean begin Result := (X mod 2)=0; end,
  function (const X: Integer): String begin Result := 'odd'; end);
// R2 = Err('odd')
```

将 Err 映射为异常（ResultToTry）
```pascal
var R: specialize TResult<Integer,String>;
var V: Integer;
R := specialize TResult<Integer,String>.Err('bad');
try
  V := specialize ResultToTry<Integer,String>(R,
    function (const E: String): Exception begin Result := Exception.Create('mapped:'+E); end);
except on Ex: Exception do WriteLn(Ex.Message); end; // 'mapped:bad'

速查表（常用模式）
```pascal
// And/Or：合并两个 Result
R := specialize ResultAnd<Integer,String>(R1, R2); // R1.Ok -> R2；R1.Err -> Err(R1)
R := specialize ResultOr<Integer,String>(R1, R2);  // R1.Ok -> R1；R1.Err -> R2

// Contains/ContainsErr：判定包含
if specialize ResultContains<Integer,String>(R, 42,
  function (const L,R: Integer): Boolean begin Result := L=R; end) then ...
if specialize ResultContainsErr<Integer,String>(R, 'io',
  function (const L,R: String): Boolean begin Result := Pos(R,L)>0; end) then ...
```


R := specialize TResult<Integer,String>.Ok(9);
V := specialize ResultToTry<Integer,String>(R,
  function (const E: String): Exception begin Result := Exception.Create(E); end);
// V = 9
```

与 Option 的 Transpose 互操作
```pascal
uses fafafa.core.option;

var RO: specialize TResult< specialize TOption<Integer>, String>;
var ORs: specialize TOption< specialize TResult<Integer,String> >;

RO := specialize TResult< specialize TOption<Integer>, String>.Ok(specialize TOption<Integer>.Some(5));
ORs := specialize ResultTransposeOption<Integer,String>(RO);
// ORs = Some(Ok(5))

RO := specialize TResult< specialize TOption<Integer>, String>.Err('e');
ORs := specialize ResultTransposeOption<Integer,String>(RO);
// ORs = Some(Err('e'))
```

WriteLn(R1.ToDebugString(
  function (const V: Integer): string begin Result := IntToStr(V); end,
  function (const E: String): string begin Result := E; end)); // Ok(9)
WriteLn(R2.ToDebugString(
  function (const V: Integer): string begin Result := IntToStr(V); end,
  function (const E: String): string begin Result := E; end)); // Err(oops)
```


常见陷阱与建议
- Map vs AndThen：Map 适用于 Ok 分支“纯变换”（T->U），AndThen 适用于“可能失败的变换”（T->Result<U,E>），避免在 Map 中手工构造 Err。
- UnwrapOr vs UnwrapOrElse：前者传常量默认值；后者按需计算（闭包/函数）更高效（只在 Err 时执行）。
- Transpose 的典型场景：当读取“可选值”同时又可能失败时，Result<Option<T>,E> 与 Option<Result<T,E>> 的互转可以简化分支处理。
- 异常桥接：ResultFromTry/ResultToTry 适用于与异常世界的边界层；在业务逻辑内部尽量避免混用异常与 Result，统一语义更清晰。

测试
- 位置：tests/fafafa.core.result/
- 构建与运行：
  - build: buildOrTest.bat
  - test:  buildOrTest.bat test
- 覆盖：Ok/Err/IsOk/IsErr/Unwrap/UnwrapOr/Expect/UnwrapErr + 全部组合子（含 MapOr/MapOrElse/Inspect/InspectErr）

别名与辅助（aliases）
- 参见 docs/fafafa.core.aliases.md：Ok/Err 泛型辅助与常见类型别名

后续路线
- 提供 Match 辅助函数与 IResultPrinter 调试接口
- 与 Option<T> 互转（Some/None）
- 更丰富的 Map/MapErr 扩展与链式工具

