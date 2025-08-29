unit fafafa.core.args.errors;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.result,
  fafafa.core.option,
  fafafa.core.aliases;

type
  // 参数解析错误类型
  TArgsErrorKind = (
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

  // 参数解析错误详情
  TArgsError = record
    Kind: TArgsErrorKind;
    Message: string;
    OptionName: string;      // 相关选项名（如果适用）
    Position: Integer;       // 参数位置（从0开始，-1表示不适用）
    ExpectedType: string;    // 期望的类型（如果适用）
    ActualValue: string;     // 实际值（如果适用）
    
    class function UnknownOption(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function MissingValue(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function InvalidValue(const OptName, ExpectedType, ActualValue: string; Pos: Integer = -1): TArgsError; static;
    class function DuplicateOption(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function MutuallyExclusive(const Opt1, Opt2: string): TArgsError; static;
    class function RequiredMissing(const OptName: string): TArgsError; static;
    class function TooManyPositionals(Expected, Actual: Integer): TArgsError; static;
    class function TooFewPositionals(Expected, Actual: Integer): TArgsError; static;
    class function ParseError(const Msg: string; Pos: Integer = -1): TArgsError; static;
    class function ValidationError(const OptName, Msg: string): TArgsError; static;
    
    function ToString: string;
    function ToDetailedString: string;
  end;

  // 类型别名
  TArgsResult = specialize TResult<string, TArgsError>;
  TArgsOptionStr = specialize TOption<string>;
  TArgsResultInt = specialize TResult<Int64, TArgsError>;
  TArgsResultDouble = specialize TResult<Double, TArgsError>;
  TArgsResultBool = specialize TResult<Boolean, TArgsError>;

// 现代化的参数获取函数
function ArgsGetValueSafe(const Key: string): TArgsResult;
function ArgsGetIntSafe(const Key: string): TArgsResultInt;
function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble;
function ArgsGetBoolSafe(const Key: string): TArgsResultBool;

// Option 风格的参数获取
function ArgsGetValueOpt(const Key: string): TArgsOptionStr;
function ArgsGetIntOpt(const Key: string): specialize TOption<Int64>;
function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>;
function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>;

// 验证辅助函数
function ValidateRange(const Value: Int64; Min, Max: Int64): specialize TResult<Int64, TArgsError>;
function ValidatePattern(const Value, Pattern: string): specialize TResult<string, TArgsError>;
function ValidateEnum(const Value: string; const ValidValues: array of string): specialize TResult<string, TArgsError>;

implementation

uses
  fafafa.core.args, RegExpr;

{ TArgsError }

class function TArgsError.UnknownOption(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekUnknownOption;
  Result.Message := Format('Unknown option: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

class function TArgsError.MissingValue(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekMissingValue;
  Result.Message := Format('Option %s requires a value', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

class function TArgsError.InvalidValue(const OptName, ExpectedType, ActualValue: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekInvalidValue;
  Result.Message := Format('Invalid value for option %s: expected %s, got "%s"', [OptName, ExpectedType, ActualValue]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := ExpectedType;
  Result.ActualValue := ActualValue;
end;

class function TArgsError.DuplicateOption(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekDuplicateOption;
  Result.Message := Format('Duplicate option: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

class function TArgsError.MutuallyExclusive(const Opt1, Opt2: string): TArgsError;
begin
  Result.Kind := aekMutuallyExclusive;
  Result.Message := Format('Options %s and %s are mutually exclusive', [Opt1, Opt2]);
  Result.OptionName := Opt1;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := Opt2;
end;

class function TArgsError.RequiredMissing(const OptName: string): TArgsError;
begin
  Result.Kind := aekRequiredMissing;
  Result.Message := Format('Required option missing: %s', [OptName]);
  Result.OptionName := OptName;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

class function TArgsError.TooManyPositionals(Expected, Actual: Integer): TArgsError;
begin
  Result.Kind := aekTooManyPositionals;
  Result.Message := Format('Too many positional arguments: expected %d, got %d', [Expected, Actual]);
  Result.OptionName := '';
  Result.Position := Expected;
  Result.ExpectedType := IntToStr(Expected);
  Result.ActualValue := IntToStr(Actual);
end;

class function TArgsError.TooFewPositionals(Expected, Actual: Integer): TArgsError;
begin
  Result.Kind := aekTooFewPositionals;
  Result.Message := Format('Too few positional arguments: expected %d, got %d', [Expected, Actual]);
  Result.OptionName := '';
  Result.Position := Actual;
  Result.ExpectedType := IntToStr(Expected);
  Result.ActualValue := IntToStr(Actual);
end;

class function TArgsError.ParseError(const Msg: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekParseError;
  Result.Message := Msg;
  Result.OptionName := '';
  Result.Position := Pos;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

class function TArgsError.ValidationError(const OptName, Msg: string): TArgsError;
begin
  Result.Kind := aekValidationError;
  Result.Message := Format('Validation error for option %s: %s', [OptName, Msg]);
  Result.OptionName := OptName;
  Result.Position := -1;
  Result.ExpectedType := '';
  Result.ActualValue := '';
end;

function TArgsError.ToString: string;
begin
  Result := Message;
end;

function TArgsError.ToDetailedString: string;
begin
  Result := Format('[%s] %s', [
    case Kind of
      aekUnknownOption: 'UNKNOWN_OPTION';
      aekMissingValue: 'MISSING_VALUE';
      aekInvalidValue: 'INVALID_VALUE';
      aekDuplicateOption: 'DUPLICATE_OPTION';
      aekMutuallyExclusive: 'MUTUALLY_EXCLUSIVE';
      aekRequiredMissing: 'REQUIRED_MISSING';
      aekTooManyPositionals: 'TOO_MANY_POSITIONALS';
      aekTooFewPositionals: 'TOO_FEW_POSITIONALS';
      aekParseError: 'PARSE_ERROR';
      aekValidationError: 'VALIDATION_ERROR';
    end,
    Message
  ]);
  
  if Position >= 0 then
    Result := Result + Format(' (position: %d)', [Position]);
end;

// 现代化的参数获取函数实现
function ArgsGetValueSafe(const Key: string): TArgsResult;
var
  Value: string;
begin
  if ArgsTryGetValue(Key, Value) then
    Result := specialize TResult<string, TArgsError>.Ok(Value)
  else
    Result := specialize TResult<string, TArgsError>.Err(
      TArgsError.UnknownOption(Key));
end;

function ArgsGetIntSafe(const Key: string): TArgsResultInt;
var
  Value: string;
  IntValue: Int64;
begin
  if not ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<Int64, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));
  
  if TryStrToInt64(Value, IntValue) then
    Result := specialize TResult<Int64, TArgsError>.Ok(IntValue)
  else
    Result := specialize TResult<Int64, TArgsError>.Err(
      TArgsError.InvalidValue(Key, 'integer', Value));
end;

function ArgsGetDoubleSafe(const Key: string): TArgsResultDouble;
var
  Value: string;
  DoubleValue: Double;
begin
  if not ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<Double, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));
  
  if TryStrToFloat(Value, DoubleValue) then
    Result := specialize TResult<Double, TArgsError>.Ok(DoubleValue)
  else
    Result := specialize TResult<Double, TArgsError>.Err(
      TArgsError.InvalidValue(Key, 'number', Value));
end;

function ArgsGetBoolSafe(const Key: string): TArgsResultBool;
var
  Value: string;
  BoolValue: Boolean;
begin
  if ArgsHasFlag(Key) then
    Exit(specialize TResult<Boolean, TArgsError>.Ok(True));
  
  if not ArgsTryGetValue(Key, Value) then
    Exit(specialize TResult<Boolean, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));
  
  Value := LowerCase(Trim(Value));
  if (Value = 'true') or (Value = '1') or (Value = 'yes') or (Value = 'on') then
    BoolValue := True
  else if (Value = 'false') or (Value = '0') or (Value = 'no') or (Value = 'off') then
    BoolValue := False
  else
    Exit(specialize TResult<Boolean, TArgsError>.Err(
      TArgsError.InvalidValue(Key, 'boolean', Value)));
  
  Result := specialize TResult<Boolean, TArgsError>.Ok(BoolValue);
end;

// Option 风格的参数获取实现
function ArgsGetValueOpt(const Key: string): TArgsOptionStr;
var
  Value: string;
begin
  if ArgsTryGetValue(Key, Value) then
    Result := specialize TOption<string>.Some(Value)
  else
    Result := specialize TOption<string>.None;
end;

function ArgsGetIntOpt(const Key: string): specialize TOption<Int64>;
var
  Value: string;
  IntValue: Int64;
begin
  if ArgsTryGetValue(Key, Value) and TryStrToInt64(Value, IntValue) then
    Result := specialize TOption<Int64>.Some(IntValue)
  else
    Result := specialize TOption<Int64>.None;
end;

function ArgsGetDoubleOpt(const Key: string): specialize TOption<Double>;
var
  Value: string;
  DoubleValue: Double;
begin
  if ArgsTryGetValue(Key, Value) and TryStrToFloat(Value, DoubleValue) then
    Result := specialize TOption<Double>.Some(DoubleValue)
  else
    Result := specialize TOption<Double>.None;
end;

function ArgsGetBoolOpt(const Key: string): specialize TOption<Boolean>;
var
  Value: string;
begin
  if ArgsHasFlag(Key) then
    Exit(specialize TOption<Boolean>.Some(True));
  
  if ArgsTryGetValue(Key, Value) then
  begin
    Value := LowerCase(Trim(Value));
    if (Value = 'true') or (Value = '1') or (Value = 'yes') or (Value = 'on') then
      Result := specialize TOption<Boolean>.Some(True)
    else if (Value = 'false') or (Value = '0') or (Value = 'no') or (Value = 'off') then
      Result := specialize TOption<Boolean>.Some(False)
    else
      Result := specialize TOption<Boolean>.None;
  end
  else
    Result := specialize TOption<Boolean>.None;
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
