unit fafafa.core.args.modern;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.errors,
  fafafa.core.result,
  fafafa.core.option,
  fafafa.core.aliases;

type
  // 现代化的参数解析器接口
  IArgsModern = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    
    // Result 风格的获取方法
    function GetValue(const Key: string): TArgsResult;
    function GetInt(const Key: string): TArgsResultInt;
    function GetDouble(const Key: string): TArgsResultDouble;
    function GetBool(const Key: string): TArgsResultBool;
    
    // Option 风格的获取方法
    function GetValueOpt(const Key: string): TArgsOptionStr;
    function GetIntOpt(const Key: string): specialize TOption<Int64>;
    function GetDoubleOpt(const Key: string): specialize TOption<Double>;
    function GetBoolOpt(const Key: string): specialize TOption<Boolean>;
    
    // 带验证的获取方法
    function GetIntRange(const Key: string; Min, Max: Int64): TArgsResultInt;
    function GetPattern(const Key: string; const Pattern: string): TArgsResult;
    function GetEnum(const Key: string; const ValidValues: array of string): TArgsResult;
    
    // 链式验证支持
    function Validate: IArgsValidator;
    
    // 传统兼容性
    function AsLegacy: IArgs;
  end;

  // 参数验证器接口
  IArgsValidator = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F23456789012}']
    function Required(const Key: string): IArgsValidator;
    function Optional(const Key: string): IArgsValidator;
    function Range(const Key: string; Min, Max: Int64): IArgsValidator;
    function Pattern(const Key: string; const RegexPattern: string): IArgsValidator;
    function Enum(const Key: string; const ValidValues: array of string): IArgsValidator;
    function MutuallyExclusive(const Key1, Key2: string): IArgsValidator;
    function AtLeastOne(const Keys: array of string): IArgsValidator;
    function PositionalCount(Min, Max: Integer): IArgsValidator;
    
    // 执行验证
    function Check: specialize TResult<Boolean, TArgsError>;
    function CheckAll: specialize TResult<Boolean, array of TArgsError>;
  end;

  // 现代化参数解析器实现
  TArgsModern = class(TInterfacedObject, IArgsModern)
  private
    FLegacyArgs: IArgs;
  public
    constructor Create(const ALegacyArgs: IArgs);
    
    // IArgsModern
    function GetValue(const Key: string): TArgsResult;
    function GetInt(const Key: string): TArgsResultInt;
    function GetDouble(const Key: string): TArgsResultDouble;
    function GetBool(const Key: string): TArgsResultBool;
    
    function GetValueOpt(const Key: string): TArgsOptionStr;
    function GetIntOpt(const Key: string): specialize TOption<Int64>;
    function GetDoubleOpt(const Key: string): specialize TOption<Double>;
    function GetBoolOpt(const Key: string): specialize TOption<Boolean>;
    
    function GetIntRange(const Key: string; Min, Max: Int64): TArgsResultInt;
    function GetPattern(const Key: string; const Pattern: string): TArgsResult;
    function GetEnum(const Key: string; const ValidValues: array of string): TArgsResult;
    
    function Validate: IArgsValidator;
    function AsLegacy: IArgs;
  end;

  // 验证规则
  TValidationRule = record
    RuleType: (vrRequired, vrOptional, vrRange, vrPattern, vrEnum, vrMutuallyExclusive, vrAtLeastOne, vrPositionalCount);
    Key: string;
    Key2: string;  // 用于互斥规则
    MinValue: Int64;
    MaxValue: Int64;
    Pattern: string;
    ValidValues: TStringArray;
    Keys: TStringArray;  // 用于 AtLeastOne
  end;

  // 参数验证器实现
  TArgsValidator = class(TInterfacedObject, IArgsValidator)
  private
    FArgs: IArgs;
    FRules: array of TValidationRule;
    procedure AddRule(const Rule: TValidationRule);
  public
    constructor Create(const AArgs: IArgs);
    
    function Required(const Key: string): IArgsValidator;
    function Optional(const Key: string): IArgsValidator;
    function Range(const Key: string; Min, Max: Int64): IArgsValidator;
    function Pattern(const Key: string; const RegexPattern: string): IArgsValidator;
    function Enum(const Key: string; const ValidValues: array of string): IArgsValidator;
    function MutuallyExclusive(const Key1, Key2: string): IArgsValidator;
    function AtLeastOne(const Keys: array of string): IArgsValidator;
    function PositionalCount(Min, Max: Integer): IArgsValidator;
    
    function Check: specialize TResult<Boolean, TArgsError>;
    function CheckAll: specialize TResult<Boolean, array of TArgsError>;
  end;

// 便利函数
function ModernArgs(const A: IArgs): IArgsModern;
function ModernArgsFromProcess: IArgsModern;
function ModernArgsFromArray(const Args: array of string; const Opts: TArgsOptions): IArgsModern;

implementation

uses
  RegExpr;

{ TArgsModern }

constructor TArgsModern.Create(const ALegacyArgs: IArgs);
begin
  inherited Create;
  FLegacyArgs := ALegacyArgs;
end;

function TArgsModern.GetValue(const Key: string): TArgsResult;
var
  Value: string;
begin
  if FLegacyArgs.TryGetValue(Key, Value) then
    Result := specialize TResult<string, TArgsError>.Ok(Value)
  else
    Result := specialize TResult<string, TArgsError>.Err(
      TArgsError.UnknownOption(Key));
end;

function TArgsModern.GetInt(const Key: string): TArgsResultInt;
var
  Value: string;
  IntValue: Int64;
begin
  if not FLegacyArgs.TryGetValue(Key, Value) then
    Exit(specialize TResult<Int64, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));
  
  if TryStrToInt64(Value, IntValue) then
    Result := specialize TResult<Int64, TArgsError>.Ok(IntValue)
  else
    Result := specialize TResult<Int64, TArgsError>.Err(
      TArgsError.InvalidValue(Key, 'integer', Value));
end;

function TArgsModern.GetDouble(const Key: string): TArgsResultDouble;
var
  Value: string;
  DoubleValue: Double;
begin
  if not FLegacyArgs.TryGetValue(Key, Value) then
    Exit(specialize TResult<Double, TArgsError>.Err(
      TArgsError.UnknownOption(Key)));
  
  if TryStrToFloat(Value, DoubleValue) then
    Result := specialize TResult<Double, TArgsError>.Ok(DoubleValue)
  else
    Result := specialize TResult<Double, TArgsError>.Err(
      TArgsError.InvalidValue(Key, 'number', Value));
end;

function TArgsModern.GetBool(const Key: string): TArgsResultBool;
var
  Value: string;
  BoolValue: Boolean;
begin
  if FLegacyArgs.HasFlag(Key) then
    Exit(specialize TResult<Boolean, TArgsError>.Ok(True));
  
  if not FLegacyArgs.TryGetValue(Key, Value) then
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

function TArgsModern.GetValueOpt(const Key: string): TArgsOptionStr;
var
  Value: string;
begin
  if FLegacyArgs.TryGetValue(Key, Value) then
    Result := specialize TOption<string>.Some(Value)
  else
    Result := specialize TOption<string>.None;
end;

function TArgsModern.GetIntOpt(const Key: string): specialize TOption<Int64>;
var
  Value: string;
  IntValue: Int64;
begin
  if FLegacyArgs.TryGetValue(Key, Value) and TryStrToInt64(Value, IntValue) then
    Result := specialize TOption<Int64>.Some(IntValue)
  else
    Result := specialize TOption<Int64>.None;
end;

function TArgsModern.GetDoubleOpt(const Key: string): specialize TOption<Double>;
var
  Value: string;
  DoubleValue: Double;
begin
  if FLegacyArgs.TryGetValue(Key, Value) and TryStrToFloat(Value, DoubleValue) then
    Result := specialize TOption<Double>.Some(DoubleValue)
  else
    Result := specialize TOption<Double>.None;
end;

function TArgsModern.GetBoolOpt(const Key: string): specialize TOption<Boolean>;
var
  Value: string;
begin
  if FLegacyArgs.HasFlag(Key) then
    Exit(specialize TOption<Boolean>.Some(True));
  
  if FLegacyArgs.TryGetValue(Key, Value) then
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

function TArgsModern.GetIntRange(const Key: string; Min, Max: Int64): TArgsResultInt;
var
  IntResult: TArgsResultInt;
begin
  IntResult := GetInt(Key);
  if IntResult.IsErr then
    Exit(IntResult);
  
  Result := ValidateRange(IntResult.Unwrap, Min, Max);
end;

function TArgsModern.GetPattern(const Key: string; const Pattern: string): TArgsResult;
var
  ValueResult: TArgsResult;
begin
  ValueResult := GetValue(Key);
  if ValueResult.IsErr then
    Exit(ValueResult);
  
  Result := ValidatePattern(ValueResult.Unwrap, Pattern);
end;

function TArgsModern.GetEnum(const Key: string; const ValidValues: array of string): TArgsResult;
var
  ValueResult: TArgsResult;
begin
  ValueResult := GetValue(Key);
  if ValueResult.IsErr then
    Exit(ValueResult);
  
  Result := ValidateEnum(ValueResult.Unwrap, ValidValues);
end;

function TArgsModern.Validate: IArgsValidator;
begin
  Result := TArgsValidator.Create(FLegacyArgs);
end;

function TArgsModern.AsLegacy: IArgs;
begin
  Result := FLegacyArgs;
end;

{ TArgsValidator }

constructor TArgsValidator.Create(const AArgs: IArgs);
begin
  inherited Create;
  FArgs := AArgs;
  SetLength(FRules, 0);
end;

procedure TArgsValidator.AddRule(const Rule: TValidationRule);
var
  Len: Integer;
begin
  Len := Length(FRules);
  SetLength(FRules, Len + 1);
  FRules[Len] := Rule;
end;

function TArgsValidator.Required(const Key: string): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrRequired;
  Rule.Key := Key;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.Optional(const Key: string): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrOptional;
  Rule.Key := Key;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.Range(const Key: string; Min, Max: Int64): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrRange;
  Rule.Key := Key;
  Rule.MinValue := Min;
  Rule.MaxValue := Max;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.Pattern(const Key: string; const RegexPattern: string): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrPattern;
  Rule.Key := Key;
  Rule.Pattern := RegexPattern;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.Enum(const Key: string; const ValidValues: array of string): IArgsValidator;
var
  Rule: TValidationRule;
  i: Integer;
begin
  Rule.RuleType := vrEnum;
  Rule.Key := Key;
  SetLength(Rule.ValidValues, Length(ValidValues));
  for i := Low(ValidValues) to High(ValidValues) do
    Rule.ValidValues[i] := ValidValues[i];
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.MutuallyExclusive(const Key1, Key2: string): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrMutuallyExclusive;
  Rule.Key := Key1;
  Rule.Key2 := Key2;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.AtLeastOne(const Keys: array of string): IArgsValidator;
var
  Rule: TValidationRule;
  i: Integer;
begin
  Rule.RuleType := vrAtLeastOne;
  SetLength(Rule.Keys, Length(Keys));
  for i := Low(Keys) to High(Keys) do
    Rule.Keys[i] := Keys[i];
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.PositionalCount(Min, Max: Integer): IArgsValidator;
var
  Rule: TValidationRule;
begin
  Rule.RuleType := vrPositionalCount;
  Rule.MinValue := Min;
  Rule.MaxValue := Max;
  AddRule(Rule);
  Result := Self;
end;

function TArgsValidator.Check: specialize TResult<Boolean, TArgsError>;
var
  i, j: Integer;
  Rule: TValidationRule;
  Value: string;
  IntValue: Int64;
  HasAny: Boolean;
  PosCount: Integer;
begin
  for i := Low(FRules) to High(FRules) do
  begin
    Rule := FRules[i];
    
    case Rule.RuleType of
      vrRequired:
        if not (FArgs.HasFlag(Rule.Key) or FArgs.TryGetValue(Rule.Key, Value)) then
          Exit(specialize TResult<Boolean, TArgsError>.Err(
            TArgsError.RequiredMissing(Rule.Key)));
      
      vrRange:
        if FArgs.TryGetValue(Rule.Key, Value) and TryStrToInt64(Value, IntValue) then
          if (IntValue < Rule.MinValue) or (IntValue > Rule.MaxValue) then
            Exit(specialize TResult<Boolean, TArgsError>.Err(
              TArgsError.ValidationError(Rule.Key, 
                Format('Value %d is out of range [%d, %d]', [IntValue, Rule.MinValue, Rule.MaxValue]))));
      
      vrMutuallyExclusive:
        if (FArgs.HasFlag(Rule.Key) or FArgs.TryGetValue(Rule.Key, Value)) and
           (FArgs.HasFlag(Rule.Key2) or FArgs.TryGetValue(Rule.Key2, Value)) then
          Exit(specialize TResult<Boolean, TArgsError>.Err(
            TArgsError.MutuallyExclusive(Rule.Key, Rule.Key2)));
      
      vrAtLeastOne:
        begin
          HasAny := False;
          for j := Low(Rule.Keys) to High(Rule.Keys) do
            if FArgs.HasFlag(Rule.Keys[j]) or FArgs.TryGetValue(Rule.Keys[j], Value) then
            begin
              HasAny := True;
              Break;
            end;
          if not HasAny then
            Exit(specialize TResult<Boolean, TArgsError>.Err(
              TArgsError.RequiredMissing('at least one of: ' + string.Join(', ', Rule.Keys))));
        end;
      
      vrPositionalCount:
        begin
          PosCount := Length(FArgs.Positionals);
          if PosCount < Rule.MinValue then
            Exit(specialize TResult<Boolean, TArgsError>.Err(
              TArgsError.TooFewPositionals(Rule.MinValue, PosCount)))
          else if PosCount > Rule.MaxValue then
            Exit(specialize TResult<Boolean, TArgsError>.Err(
              TArgsError.TooManyPositionals(Rule.MaxValue, PosCount)));
        end;
    end;
  end;
  
  Result := specialize TResult<Boolean, TArgsError>.Ok(True);
end;

function TArgsValidator.CheckAll: specialize TResult<Boolean, array of TArgsError>;
begin
  // 简化实现：返回第一个错误
  // 完整实现需要收集所有错误
  var SingleResult := Check;
  if SingleResult.IsErr then
  begin
    var Errors: array of TArgsError;
    SetLength(Errors, 1);
    Errors[0] := SingleResult.UnwrapErr;
    Result := specialize TResult<Boolean, array of TArgsError>.Err(Errors);
  end
  else
    Result := specialize TResult<Boolean, array of TArgsError>.Ok(True);
end;

// 便利函数实现
function ModernArgs(const A: IArgs): IArgsModern;
begin
  Result := TArgsModern.Create(A);
end;

function ModernArgsFromProcess: IArgsModern;
begin
  Result := TArgsModern.Create(TArgs.FromProcess);
end;

function ModernArgsFromArray(const Args: array of string; const Opts: TArgsOptions): IArgsModern;
begin
  Result := TArgsModern.Create(TArgs.FromArray(Args, Opts));
end;

end.
