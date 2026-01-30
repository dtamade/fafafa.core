# fafafa.core.option — 可选类型（Option<T>）

目标
- 提供零依赖、跨平台、零额外分配的 Option<T>（Some/None）
- 借鉴 Rust Option 的语义与 API，贴合 FPC 泛型/闭包特性

快速开始
```pascal
uses fafafa.core.option.base, fafafa.core.option;

var O: specialize TOption<Integer>;
O := specialize TOption<Integer>.Some(7);
if O.IsSome then WriteLn(O.Unwrap); // 7
WriteLn(O.UnwrapOr(9)); // 7

O := specialize TOption<Integer>.None;
WriteLn(O.UnwrapOr(9)); // 9
```

API 概览
- 构造：class function Some/None
- 查询：IsSome/IsNone
- 取值：Unwrap（None -> EOptionUnwrapError）/UnwrapOr
- 组合子：
  - 顶层：OptionMap / OptionAndThen
  - 方法：Inspect（副作用，返回 Self）、ToDebugString（调试输出）

> 注意：回调参数按惰性语义处理——仅当需要调用该回调时才要求非 nil；若 nil 回调被实际调用，将抛出 `EArgumentNil('<Name> is nil')`（定义于 `fafafa.core.base`）。
> `ToDebugString` 的 Printer 允许为 nil（会输出 `Some(?)`）。
- 与 Result 互转：
  - OptionToResult(Some->Ok / None->Err(E))
  - ResultToOption(Ok->Some / Err->None)

组合子示例
```pascal
var O: specialize TOption<Integer> := specialize TOption<Integer>.Some(3);
var O2: specialize TOption<Integer>;
O2 := specialize OptionMap<Integer,Integer>(O,
  function (const X: Integer): Integer begin Result := X+1; end); // Some(4)
O2 := specialize OptionAndThen<Integer,Integer>(O,
  function (const X: Integer): specialize TOption<Integer>
  begin
    if X>0 then Result := specialize TOption<Integer>.Some(X*2)
    else Result := specialize TOption<Integer>.None;
  end); // Some(6)
O := O.Inspect(procedure (const X: Integer) begin WriteLn('seen=', X); end);
```

调试输出
```pascal
var O: specialize TOption<Integer> := specialize TOption<Integer>.Some(3);
WriteLn(O.ToDebugString(function (const X: Integer): string begin Result := IntToStr(X); end)); // Some(3)
```

测试
- 位置：tests/fafafa.core.option/
- 构建与运行：
  - build: buildOrTest.bat
  - test:  buildOrTest.bat test
- 覆盖：Some/None/查询/解包/默认值 + 组合子 + Result 互转

## 测试覆盖率 (Phase 3.1)

**统计数据** (更新时间: 2026-01-18):
- **测试用例数**: 63 个测试 (从 14 个增长 +350%)
- **API 覆盖率**: 97% (34/35 APIs)
- **测试通过率**: 100%
- **内存泄漏**: 0

**测试套件组成**:
- `TTestCase_Option`: 52 个测试（核心功能）
- `TTestCase_Option_CallbackContracts`: 11 个测试（回调契约验证）

**已覆盖 API** (34/35):

*TOption<T> 核心方法*:
- ✅ Some/None - 构造
- ✅ IsSome/IsNone - 查询
- ✅ Unwrap/UnwrapOr/UnwrapOrElse/UnwrapOrDefault/Expect/TryUnwrap - 解包
- ✅ Inspect/ToDebugString - 调试
- ✅ IsSomeAnd/Contains - 谓词检查
- ✅ Or_/And_/Xor_ - 逻辑组合

*全局组合子*:
- ✅ OptionMap/OptionAndThen/OptionMapOr/OptionMapOrElse - 转换
- ✅ OptionFilter - 过滤
- ✅ OptionFlatten/OptionZip/OptionZipWith - 组合
- ✅ OptionToResult/OptionToResultElse/ResultToOption/ResultErrOption - Result 互转
- ✅ ResultTransposeOption/OptionTransposeResult - 转置
- ✅ OptionFromBool/OptionFromString/OptionFromValue/OptionFromInterface - 构造

**测试质量**:
- ✅ 正常路径覆盖完整
- ✅ 边界情况覆盖完整
- ✅ 错误处理覆盖完整
- ✅ Nil 回调验证完整
- ✅ 类型安全验证完整
- ✅ 内存安全验证（HeapTrc）

FromNullable 与链式分流（示例）
```pascal
uses SysUtils, fafafa.core.option.base, fafafa.core.option, fafafa.core.result;

function GetEnvOpt(const Name: string): specialize TOption<string>;
begin
  Result := OptionFromString(GetEnvironmentVariable(Name), True);
end;

function ParseIntOpt(const S: string): specialize TOption<Integer>;
begin
  if TryStrToInt(S, Result.FValue) then
  begin
    Result.FHas := True;
  end
  else
    Result := specialize TOption<Integer>.None;
end;

function NonZero(const X: Integer): Boolean; begin Result := X<>0; end;

var OStr: specialize TOption<string>;
    OInt: specialize TOption<Integer>;
    R: specialize TResult<Integer,string>;
begin
  OStr := GetEnvOpt('MY_PORT');
  OInt := specialize OptionAndThen<string,Integer>(OStr, @ParseIntOpt);
  OInt := specialize OptionFilter<Integer>(OInt, @NonZero);
  // 注入错误信息，得到 Result 以便上游消费
  R := specialize OptionToResult<Integer,string>(OInt, 'invalid port');
  if R.IsOk then WriteLn('port=', R.Unwrap) else WriteLn('ERR: ', R.UnwrapErr);
end;
```

别名与辅助（aliases）
- 参见 docs/fafafa.core.aliases.md：Some/None、常用类型别名、Ok/Err 泛型辅助

后续路线
- 扩展组合子（MapOr/MapOrElse/Filter）
- 与 Result 更丰富的互操作（OkOr/ErrOrNone 等）
- 文档补充更多范式与实践建议

