# fafafa.core.result 模块规划（v0）

## 目标
- 提供跨平台、零依赖、面向抽象的 Result<T,E> 错误处理原语。
- 借鉴 Rust Result 的语义与 API（map/and_then/unwrap/expect 等），符合 FPC 语法与性能特征。
- 以 TDD 驱动：先编写覆盖全部公共 API 的 fpcunit 测试，再实现。

## 背景调研（摘要）
- Rust Result<T,E>：强类型错误、组合子(map/and_then)、解包(unwrap/expect)、与 Option 互转。
- Go error：接口类型 error 返回值 + 显式处理；无代数类型。
- Java 生态：常用异常；函数式库提供 Try/Result（如 Vavr）。
- FPC/Delphi：
  - 泛型 record/接口已可用，record + variant record 可实现零分配 Result。
  - 函数指针可作为简单“函数对象”；匿名函数/闭包在 FPC 中兼容性受限，v0 先用函数指针。

## 设计原则
- 零额外分配：TFfResult<T,E> 使用 discriminated union（variant record）+ 布尔标签。
- API 与 Rust 尽量对齐但贴合 Pascal：
  - Ok/Err 构造：class function Ok/Err。
  - 查询：IsOk/IsErr。
  - 取值：Unwrap/UnwrapOr/Expect/UnwrapErr。
  - 组合：Map/MapErr/AndThen/OrElse。
  - 转换：ToString（调试用）、Match（实用匹配函数）。
- 错误语义：Unwrap/UnwrapErr 在错误路径抛出 EResultUnwrapError。
- 扩展接口：
  - IResultPrinter（调试/日志友好）。
  - 后续与 Option<T> 的互转（v1 以后）。

## 最小 API 草案（Pascal 伪代码）
- 单元：src/fafafa.core.result.pas
- 依赖：仅 RTL；包含 {$I fafafa.core.settings.inc}

```
unit fafafa.core.result;
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
interface

uses SysUtils;

type
  EResultUnwrapError = class(Exception);

  generic TFfFunc<TArg, TResult> = function (const Arg: TArg): TResult;

  generic TFfResult<T,E> = record
  private
    FIsOk: Boolean;
    case Boolean of
      True: (FOk: T);
      False:(FErr: E);
  public
    // 构造
    class function Ok(const AValue: T): specialize TFfResult<T,E>; static; inline;
    class function Err(const AError: E): specialize TFfResult<T,E>; static; inline;
    // 查询
    function IsOk: Boolean; inline;
    function IsErr: Boolean; inline;
    // 取值
    function Unwrap: T; // Err -> raise EResultUnwrapError
    function UnwrapOr(const ADefault: T): T; inline;
    function Expect(const AMsg: string): T; // Err -> raise EResultUnwrapError(AMsg)
    function UnwrapErr: E; // Ok -> raise EResultUnwrapError
    // 组合
    generic function Map<U>(const F: specialize TFfFunc<T,U>): specialize TFfResult<U,E>;
    generic function MapErr<F2>(const F: specialize TFfFunc<E,F2>): specialize TFfResult<T,F2>;
    generic function AndThen<U>(const F: specialize TFfFunc<T, specialize TFfResult<U,E>>): specialize TFfResult<U,E>;
    generic function OrElse<E2>(const F: specialize TFfFunc<E, specialize TFfResult<T,E2>>): specialize TFfResult<T,E2>;
    // 辅助
    function ToString: string;
  end;

implementation
// v0: 简单直接实现，注意避免未初始化读取
end.
```

## 测试计划（TDD）
目录：tests/fafafa.core.result/
- tests_result.lpi / tests_result.lpr
- Test_fafafa_core_result.pas
- BuildOrTest.bat / BuildOrTest.sh（调用 tools/lazbuild.bat）

覆盖用例：
- Ok/Err 构造与 IsOk/IsErr。
- Unwrap/UnwrapOr/Expect/UnwrapErr 正常与异常路径。
- Map/MapErr/AndThen/OrElse 组合逻辑（至少 2 层级）。
- 泛型实例化覆盖：
  - T=int, E=string；T=string, E=Integer；T=record（含引用类型字段）；E=Exception。
- ToString 输出包含标签与值摘要。

## 示例（examples）
- example_result_basic：链式组合读取配置 -> 校验 -> 转换。

## 版本划分
- v0.1：核心 Result + 全覆盖测试 + 示例 + 文档。
- v0.2：与 Option 互转；Contains/ContainsErr；Match；Equal/Compare（需要 comparer）。
- v1.0：稳定 API + 明确二进制兼容策略。

## 风险与对策
- FPC 匿名函数兼容性：v0 采用函数指针，避免闭包；后续可提供重载支持方法指针/接口。
- 变体记录生命周期：避免未初始化读取；对管理型类型（string/dynarray/interface）要注意分支切换复制语义；通过测试覆盖。
- 异常文化差异：提供 Result 与异常共存策略（仅在 Unwrap* 抛异常）。

## 近期任务
1) 编写测试工程骨架与失败用例（红）
2) 实现 src/fafafa.core.result.pas 的 v0 API（绿）
3) 编写示例与文档（重构、清理）
4) 增加 Option 互转与更多组合子（v0.2）

