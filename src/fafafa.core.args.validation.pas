unit fafafa.core.args.validation;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, RegExpr,
  fafafa.core.base,  // ✅ ARGS-001: 引入 ECore 基类
  fafafa.core.args,
  fafafa.core.args.base,  // TStringArray
  fafafa.core.args.errors,
  fafafa.core.args.schema,
  fafafa.core.args.utils,
  fafafa.core.result;

type
  // 验证器类型
  TValidatorType = (
    vtRequired,           // 必需参数
    vtOptional,           // 可选参数
    vtRange,              // 数值范围
    vtMinLength,          // 最小长度
    vtMaxLength,          // 最大长度
    vtPattern,            // 正则表达式
    vtEnum,               // 枚举值
    vtEmail,              // 邮箱格式
    vtUrl,                // URL 格式
    vtIPAddress,          // IP 地址
    vtPort,               // 端口号
    vtFile,               // 文件存在
    vtDirectory,          // 目录存在
    vtCustom              // 自定义验证
  );

  // 自定义验证函数类型
  TCustomValidator = function(const Value: string; out ErrorMsg: string): Boolean;

  // 验证规则
  TValidationRule = record
    ValidatorType: TValidatorType;
    Key: string;
    MinValue: Int64;
    MaxValue: Int64;
    Pattern: string;
    ValidValues: TStringArray;
    CustomValidator: TCustomValidator;
    ErrorMessage: string;

    class function Required(const AKey: string): TValidationRule; static;
    class function Optional(const AKey: string): TValidationRule; static;
    class function Range(const AKey: string; AMin, AMax: Int64): TValidationRule; static;
    class function MinLength(const AKey: string; AMinLen: Integer): TValidationRule; static;
    class function MaxLength(const AKey: string; AMaxLen: Integer): TValidationRule; static;
    class function MatchPattern(const AKey, APattern: string): TValidationRule; static;
    class function Enum(const AKey: string; const AValidValues: array of string): TValidationRule; static;
    class function Email(const AKey: string): TValidationRule; static;
    class function Url(const AKey: string): TValidationRule; static;
    class function IPAddress(const AKey: string): TValidationRule; static;
    class function Port(const AKey: string): TValidationRule; static;
    class function FileExists(const AKey: string): TValidationRule; static;
    class function DirectoryExists(const AKey: string): TValidationRule; static;
    class function Custom(const AKey: string; AValidator: TCustomValidator; const AErrorMsg: string = ''): TValidationRule; static;
  end;

  // 验证结果
  TValidationResult = record
    IsValid: Boolean;
    Errors: array of TArgsError;

    class function Success: TValidationResult; static;
    class function Failure(const AErrors: array of TArgsError): TValidationResult; static;
    function AddError(const AError: TArgsError): TValidationResult;
    function GetFirstError: TArgsError;
    function HasErrors: Boolean;
    function ErrorCount: Integer;
  end;

  // 参数验证器
  TArgsValidator = class
  private
    FArgs: IArgs;
    FRules: array of TValidationRule;
    FStopOnFirstError: Boolean;

    function ValidateRule(const Rule: TValidationRule): TArgsError;
    function ValidateRequired(const Key: string): TArgsError;
    function ValidateRange(const Key: string; Min, Max: Int64): TArgsError;
    function ValidateLength(const Key: string; MinLen, MaxLen: Integer): TArgsError;
    function ValidatePattern(const Key, Pattern: string): TArgsError;
    function ValidateEnum(const Key: string; const ValidValues: TStringArray): TArgsError;
    function ValidateEmail(const Key: string): TArgsError;
    function ValidateUrl(const Key: string): TArgsError;
    function ValidateIPAddress(const Key: string): TArgsError;
    function ValidatePort(const Key: string): TArgsError;
    function ValidateFileExists(const Key: string): TArgsError;
    function ValidateDirectoryExists(const Key: string): TArgsError;
    function ValidateCustom(const Key: string; Validator: TCustomValidator; const ErrorMsg: string): TArgsError;

  public
    constructor Create(const AArgs: IArgs);

    // 添加验证规则
    function AddRule(const Rule: TValidationRule): TArgsValidator;
    function Required(const Key: string): TArgsValidator;
    function Optional(const Key: string): TArgsValidator;
    function Range(const Key: string; Min, Max: Int64): TArgsValidator;
    function MinLength(const Key: string; MinLen: Integer): TArgsValidator;
    function MaxLength(const Key: string; MaxLen: Integer): TArgsValidator;
    function Pattern(const Key, APattern: string): TArgsValidator;
    function Enum(const Key: string; const ValidValues: array of string): TArgsValidator;
    function Email(const Key: string): TArgsValidator;
    function Url(const Key: string): TArgsValidator;
    function IPAddress(const Key: string): TArgsValidator;
    function Port(const Key: string): TArgsValidator;
    function FileExists(const Key: string): TArgsValidator;
    function DirectoryExists(const Key: string): TArgsValidator;
    function Custom(const Key: string; Validator: TCustomValidator; const ErrorMsg: string = ''): TArgsValidator;

    // 配置选项
    function StopOnFirstError(AStop: Boolean = True): TArgsValidator;

    // 执行验证
    function Validate: TValidationResult;
    function ValidateAndThrow: Boolean;  // 验证失败时抛出异常
  end;

  // 验证异常
  TArgsErrors = array of TArgsError;

  EArgsValidationException = class(ECore)  // ✅ ARGS-001: 继承自 ECore
  private
    FErrors: TArgsErrors;
  public
    constructor Create(const AErrors: array of TArgsError);
    function GetErrors: TArgsErrors;
  end;

// 便利函数
function ValidateArgs(const Args: IArgs): TArgsValidator;

// Spec-based strict validation (schema bridge)
function ValidateArgsAgainstSpec(const Args: IArgs; const Spec: IArgsCommandSpec; const Opts: TArgsOptions): TValidationResult;

// 预定义验证器
function IsValidEmail(const Email: string): Boolean;
function IsValidUrl(const Url: string): Boolean;
function IsValidIPAddress(const IP: string): Boolean;
function IsValidPort(const Port: string): Boolean;

implementation

uses
  fafafa.core.sync.mutex;

const
  // ✅ S1 修复: 输入长度限制常量（防止 ReDoS）
  MAX_EMAIL_LENGTH = 254;    // RFC 5321
  MAX_URL_LENGTH = 2048;     // 常见浏览器限制
  MAX_IP_LENGTH = 45;        // IPv6 最大长度

  // 正则表达式模式（配合长度限制使用）
  EMAIL_PATTERN = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  URL_PATTERN = '^https?://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})?(?:/.*)?$';
  IPV4_PATTERN = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';

var
  // ✅ S1/P2: 缓存编译后的正则表达式
  // 注意：TRegExpr.Exec 不是可重入/线程安全的，因此必须用锁保护 Exec。
  _CachedEmailRegex: TRegExpr = nil;
  _CachedUrlRegex: TRegExpr = nil;
  _CachedIPv4Regex: TRegExpr = nil;

  _EmailRegexLock: IMutex = nil;
  _UrlRegexLock: IMutex = nil;
  _IPv4RegexLock: IMutex = nil;

{ TValidationRule }

// ✅ D1 修复: 所有工厂方法使用 Default() 初始化，确保托管类型字段正确初始化

class function TValidationRule.Required(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtRequired;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Required parameter "%s" is missing', [AKey]);
end;

class function TValidationRule.Optional(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtOptional;
  Result.Key := AKey;
end;

class function TValidationRule.Range(const AKey: string; AMin, AMax: Int64): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtRange;
  Result.Key := AKey;
  Result.MinValue := AMin;
  Result.MaxValue := AMax;
  Result.ErrorMessage := Format('Parameter "%s" must be between %d and %d', [AKey, AMin, AMax]);
end;

class function TValidationRule.MinLength(const AKey: string; AMinLen: Integer): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtMinLength;
  Result.Key := AKey;
  Result.MinValue := AMinLen;
  Result.ErrorMessage := Format('Parameter "%s" must be at least %d characters long', [AKey, AMinLen]);
end;

class function TValidationRule.MaxLength(const AKey: string; AMaxLen: Integer): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtMaxLength;
  Result.Key := AKey;
  Result.MaxValue := AMaxLen;
  Result.ErrorMessage := Format('Parameter "%s" must be at most %d characters long', [AKey, AMaxLen]);
end;

class function TValidationRule.MatchPattern(const AKey, APattern: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtPattern;
  Result.Key := AKey;
  Result.Pattern := APattern;
  Result.ErrorMessage := Format('Parameter "%s" does not match required pattern', [AKey]);
end;

class function TValidationRule.Enum(const AKey: string; const AValidValues: array of string): TValidationRule;
var
  i: Integer;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtEnum;
  Result.Key := AKey;
  SetLength(Result.ValidValues, Length(AValidValues));
  for i := Low(AValidValues) to High(AValidValues) do
    Result.ValidValues[i] := AValidValues[i];
  Result.ErrorMessage := Format('Parameter "%s" must be one of: %s', [AKey, string.Join(', ', Result.ValidValues)]);
end;

class function TValidationRule.Email(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtEmail;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid email address', [AKey]);
end;

class function TValidationRule.Url(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtUrl;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid URL', [AKey]);
end;

class function TValidationRule.IPAddress(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtIPAddress;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid IP address', [AKey]);
end;

class function TValidationRule.Port(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtPort;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid port number (1-65535)', [AKey]);
end;

class function TValidationRule.FileExists(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtFile;
  Result.Key := AKey;
  Result.ErrorMessage := Format('File specified in parameter "%s" does not exist', [AKey]);
end;

class function TValidationRule.DirectoryExists(const AKey: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtDirectory;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Directory specified in parameter "%s" does not exist', [AKey]);
end;

class function TValidationRule.Custom(const AKey: string; AValidator: TCustomValidator; const AErrorMsg: string): TValidationRule;
begin
  Result := Default(TValidationRule);
  Result.ValidatorType := vtCustom;
  Result.Key := AKey;
  Result.CustomValidator := AValidator;
  if AErrorMsg <> '' then
    Result.ErrorMessage := AErrorMsg
  else
    Result.ErrorMessage := Format('Parameter "%s" failed custom validation', [AKey]);
end;

{ TValidationResult }

class function TValidationResult.Success: TValidationResult;
begin
  Result.IsValid := True;
  SetLength(Result.Errors, 0);
end;

class function TValidationResult.Failure(const AErrors: array of TArgsError): TValidationResult;
var
  i: Integer;
begin
  Result.IsValid := False;
  SetLength(Result.Errors, Length(AErrors));
  for i := Low(AErrors) to High(AErrors) do
    Result.Errors[i] := AErrors[i];
end;

function TValidationResult.AddError(const AError: TArgsError): TValidationResult;
var
  Len: Integer;
begin
  Result := Self;
  Result.IsValid := False;
  Len := Length(Result.Errors);
  SetLength(Result.Errors, Len + 1);
  Result.Errors[Len] := AError;
end;

function TValidationResult.GetFirstError: TArgsError;
begin
  if Length(Errors) > 0 then
    Result := Errors[0]
  else
    Result := TArgsError.ParseError('No errors available');
end;

function TValidationResult.HasErrors: Boolean;
begin
  Result := Length(Errors) > 0;
end;

function TValidationResult.ErrorCount: Integer;
begin
  Result := Length(Errors);
end;

{ TArgsValidator }

constructor TArgsValidator.Create(const AArgs: IArgs);
begin
  inherited Create;
  FArgs := AArgs;
  SetLength(FRules, 0);
  FStopOnFirstError := False;
end;

function TArgsValidator.AddRule(const Rule: TValidationRule): TArgsValidator;
var
  Len: Integer;
begin
  Len := Length(FRules);
  SetLength(FRules, Len + 1);
  FRules[Len] := Rule;
  Result := Self;
end;

function TArgsValidator.Required(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Required(Key));
end;

function TArgsValidator.Optional(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Optional(Key));
end;

function TArgsValidator.Range(const Key: string; Min, Max: Int64): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Range(Key, Min, Max));
end;

function TArgsValidator.MinLength(const Key: string; MinLen: Integer): TArgsValidator;
begin
  Result := AddRule(TValidationRule.MinLength(Key, MinLen));
end;

function TArgsValidator.MaxLength(const Key: string; MaxLen: Integer): TArgsValidator;
begin
  Result := AddRule(TValidationRule.MaxLength(Key, MaxLen));
end;

function TArgsValidator.Pattern(const Key, APattern: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.MatchPattern(Key, APattern));
end;

function TArgsValidator.Enum(const Key: string; const ValidValues: array of string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Enum(Key, ValidValues));
end;

function TArgsValidator.Email(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Email(Key));
end;

function TArgsValidator.Url(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Url(Key));
end;

function TArgsValidator.IPAddress(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.IPAddress(Key));
end;

function TArgsValidator.Port(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Port(Key));
end;

function TArgsValidator.FileExists(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.FileExists(Key));
end;

function TArgsValidator.DirectoryExists(const Key: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.DirectoryExists(Key));
end;

function TArgsValidator.Custom(const Key: string; Validator: TCustomValidator; const ErrorMsg: string): TArgsValidator;
begin
  Result := AddRule(TValidationRule.Custom(Key, Validator, ErrorMsg));
end;

function TArgsValidator.StopOnFirstError(AStop: Boolean): TArgsValidator;
begin
  FStopOnFirstError := AStop;
  Result := Self;
end;

function TArgsValidator.ValidateRule(const Rule: TValidationRule): TArgsError;
begin
  case Rule.ValidatorType of
    vtRequired: Result := ValidateRequired(Rule.Key);
    vtOptional: Result := TArgsError.Success; // 可选参数总是通过
    vtRange: Result := ValidateRange(Rule.Key, Rule.MinValue, Rule.MaxValue);
    vtMinLength: Result := ValidateLength(Rule.Key, Rule.MinValue, MaxInt);
    vtMaxLength: Result := ValidateLength(Rule.Key, 0, Rule.MaxValue);
    vtPattern: Result := ValidatePattern(Rule.Key, Rule.Pattern);
    vtEnum: Result := ValidateEnum(Rule.Key, Rule.ValidValues);
    vtEmail: Result := ValidateEmail(Rule.Key);
    vtUrl: Result := ValidateUrl(Rule.Key);
    vtIPAddress: Result := ValidateIPAddress(Rule.Key);
    vtPort: Result := ValidatePort(Rule.Key);
    vtFile: Result := ValidateFileExists(Rule.Key);
    vtDirectory: Result := ValidateDirectoryExists(Rule.Key);
    vtCustom: Result := ValidateCustom(Rule.Key, Rule.CustomValidator, Rule.ErrorMessage);
  else
    Result := TArgsError.ParseError('Unknown validation rule type');
  end;
end;

function TArgsValidator.ValidateRequired(const Key: string): TArgsError;
var
  Value: string;
begin
  if FArgs.HasFlag(Key) or FArgs.TryGetValue(Key, Value) then
    Result := TArgsError.Success // ✅ P0-1 修复: 使用 Success 而非空 ParseError
  else
    Result := TArgsError.RequiredMissing(Key);
end;

function TArgsValidator.ValidateRange(const Key: string; Min, Max: Int64): TArgsError;
var
  Value: string;
  IntValue: Int64;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if not TryStrToInt64(Value, IntValue) then
    Exit(TArgsError.InvalidValue(Key, 'integer', Value));

  if (IntValue < Min) or (IntValue > Max) then
    Result := TArgsError.ValidationError(Key, Format('Value %d is out of range [%d, %d]', [IntValue, Min, Max]))
  else
    Result := TArgsError.Success; // ✅ P0-1 修复
end;

function TArgsValidator.ValidateLength(const Key: string; MinLen, MaxLen: Integer): TArgsError;
var
  Value: string;
  Len: Integer;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  Len := Length(Value);
  if (Len < MinLen) or (Len > MaxLen) then
    Result := TArgsError.ValidationError(Key, Format('Length %d is out of range [%d, %d]', [Len, MinLen, MaxLen]))
  else
    Result := TArgsError.Success; // ✅ P0-1 修复
end;

function TArgsValidator.ValidatePattern(const Key, Pattern: string): TArgsError;
var
  Value: string;
  RegEx: TRegExpr;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := Pattern;
    if RegEx.Exec(Value) then
      Result := TArgsError.Success // ✅ P0-1 修复
    else
      Result := TArgsError.ValidationError(Key, Format('Value "%s" does not match pattern "%s"', [Value, Pattern]));
  finally
    RegEx.Free;
  end;
end;

function TArgsValidator.ValidateEnum(const Key: string; const ValidValues: TStringArray): TArgsError;
var
  Value: string;
  i: Integer;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  for i := Low(ValidValues) to High(ValidValues) do
    if SameText(Value, ValidValues[i]) then
      Exit(TArgsError.Success); // ✅ P0-1 修复

  Result := TArgsError.ValidationError(Key, Format('Invalid value "%s". Valid values: %s', [Value, string.Join(', ', ValidValues)]));
end;

function TArgsValidator.ValidateEmail(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if IsValidEmail(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid email address', [Value]));
end;

function TArgsValidator.ValidateUrl(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if IsValidUrl(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid URL', [Value]));
end;

function TArgsValidator.ValidateIPAddress(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if IsValidIPAddress(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid IP address', [Value]));
end;

function TArgsValidator.ValidatePort(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if IsValidPort(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid port number', [Value]));
end;

function TArgsValidator.ValidateFileExists(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if SysUtils.FileExists(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('File "%s" does not exist', [Value]));
end;

function TArgsValidator.ValidateDirectoryExists(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if SysUtils.DirectoryExists(Value) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
    Result := TArgsError.ValidationError(Key, Format('Directory "%s" does not exist', [Value]));
end;

function TArgsValidator.ValidateCustom(const Key: string; Validator: TCustomValidator; const ErrorMsg: string): TArgsError;
var
  Value: string;
  CustomErrorMsg: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.Success); // 可选参数，跳过验证

  if Validator(Value, CustomErrorMsg) then
    Result := TArgsError.Success // ✅ P0-1 修复
  else
  begin
    if CustomErrorMsg <> '' then
      Result := TArgsError.ValidationError(Key, CustomErrorMsg)
    else
      Result := TArgsError.ValidationError(Key, ErrorMsg);
  end;
end;

function TArgsValidator.Validate: TValidationResult;
var
  i: Integer;
  Error: TArgsError;
begin
  Result := TValidationResult.Success;

  for i := Low(FRules) to High(FRules) do
  begin
    Error := ValidateRule(FRules[i]);
    if not Error.IsSuccess then // ✅ P0-1 修复: 使用 IsSuccess 语义检查
    begin
      Result := Result.AddError(Error);
      if FStopOnFirstError then
        Break;
    end;
  end;
end;

function TArgsValidator.ValidateAndThrow: Boolean;
var
  ValidationResult: TValidationResult;
begin
  ValidationResult := Validate;
  if not ValidationResult.IsValid then
    raise EArgsValidationException.Create(ValidationResult.Errors);
  Result := True;
end;

{ EArgsValidationException }

constructor EArgsValidationException.Create(const AErrors: array of TArgsError);
var
  i: Integer;
  Msg: string;
begin
  SetLength(FErrors, Length(AErrors));
  for i := Low(AErrors) to High(AErrors) do
    FErrors[i] := AErrors[i];

  if Length(AErrors) = 1 then
    Msg := AErrors[0].ToString
  else
  begin
    Msg := Format('Validation failed with %d errors:', [Length(AErrors)]);
    for i := Low(AErrors) to High(AErrors) do
      Msg := Msg + sLineBreak + '  - ' + AErrors[i].ToString;
  end;

  inherited Create(Msg);
end;

function EArgsValidationException.GetErrors: TArgsErrors;
begin
  Result := FErrors;
end;

// 便利函数实现
function ValidateArgs(const Args: IArgs): TArgsValidator;
begin
  Result := TArgsValidator.Create(Args);
end;

function FindFlagSpecByKey(const Spec: IArgsCommandSpec; const Key: string; const Opts: TArgsOptions): IArgsFlagSpec;
var
  i, j: Integer;
  F: IArgsFlagSpec;
  Aliases: fafafa.core.args.schema.TStringArray;
  Canon: string;
begin
  Result := nil;
  if Spec = nil then Exit;

  for i := 0 to Spec.FlagCount - 1 do
  begin
    F := Spec.FlagAt(i);
    if F = nil then Continue;

    Canon := NormalizeKey(F.Name, Opts.CaseInsensitiveKeys);
    if Canon = Key then Exit(F);

    Aliases := F.Aliases;
    for j := Low(Aliases) to High(Aliases) do
      if NormalizeKey(Aliases[j], Opts.CaseInsensitiveKeys) = Key then
        Exit(F);
  end;
end;

function SpecFlagIsPresentInArgs(const Args: IArgs; const F: IArgsFlagSpec; const Opts: TArgsOptions): Boolean;
var
  Dummy: string;
  i: Integer;
  Aliases: fafafa.core.args.schema.TStringArray;
  IsBool: Boolean;
begin
  Result := False;
  if (Args = nil) or (F = nil) then Exit;

  IsBool := SameText(F.ValueType, 'bool');

  // Check canonical name
  if IsBool then
  begin
    if Args.HasFlag(F.Name) then Exit(True);
    if Args.TryGetValue(F.Name, Dummy) then Exit(True);
  end
  else
  begin
    if Args.TryGetValue(F.Name, Dummy) then Exit(True);
  end;

  // Check aliases
  Aliases := F.Aliases;
  for i := Low(Aliases) to High(Aliases) do
  begin
    if IsBool then
    begin
      if Args.HasFlag(Aliases[i]) then Exit(True);
      if Args.TryGetValue(Aliases[i], Dummy) then Exit(True);
    end
    else
    begin
      if Args.TryGetValue(Aliases[i], Dummy) then Exit(True);
    end;
  end;
end;

function ValidateArgsAgainstSpec(const Args: IArgs; const Spec: IArgsCommandSpec; const Opts: TArgsOptions): TValidationResult;
var
  i: Integer;
  It: TArgItem;
  F: IArgsFlagSpec;
  BaseKey: string;
  CanonName: string;
begin
  Result := TValidationResult.Success;

  if (Args = nil) or (Spec = nil) then
    Exit;

  // 1) Validate each encountered option token: unknown options, missing values, etc.
  for i := 0 to Args.Count - 1 do
  begin
    It := Args.Items(i);

    // Skip positionals
    if It.Kind = akArg then
      Continue;

    if It.Name = '' then
      Continue;

    F := FindFlagSpecByKey(Spec, It.Name, Opts);

    // Allow internal no.* marker when no-prefix negation is enabled.
    if (F = nil)
      and Opts.EnableNoPrefixNegation
      and StartsWith(It.Name, 'no.') then
    begin
      BaseKey := Copy(It.Name, Length('no.') + 1, MaxInt);
      F := FindFlagSpecByKey(Spec, BaseKey, Opts);
      if (F <> nil) and SameText(F.ValueType, 'bool') then
        Continue; // ignore internal marker
    end;

    if F = nil then
    begin
      Result := Result.AddError(TArgsError.UnknownOption(It.Name, It.Position));
      Continue;
    end;

    // Missing value: non-bool flags require a value token.
    if (not SameText(F.ValueType, 'bool')) and (not It.HasValue) then
      Result := Result.AddError(TArgsError.MissingValue(It.Name, It.Position));
  end;

  // 2) Validate required flags.
  for i := 0 to Spec.FlagCount - 1 do
  begin
    F := Spec.FlagAt(i);
    if (F = nil) or (not F.Required) then
      Continue;

    if not SpecFlagIsPresentInArgs(Args, F, Opts) then
    begin
      CanonName := NormalizeKey(F.Name, Opts.CaseInsensitiveKeys);
      Result := Result.AddError(TArgsError.RequiredMissing(CanonName));
    end;
  end;
end;

function ExecEmailRegexLocked(const Email: string): Boolean;
begin
  _EmailRegexLock.Acquire;
  try
    if _CachedEmailRegex = nil then
    begin
      _CachedEmailRegex := TRegExpr.Create;
      _CachedEmailRegex.Expression := EMAIL_PATTERN;
    end;
    Result := _CachedEmailRegex.Exec(Email);
  finally
    _EmailRegexLock.Release;
  end;
end;

function ExecUrlRegexLocked(const Url: string): Boolean;
begin
  _UrlRegexLock.Acquire;
  try
    if _CachedUrlRegex = nil then
    begin
      _CachedUrlRegex := TRegExpr.Create;
      _CachedUrlRegex.Expression := URL_PATTERN;
    end;
    Result := _CachedUrlRegex.Exec(Url);
  finally
    _UrlRegexLock.Release;
  end;
end;

function ExecIPv4RegexLocked(const IP: string): Boolean;
begin
  _IPv4RegexLock.Acquire;
  try
    if _CachedIPv4Regex = nil then
    begin
      _CachedIPv4Regex := TRegExpr.Create;
      _CachedIPv4Regex.Expression := IPV4_PATTERN;
    end;
    Result := _CachedIPv4Regex.Exec(IP);
  finally
    _IPv4RegexLock.Release;
  end;
end;

// 预定义验证器实现
function IsValidEmail(const Email: string): Boolean;
begin
  // ✅ S1 修复: 长度限制防止 ReDoS 攻击
  if (Length(Email) = 0) or (Length(Email) > MAX_EMAIL_LENGTH) then
    Exit(False);

  // ✅ P2 修复: 使用缓存正则（加锁保护 TRegExpr.Exec）
  Result := ExecEmailRegexLocked(Email);
end;

function IsValidUrl(const Url: string): Boolean;
begin
  // ✅ S1 修复: 长度限制防止 ReDoS 攻击
  if (Length(Url) = 0) or (Length(Url) > MAX_URL_LENGTH) then
    Exit(False);

  // ✅ P2 修复: 使用缓存正则（加锁保护 TRegExpr.Exec）
  Result := ExecUrlRegexLocked(Url);
end;

function IsValidIPAddress(const IP: string): Boolean;
begin
  // ✅ S1 修复: 长度限制防止 ReDoS 攻击
  if (Length(IP) = 0) or (Length(IP) > MAX_IP_LENGTH) then
    Exit(False);

  // ✅ P2 修复: 使用缓存正则（加锁保护 TRegExpr.Exec）
  Result := ExecIPv4RegexLocked(IP);
end;

function IsValidPort(const Port: string): Boolean;
var
  PortNum: Integer;
begin
  Result := TryStrToInt(Port, PortNum) and (PortNum >= 1) and (PortNum <= 65535);
end;

initialization
  _EmailRegexLock := MakeMutex;
  _UrlRegexLock := MakeMutex;
  _IPv4RegexLock := MakeMutex;

// ✅ S1/P2 修复: 清理缓存的正则表达式对象
finalization
  FreeAndNil(_CachedEmailRegex);
  FreeAndNil(_CachedUrlRegex);
  FreeAndNil(_CachedIPv4Regex);

  _EmailRegexLock := nil;
  _UrlRegexLock := nil;
  _IPv4RegexLock := nil;

end.
