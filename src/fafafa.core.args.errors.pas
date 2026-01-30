unit fafafa.core.args.errors;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.args.base,
  fafafa.core.result,
  fafafa.core.option.base,  // TOption<T> 核心定义
  fafafa.core.option;

type
  // 参数解析错误类型
  TArgsErrorKind = (
    aekSuccess,              // 成功（无错误）
    aekUnknownOption,        // 未知选项
    aekMissingValue,         // 缺少值
    aekInvalidValue,         // 无效值
    aekDuplicateOption,      // 重复选项
    aekMutuallyExclusive,    // 互斥选项
    aekRequiredMissing,      // 必需参数缺失
    aekTooManyPositionals,   // 位置参数过多
    aekTooFewPositionals,    // 位置参数过少
    aekParseError,           // 通用解析错误
    aekValidationError       // 验证错误
  );

  // 参数解析错误详情（统一定义，包含 v2 扩展字段）
  TArgsError = record
    Kind: TArgsErrorKind;
    Message: string;
    OptionName: string;      // 相关选项名（如果适用）
    Position: Integer;       // 参数位置（从0开始，-1表示不适用）
    ExpectedType: string;    // 期望的类型（如果适用）
    ActualValue: string;     // 实际值（如果适用）
    Suggestion: string;      // 建议修复方案
    Context: string;         // 上下文信息

    class function Success: TArgsError; static;
    class function UnknownOption(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function MissingValue(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function InvalidValue(const OptName, AExpectedType, AActualValue: string; Pos: Integer = -1): TArgsError; static;
    class function DuplicateOption(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function MutuallyExclusive(const Opt1, Opt2: string): TArgsError; static;
    class function RequiredMissing(const OptName: string): TArgsError; static;
    class function TooManyPositionals(Expected, Actual: Integer): TArgsError; static;
    class function TooFewPositionals(Expected, Actual: Integer): TArgsError; static;
    class function ParseError(const Msg: string; Pos: Integer = -1): TArgsError; static;
    class function ValidationError(const OptName, Msg: string): TArgsError; static;

    function IsSuccess: Boolean; inline;
    function ToString: string;
    function ToDetailedString: string;
  end;

  // Result 类型别名
  TArgsResult = specialize TResult<string, TArgsError>;
  TArgsResultInt = specialize TResult<Int64, TArgsError>;
  TArgsResultDouble = specialize TResult<Double, TArgsError>;
  TArgsResultBool = specialize TResult<Boolean, TArgsError>;

// 现代化的参数获取函数
function ArgsGetValueSafe(const Key: string): TArgsResult; overload;
function ArgsGetValueSafe(const A: IArgs; const Key: string): TArgsResult; overload;
function ArgsGetIntSafe(const Key: string): TArgsResultInt; overload;
function ArgsGetIntSafe(const A: IArgs; const Key: string): TArgsResultInt; overload;
function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble; overload;
function ArgsGetDoubleSafe(const A: IArgs; const Key: string): TArgsResultDouble; overload;
function ArgsGetBoolSafe(const Key: string): TArgsResultBool; overload;
function ArgsGetBoolSafe(const A: IArgs; const Key: string): TArgsResultBool; overload;

// Note: Option-style APIs (ArgsGetOpt, ArgsGetInt64Opt, etc.) are in args.base.pas
// This unit focuses on Result-style APIs with detailed error information

// 验证辅助函数
function ValidateRange(const Value: Int64; Min, Max: Int64): specialize TResult<Int64, TArgsError>;
function ValidatePattern(const Value, Pattern: string): specialize TResult<string, TArgsError>;
function ValidateEnum(const Value: string; const ValidValues: array of string): specialize TResult<string, TArgsError>;

implementation

uses
  RegExpr,
  fafafa.core.args.utils;

{ TArgsError }

class function TArgsError.Success: TArgsError;
begin
  Result.Kind := aekSuccess;
  Result.Message := '';
  Result.OptionName := '';
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := '';
  Result.Context := '';
end;

function TArgsError.IsSuccess: Boolean;
begin
  Result := Kind = aekSuccess;
end;

class function TArgsError.UnknownOption(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekUnknownOption;
  Result.Message := Format('Unknown option: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := 'Check available options with --help';
  Result.Context := '';
end;

class function TArgsError.MissingValue(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekMissingValue;
  Result.Message := Format('Option %s requires a value', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := Format('Use %s=<value> or %s <value>', [OptName, OptName]);
  Result.Context := '';
end;

class function TArgsError.InvalidValue(const OptName, AExpectedType, AActualValue: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekInvalidValue;
  Result.Message := Format('Invalid value for option %s: expected %s, got "%s"', [OptName, AExpectedType, AActualValue]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := AExpectedType;
  Result.ActualValue := AActualValue;
  Result.Suggestion := Format('Provide a valid %s value', [AExpectedType]);
  Result.Context := '';
end;

class function TArgsError.DuplicateOption(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekDuplicateOption;
  Result.Message := Format('Duplicate option: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := '';
  Result.Context := '';
end;

class function TArgsError.MutuallyExclusive(const Opt1, Opt2: string): TArgsError;
begin
  Result.Kind := aekMutuallyExclusive;
  Result.Message := Format('Options %s and %s are mutually exclusive', [Opt1, Opt2]);
  Result.OptionName := Opt1;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := Opt2;
  Result.Suggestion := Format('Use either %s or %s, not both', [Opt1, Opt2]);
  Result.Context := '';
end;

class function TArgsError.RequiredMissing(const OptName: string): TArgsError;
begin
  Result.Kind := aekRequiredMissing;
  Result.Message := Format('Required option missing: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := Format('Add the required option: %s', [OptName]);
  Result.Context := '';
end;

class function TArgsError.TooManyPositionals(Expected, Actual: Integer): TArgsError;
begin
  Result.Kind := aekTooManyPositionals;
  Result.Message := Format('Too many positional arguments: expected %d, got %d', [Expected, Actual]);
  Result.OptionName := '';
  Result.Position := Expected;
  Result.ExpectedType := IntToStr(Expected);
  Result.ActualValue := IntToStr(Actual);
  Result.Suggestion := '';
  Result.Context := '';
end;

class function TArgsError.TooFewPositionals(Expected, Actual: Integer): TArgsError;
begin
  Result.Kind := aekTooFewPositionals;
  Result.Message := Format('Too few positional arguments: expected %d, got %d', [Expected, Actual]);
  Result.OptionName := '';
  Result.Position := Actual;
  Result.ExpectedType := IntToStr(Expected);
  Result.ActualValue := IntToStr(Actual);
  Result.Suggestion := '';
  Result.Context := '';
end;

class function TArgsError.ParseError(const Msg: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekParseError;
  Result.Message := Msg;
  Result.OptionName := '';
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := '';
  Result.Context := '';
end;

class function TArgsError.ValidationError(const OptName, Msg: string): TArgsError;
begin
  Result.Kind := aekValidationError;
  Result.Message := Format('Validation error for option %s: %s', [OptName, Msg]);
  Result.OptionName := OptName;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := '';
  Result.Suggestion := '';
  Result.Context := '';
end;

function TArgsError.ToString: string;
begin
  Result := Message;
end;

function TArgsError.ToDetailedString: string;
var
  KindStr: string;
begin
  case Kind of
    aekSuccess: KindStr := 'SUCCESS';
    aekUnknownOption: KindStr := 'UNKNOWN_OPTION';
    aekMissingValue: KindStr := 'MISSING_VALUE';
    aekInvalidValue: KindStr := 'INVALID_VALUE';
    aekDuplicateOption: KindStr := 'DUPLICATE_OPTION';
    aekMutuallyExclusive: KindStr := 'MUTUALLY_EXCLUSIVE';
    aekRequiredMissing: KindStr := 'REQUIRED_MISSING';
    aekTooManyPositionals: KindStr := 'TOO_MANY_POSITIONALS';
    aekTooFewPositionals: KindStr := 'TOO_FEW_POSITIONALS';
    aekParseError: KindStr := 'PARSE_ERROR';
    aekValidationError: KindStr := 'VALIDATION_ERROR';
  else
    KindStr := 'UNKNOWN';
  end;

  Result := Format('[%s] %s', [KindStr, Message]);

  if Position >= 0 then
    Result := Result + Format(' (position: %d)', [Position]);

  if Suggestion <> '' then
    Result := Result + Format(' Suggestion: %s', [Suggestion]);
end;

// 现代化的参数获取函数实现
function ArgsGetValueSafe(const A: IArgs; const Key: string): TArgsResult; overload;
var
  Value: string;
begin
  if A = nil then
    Exit(specialize TResult<string, TArgsError>.Err(
      TArgsError.ParseError('Args instance is nil')));

  if A.TryGetValue(Key, Value) then
    Exit(specialize TResult<string, TArgsError>.Ok(Value));

  Exit(specialize TResult<string, TArgsError>.Err(
    TArgsError.UnknownOption(Key)));
end;

function ArgsGetValueSafe(const Key: string): TArgsResult; overload;
var
  Value: string;
begin
  if ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<string, TArgsError>.Ok(Value));

  Exit(specialize TResult<string, TArgsError>.Err(
    TArgsError.UnknownOption(Key)));
end;

function ArgsGetIntSafe(const A: IArgs; const Key: string): TArgsResultInt; overload;
var
  Value: string;
  IntValue: Int64;
begin
  if A = nil then
    Exit(specialize TResult<Int64, TArgsError>.Err(
      TArgsError.ParseError('Args instance is nil')));

  if not A.TryGetValue(Key, Value) then
    Exit(specialize TResult<Int64, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));

  if TryStrToInt64(Value, IntValue) then
    Exit(specialize TResult<Int64, TArgsError>.Ok(IntValue));

  Exit(specialize TResult<Int64, TArgsError>.Err(
    TArgsError.InvalidValue(Key, 'integer', Value)));
end;

function ArgsGetIntSafe(const Key: string): TArgsResultInt; overload;
var
  Value: string;
  IntValue: Int64;
begin
  if not ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<Int64, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));

  if TryStrToInt64(Value, IntValue) then
    Exit(specialize TResult<Int64, TArgsError>.Ok(IntValue));

  Exit(specialize TResult<Int64, TArgsError>.Err(
    TArgsError.InvalidValue(Key, 'integer', Value)));
end;

function ArgsGetDoubleSafe(const A: IArgs; const Key: string): TArgsResultDouble; overload;
var
  Value: string;
  DoubleValue: Double;
begin
  if A = nil then
    Exit(specialize TResult<Double, TArgsError>.Err(
      TArgsError.ParseError('Args instance is nil')));

  if not A.TryGetValue(Key, Value) then
    Exit(specialize TResult<Double, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));

  if A.TryGetDouble(Key, DoubleValue) then
    Exit(specialize TResult<Double, TArgsError>.Ok(DoubleValue));

  Exit(specialize TResult<Double, TArgsError>.Err(
    TArgsError.InvalidValue(Key, 'number', Value)));
end;

function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble; overload;
var
  Value: string;
  DoubleValue: Double;
  FS: TFormatSettings;
begin
  if not ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<Double, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));

  // Locale-invariant float parsing ('.' as decimal separator)
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  FS.ThousandSeparator := ',';

  if TryStrToFloat(Value, DoubleValue, FS) then
    Exit(specialize TResult<Double, TArgsError>.Ok(DoubleValue));

  Exit(specialize TResult<Double, TArgsError>.Err(
    TArgsError.InvalidValue(Key, 'number', Value)));
end;

function ArgsGetBoolSafe(const A: IArgs; const Key: string): TArgsResultBool; overload;
var
  Value: string;
  BoolValue: Boolean;
begin
  if A = nil then
    Exit(specialize TResult<Boolean, TArgsError>.Err(
      TArgsError.ParseError('Args instance is nil')));

  // Prefer explicit value (last write wins), then fall back to flag-only presence.
  if A.TryGetValue(Key, Value) then
  begin
    if IsTrueValue(Value) then
      BoolValue := True
    else if IsFalseValue(Value) then
      BoolValue := False
    else
      Exit(specialize TResult<Boolean, TArgsError>.Err(
        TArgsError.InvalidValue(Key, 'boolean', Value)));

    Exit(specialize TResult<Boolean, TArgsError>.Ok(BoolValue));
  end;

  if A.HasFlag(Key) then
    Exit(specialize TResult<Boolean, TArgsError>.Ok(True));

  Exit(specialize TResult<Boolean, TArgsError>.Err(
    TArgsError.UnknownOption(Key)));
end;

function ArgsGetBoolSafe(const Key: string): TArgsResultBool; overload;
var
  Value: string;
  BoolValue: Boolean;
begin
  // Prefer explicit value (last write wins), then fall back to flag-only presence.
  if ArgsTryGetValue(Key, Value) then
  begin
    if IsTrueValue(Value) then
      BoolValue := True
    else if IsFalseValue(Value) then
      BoolValue := False
    else
      Exit(specialize TResult<Boolean, TArgsError>.Err(
        TArgsError.InvalidValue(Key, 'boolean', Value)));

    Exit(specialize TResult<Boolean, TArgsError>.Ok(BoolValue));
  end;

  if ArgsHasFlag(Key) then
    Exit(specialize TResult<Boolean, TArgsError>.Ok(True));

  Exit(specialize TResult<Boolean, TArgsError>.Err(
    TArgsError.UnknownOption(Key)));
end;

// 验证辅助函数实现
function ValidateRange(const Value: Int64; Min, Max: Int64): specialize TResult<Int64, TArgsError>;
begin
  if (Value >= Min) and (Value <= Max) then
    Result := specialize TResult<Int64, TArgsError>.Ok(Value)
  else
    Result := specialize TResult<Int64, TArgsError>.Err(
      TArgsError.ValidationError('', Format('Value %d is out of range [%d, %d]', [Value, Min, Max])));
end;

function ValidatePattern(const Value, Pattern: string): specialize TResult<string, TArgsError>;
var
  RegEx: TRegExpr;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := Pattern;
    if RegEx.Exec(Value) then
      Result := specialize TResult<string, TArgsError>.Ok(Value)
    else
      Result := specialize TResult<string, TArgsError>.Err(
        TArgsError.ValidationError('', Format('Value "%s" does not match pattern "%s"', [Value, Pattern])));
  finally
    RegEx.Free;
  end;
end;

function ValidateEnum(const Value: string; const ValidValues: array of string): specialize TResult<string, TArgsError>;
var
  i: Integer;
  ValidList: string;
begin
  for i := Low(ValidValues) to High(ValidValues) do
    if SameText(Value, ValidValues[i]) then
      Exit(specialize TResult<string, TArgsError>.Ok(Value));
  
  ValidList := '';
  for i := Low(ValidValues) to High(ValidValues) do
  begin
    if i > Low(ValidValues) then ValidList := ValidList + ', ';
    ValidList := ValidList + ValidValues[i];
  end;
  
  Result := specialize TResult<string, TArgsError>.Err(
    TArgsError.ValidationError('', Format('Invalid value "%s". Valid values: %s', [Value, ValidList])));
end;

end.
