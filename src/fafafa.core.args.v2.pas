unit fafafa.core.args.v2;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes
  {$IFDEF Windows}
  , Windows, ShellApi
  {$ENDIF}
  ;

type
  TStringArray = array of string;
  
  // 现代化错误处理系统
  TArgsErrorKind = (
    aekSuccess,
    aekUnknownOption,
    aekMissingValue,
    aekInvalidValue,
    aekDuplicateOption,
    aekMutuallyExclusive,
    aekRequiredMissing,
    aekTooManyPositionals,
    aekTooFewPositionals,
    aekParseError,
    aekValidationError
  );
  
  TArgsError = record
    Kind: TArgsErrorKind;
    Position: Integer;
    OptionName: string;
    Message: string;
    Suggestion: string;
    Context: string;
    
    class function Success: TArgsError; static;
    class function UnknownOption(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function MissingValue(const OptName: string; Pos: Integer = -1): TArgsError; static;
    class function InvalidValue(const OptName, ExpectedType, ActualValue: string; Pos: Integer = -1): TArgsError; static;
    
    function IsSuccess: Boolean; inline;
    function ToString: string;
    function ToDetailedString: string;
  end;
  
  // 简化的结果类型
  TArgsResult = record
    IsOk: Boolean;
    Value: string;
    Error: TArgsError;
  end;

  TArgsResultInt = record
    IsOk: Boolean;
    Value: Int64;
    Error: TArgsError;
  end;

  TArgsResultDouble = record
    IsOk: Boolean;
    Value: Double;
    Error: TArgsError;
  end;

  TArgsResultBool = record
    IsOk: Boolean;
    Value: Boolean;
    Error: TArgsError;
  end;
  
  // 高性能解析选项
  TArgsOptions = record
    CaseInsensitiveKeys: Boolean;
    AllowShortFlagsCombo: Boolean;
    AllowShortKeyValue: Boolean;
    StopAtDoubleDash: Boolean;
    TreatNegativeNumbersAsPositionals: Boolean;
    EnableNoPrefixNegation: Boolean;
    EnableCaching: Boolean;
    MaxCacheSize: Integer;
    
    class function Default: TArgsOptions; static;
    class function HighPerformance: TArgsOptions; static;
    class function Strict: TArgsOptions; static;
  end;
  
  TArgKind = (akArg, akOptionShort, akOptionLong);

  TArgItem = record
    Name: string;
    Value: string;
    HasValue: Boolean;
    Kind: TArgKind;
    Position: Integer;
  end;

  // 高性能上下文结构
  TArgsContext = record
    FFlags: TStringArray;
    FKeys: TStringArray;
    FValues: TStringArray;
    FPositionals: TStringArray;
    FItemNames: TStringArray;
    FItemValues: TStringArray;
    FItemHasValue: array of Boolean;
    FItemKinds: array of TArgKind;
    FItemPositions: array of Integer;
    FKeyLookup: array of record Key: string; Index: Integer; end;
    FFlagLookup: array of record Key: string; Value: Boolean; end;
    FKeyCount: Integer;
    FFlagCount: Integer;
    FInitialized: Boolean;
  end;



// 现代化解析函数 - 在 parser 单元中实现
// function ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;
// function ParseArgsWithCache(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext): TArgsError;

// 现代化 Result 风格 API - 在 impl 单元中实现
// function ArgsGetValue(const Key: string): TArgsResult;
// function ArgsGetInt(const Key: string): TArgsResultInt;
// function ArgsGetDouble(const Key: string): TArgsResultDouble;
// function ArgsGetBool(const Key: string): TArgsResultBool;

// 验证器类型
type
  TArgsValidator = function(const Value: string): TArgsError;

// 现代化接口设计
type
  IArgs = interface
    ['{E4F6A76C-4A13-4D4E-9D3A-7E8A3F2F3C21}']
    function Count: Integer;
    function Items(Index: Integer): TArgItem;
    function Positionals: TStringArray;
    
    // 现代化 Result 风格查询
    function GetValue(const Key: string): TArgsResult;
    function GetInt(const Key: string): TArgsResultInt;
    function GetDouble(const Key: string): TArgsResultDouble;
    function GetBool(const Key: string): TArgsResultBool;
    function GetAll(const Key: string): TStringArray;
    
    // 快速查询
    function HasFlag(const Name: string): Boolean;
    function TryGetValueFast(const Key: string; out Value: string): Boolean;
  end;
  
  // Fluent API 接口
  IArgsBuilder = interface
    ['{B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E}']
    function WithOption(const Name, Description: string; Required: Boolean = False): IArgsBuilder;
    function WithFlag(const Name, Description: string): IArgsBuilder;
    function WithPositional(const Name, Description: string; Required: Boolean = True): IArgsBuilder;
    function WithValidation(const Key: string; Validator: TArgsValidator): IArgsBuilder;
    function Parse(const Args: array of string): IArgs;
    function ParseProcess: IArgs;
  end;

type
  // 高性能参数解析器实现
  TArgsV2 = class(TInterfacedObject, IArgs)
  private
    FCtx: TArgsContext;
    FOpts: TArgsOptions;
    FInitialized: Boolean;

    procedure EnsureInitialized;
    function NormalizeKey(const Key: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    // 现代化工厂方法
    class function FromProcess(const Opts: TArgsOptions): TArgsV2; overload; static;
    class function FromProcess: TArgsV2; overload; static;
    class function FromArray(const A: array of string; const Opts: TArgsOptions): TArgsV2; static;
    class function FromArrayCached(const A: array of string; const Opts: TArgsOptions): TArgsV2; static;

    // IArgs 现代化实现
    function Count: Integer;
    function Items(Index: Integer): TArgItem;
    function Positionals: TStringArray;
    function GetValue(const Key: string): TArgsResult;
    function GetInt(const Key: string): TArgsResultInt;
    function GetDouble(const Key: string): TArgsResultDouble;
    function GetBool(const Key: string): TArgsResultBool;
    function GetAll(const Key: string): TStringArray;
    function HasFlag(const Name: string): Boolean;
    function TryGetValueFast(const Key: string; out Value: string): Boolean;
  end;

  TArgsBuilder = class(TInterfacedObject, IArgsBuilder)
  private
    FOptions: TArgsOptions;
    FOptionSpecs: array of record
      Name: string;
      Description: string;
      Required: Boolean;
      IsFlag: Boolean;
    end;
    FValidators: array of record
      Key: string;
      Validator: TArgsValidator;
    end;
  public
    constructor Create;
    function WithOption(const Name, Description: string; Required: Boolean = False): IArgsBuilder;
    function WithFlag(const Name, Description: string): IArgsBuilder;
    function WithPositional(const Name, Description: string; Required: Boolean = True): IArgsBuilder;
    function WithValidation(const Key: string; Validator: TArgsValidator): IArgsBuilder;
    function Parse(const Args: array of string): IArgs;
    function ParseProcess: IArgs;
  end;

// 现代化构建器工厂函数
function NewArgsBuilder: IArgsBuilder;
function Args: IArgsBuilder;

implementation

uses
  fafafa.core.args.v2.parser;

// TArgsError 实现
class function TArgsError.Success: TArgsError;
begin
  Result.Kind := aekSuccess;
  Result.Position := -1;
  Result.OptionName := '';
  Result.Message := '';
  Result.Suggestion := '';
  Result.Context := '';
end;

class function TArgsError.UnknownOption(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekUnknownOption;
  Result.Position := Pos;
  Result.OptionName := OptName;
  Result.Message := Format('Unknown option: %s', [OptName]);
  Result.Suggestion := 'Check available options with --help';
  Result.Context := '';
end;

class function TArgsError.MissingValue(const OptName: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekMissingValue;
  Result.Position := Pos;
  Result.OptionName := OptName;
  Result.Message := Format('Option %s requires a value', [OptName]);
  Result.Suggestion := Format('Use %s=<value> or %s <value>', [OptName, OptName]);
  Result.Context := '';
end;

class function TArgsError.InvalidValue(const OptName, ExpectedType, ActualValue: string; Pos: Integer): TArgsError;
begin
  Result.Kind := aekInvalidValue;
  Result.Position := Pos;
  Result.OptionName := OptName;
  Result.Message := Format('Invalid value for %s: expected %s, got "%s"', [OptName, ExpectedType, ActualValue]);
  Result.Suggestion := Format('Provide a valid %s value', [ExpectedType]);
  Result.Context := '';
end;

function TArgsError.IsSuccess: Boolean;
begin
  Result := Kind = aekSuccess;
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
  end;

  Result := Format('[%s] %s', [KindStr, Message]);
  
  if Position >= 0 then
    Result := Result + Format(' (position: %d)', [Position]);
    
  if Suggestion <> '' then
    Result := Result + Format(' Suggestion: %s', [Suggestion]);
end;

// TArgsOptions 实现
class function TArgsOptions.Default: TArgsOptions;
begin
  Result.CaseInsensitiveKeys := True;
  Result.AllowShortFlagsCombo := True;
  Result.AllowShortKeyValue := True;
  Result.StopAtDoubleDash := True;
  Result.TreatNegativeNumbersAsPositionals := True;
  Result.EnableNoPrefixNegation := True;
  Result.EnableCaching := True;
  Result.MaxCacheSize := 100;
end;

class function TArgsOptions.HighPerformance: TArgsOptions;
begin
  Result := Default;
  Result.EnableCaching := True;
  Result.MaxCacheSize := 1000;
end;

class function TArgsOptions.Strict: TArgsOptions;
begin
  Result := Default;
  Result.CaseInsensitiveKeys := False;
  Result.AllowShortFlagsCombo := False;
  Result.EnableNoPrefixNegation := False;
end;



// 简化实现，移除复杂的缓存系统

// 辅助函数
function ArgsResultOk(const Value: string): TArgsResult;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultErr(const Error: TArgsError): TArgsResult;
begin
  Result.IsOk := False;
  Result.Value := '';
  Result.Error := Error;
end;

function ArgsResultIntOk(const Value: Int64): TArgsResultInt;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultIntErr(const Error: TArgsError): TArgsResultInt;
begin
  Result.IsOk := False;
  Result.Value := 0;
  Result.Error := Error;
end;

function ArgsResultDoubleOk(const Value: Double): TArgsResultDouble;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultDoubleErr(const Error: TArgsError): TArgsResultDouble;
begin
  Result.IsOk := False;
  Result.Value := 0.0;
  Result.Error := Error;
end;

function ArgsResultBoolOk(const Value: Boolean): TArgsResultBool;
begin
  Result.IsOk := True;
  Result.Value := Value;
  Result.Error := TArgsError.Success;
end;

function ArgsResultBoolErr(const Error: TArgsError): TArgsResultBool;
begin
  Result.IsOk := False;
  Result.Value := False;
  Result.Error := Error;
end;

// TArgsV2 基本实现
constructor TArgsV2.Create;
begin
  inherited Create;
  SetLength(FCtx.FFlags, 0);
  SetLength(FCtx.FKeys, 0);
  SetLength(FCtx.FValues, 0);
  SetLength(FCtx.FPositionals, 0);
  SetLength(FCtx.FItemNames, 0);
  SetLength(FCtx.FItemValues, 0);
  SetLength(FCtx.FItemHasValue, 0);
  SetLength(FCtx.FItemKinds, 0);
  SetLength(FCtx.FItemPositions, 0);
  SetLength(FCtx.FKeyLookup, 0);
  SetLength(FCtx.FFlagLookup, 0);
  FCtx.FKeyCount := 0;
  FCtx.FFlagCount := 0;
  FCtx.FInitialized := True;
  FOpts := TArgsOptions.Default;
  FInitialized := False;
end;

destructor TArgsV2.Destroy;
begin
  inherited Destroy;
end;

procedure TArgsV2.EnsureInitialized;
begin
  if not FInitialized then
    raise Exception.Create('Args not initialized');
end;

function TArgsV2.NormalizeKey(const Key: string): string;
begin
  Result := LowerCase(Key);
end;

class function TArgsV2.FromProcess(const Opts: TArgsOptions): TArgsV2;
var
  args: TStringArray;
  i: Integer;
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;

  // 收集进程参数
  SetLength(args, ParamCount);
  for i := 1 to ParamCount do
    args[i-1] := ParamStr(i);

  // 解析参数
  err := ParseArgs(args, Opts, Result.FCtx);
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);

  Result.FInitialized := True;
end;

class function TArgsV2.FromProcess: TArgsV2;
begin
  Result := FromProcess(TArgsOptions.Default);
end;

class function TArgsV2.FromArray(const A: array of string; const Opts: TArgsOptions): TArgsV2;
var
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;

  // 解析参数数组
  err := ParseArgs(A, Opts, Result.FCtx);
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);

  Result.FInitialized := True;
end;

class function TArgsV2.FromArrayCached(const A: array of string; const Opts: TArgsOptions): TArgsV2;
var
  err: TArgsError;
begin
  Result := TArgsV2.Create;
  Result.FOpts := Opts;

  // 使用缓存解析
  err := ParseArgsWithCache(A, Opts, Result.FCtx);
  if not err.IsSuccess then
    raise Exception.Create(err.ToDetailedString);

  Result.FInitialized := True;
end;

function TArgsV2.Count: Integer;
begin
  EnsureInitialized;
  Result := Length(FCtx.FItemNames);
end;

function TArgsV2.Items(Index: Integer): TArgItem;
begin
  EnsureInitialized;
  if (Index >= 0) and (Index < Length(FCtx.FItemNames)) then
  begin
    Result.Name := FCtx.FItemNames[Index];
    Result.Value := FCtx.FItemValues[Index];
    Result.HasValue := FCtx.FItemHasValue[Index];
    Result.Kind := FCtx.FItemKinds[Index];
    Result.Position := FCtx.FItemPositions[Index];
  end
  else
  begin
    Result.Name := '';
    Result.Value := '';
    Result.HasValue := False;
    Result.Kind := akArg;
    Result.Position := -1;
  end;
end;

function TArgsV2.Positionals: TStringArray;
begin
  EnsureInitialized;
  Result := FCtx.FPositionals;
end;

function TArgsV2.GetValue(const Key: string): TArgsResult;
var
  i: Integer;
  normKey: string;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);

  // 在键查找表中查找
  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
    begin
      if (FCtx.FKeyLookup[i].Index >= 0) and (FCtx.FKeyLookup[i].Index < Length(FCtx.FValues)) then
      begin
        Result := ArgsResultOk(FCtx.FValues[FCtx.FKeyLookup[i].Index]);
        Exit;
      end;
    end;
  end;

  Result := ArgsResultErr(TArgsError.UnknownOption(Key));
end;

function TArgsV2.GetInt(const Key: string): TArgsResultInt;
var
  valueResult: TArgsResult;
  intValue: Int64;
begin
  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    if TryStrToInt64(valueResult.Value, intValue) then
      Result := ArgsResultIntOk(intValue)
    else
      Result := ArgsResultIntErr(TArgsError.InvalidValue(Key, 'integer', valueResult.Value));
  end
  else
    Result := ArgsResultIntErr(valueResult.Error);
end;

function TArgsV2.GetDouble(const Key: string): TArgsResultDouble;
var
  valueResult: TArgsResult;
  doubleValue: Double;
begin
  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    if TryStrToFloat(valueResult.Value, doubleValue) then
      Result := ArgsResultDoubleOk(doubleValue)
    else
      Result := ArgsResultDoubleErr(TArgsError.InvalidValue(Key, 'number', valueResult.Value));
  end
  else
    Result := ArgsResultDoubleErr(valueResult.Error);
end;

function TArgsV2.GetBool(const Key: string): TArgsResultBool;
var
  valueResult: TArgsResult;
  value: string;
begin
  // 首先检查是否是标志
  if HasFlag(Key) then
    Exit(ArgsResultBoolOk(True));

  valueResult := GetValue(Key);
  if valueResult.IsOk then
  begin
    value := LowerCase(Trim(valueResult.Value));
    if (value = 'true') or (value = '1') or (value = 'yes') or (value = 'on') then
      Result := ArgsResultBoolOk(True)
    else if (value = 'false') or (value = '0') or (value = 'no') or (value = 'off') then
      Result := ArgsResultBoolOk(False)
    else
      Result := ArgsResultBoolErr(TArgsError.InvalidValue(Key, 'boolean', valueResult.Value));
  end
  else
    Result := ArgsResultBoolErr(valueResult.Error);
end;

function TArgsV2.GetAll(const Key: string): TStringArray;
var
  i, matchCount: Integer;
  normKey: string;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);

  // 计算匹配的数量
  matchCount := 0;
  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
      Inc(matchCount);
  end;

  // 分配数组并填充
  SetLength(Result, matchCount);
  matchCount := 0;
  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
    begin
      if (FCtx.FKeyLookup[i].Index >= 0) and (FCtx.FKeyLookup[i].Index < Length(FCtx.FValues)) then
      begin
        Result[matchCount] := FCtx.FValues[FCtx.FKeyLookup[i].Index];
        Inc(matchCount);
      end;
    end;
  end;
end;

function TArgsV2.HasFlag(const Name: string): Boolean;
var
  i: Integer;
  normName: string;
begin
  EnsureInitialized;
  normName := NormalizeKey(Name);
  Result := False;

  // 在标志查找表中查找
  for i := 0 to FCtx.FFlagCount - 1 do
  begin
    if LowerCase(FCtx.FFlagLookup[i].Key) = LowerCase(normName) then
    begin
      Result := FCtx.FFlagLookup[i].Value;
      Exit;
    end;
  end;
end;

function TArgsV2.TryGetValueFast(const Key: string; out Value: string): Boolean;
var
  i: Integer;
  normKey: string;
begin
  EnsureInitialized;
  normKey := NormalizeKey(Key);
  Result := False;
  Value := '';

  // 快速查找
  for i := 0 to FCtx.FKeyCount - 1 do
  begin
    if LowerCase(FCtx.FKeyLookup[i].Key) = LowerCase(normKey) then
    begin
      if (FCtx.FKeyLookup[i].Index >= 0) and (FCtx.FKeyLookup[i].Index < Length(FCtx.FValues)) then
      begin
        Value := FCtx.FValues[FCtx.FKeyLookup[i].Index];
        Result := True;
      end;
      Exit;
    end;
  end;
end;

// TArgsBuilder 基本实现
constructor TArgsBuilder.Create;
begin
  inherited Create;
  FOptions := TArgsOptions.Default;
end;

function TArgsBuilder.WithOption(const Name, Description: string; Required: Boolean): IArgsBuilder;
begin
  Result := Self;
end;

function TArgsBuilder.WithFlag(const Name, Description: string): IArgsBuilder;
begin
  Result := Self;
end;

function TArgsBuilder.WithPositional(const Name, Description: string; Required: Boolean): IArgsBuilder;
begin
  Result := Self;
end;

function TArgsBuilder.WithValidation(const Key: string; Validator: TArgsValidator): IArgsBuilder;
begin
  Result := Self;
end;

function TArgsBuilder.Parse(const Args: array of string): IArgs;
begin
  Result := TArgsV2.FromArray(Args, FOptions);
end;

function TArgsBuilder.ParseProcess: IArgs;
begin
  Result := TArgsV2.FromProcess(FOptions);
end;

// 工厂函数
function NewArgsBuilder: IArgsBuilder;
begin
  Result := TArgsBuilder.Create;
end;

function Args: IArgsBuilder;
begin
  Result := NewArgsBuilder;
end;

end.
