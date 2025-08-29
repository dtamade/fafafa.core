unit fafafa.core.args.validation;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, RegExpr,
  fafafa.core.args,
  fafafa.core.args.errors,
  fafafa.core.result,
  fafafa.core.aliases;

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
    class function Pattern(const AKey, APattern: string): TValidationRule; static;
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
  EArgsValidationException = class(Exception)
  private
    FErrors: array of TArgsError;
  public
    constructor Create(const AErrors: array of TArgsError);
    property Errors: array of TArgsError read FErrors;
  end;

// 便利函数
function ValidateArgs(const Args: IArgs): TArgsValidator;

// 预定义验证器
function IsValidEmail(const Email: string): Boolean;
function IsValidUrl(const Url: string): Boolean;
function IsValidIPAddress(const IP: string): Boolean;
function IsValidPort(const Port: string): Boolean;

implementation

const
  EMAIL_PATTERN = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  URL_PATTERN = '^https?://[a-zA-Z0-9.-]+(?:\.[a-zA-Z]{2,})?(?:/.*)?$';
  IPV4_PATTERN = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';

{ TValidationRule }

class function TValidationRule.Required(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtRequired;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Required parameter "%s" is missing', [AKey]);
end;

class function TValidationRule.Optional(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtOptional;
  Result.Key := AKey;
end;

class function TValidationRule.Range(const AKey: string; AMin, AMax: Int64): TValidationRule;
begin
  Result.ValidatorType := vtRange;
  Result.Key := AKey;
  Result.MinValue := AMin;
  Result.MaxValue := AMax;
  Result.ErrorMessage := Format('Parameter "%s" must be between %d and %d', [AKey, AMin, AMax]);
end;

class function TValidationRule.MinLength(const AKey: string; AMinLen: Integer): TValidationRule;
begin
  Result.ValidatorType := vtMinLength;
  Result.Key := AKey;
  Result.MinValue := AMinLen;
  Result.ErrorMessage := Format('Parameter "%s" must be at least %d characters long', [AKey, AMinLen]);
end;

class function TValidationRule.MaxLength(const AKey: string; AMaxLen: Integer): TValidationRule;
begin
  Result.ValidatorType := vtMaxLength;
  Result.Key := AKey;
  Result.MaxValue := AMaxLen;
  Result.ErrorMessage := Format('Parameter "%s" must be at most %d characters long', [AKey, AMaxLen]);
end;

class function TValidationRule.Pattern(const AKey, APattern: string): TValidationRule;
begin
  Result.ValidatorType := vtPattern;
  Result.Key := AKey;
  Result.Pattern := APattern;
  Result.ErrorMessage := Format('Parameter "%s" does not match required pattern', [AKey]);
end;

class function TValidationRule.Enum(const AKey: string; const AValidValues: array of string): TValidationRule;
var
  i: Integer;
begin
  Result.ValidatorType := vtEnum;
  Result.Key := AKey;
  SetLength(Result.ValidValues, Length(AValidValues));
  for i := Low(AValidValues) to High(AValidValues) do
    Result.ValidValues[i] := AValidValues[i];
  Result.ErrorMessage := Format('Parameter "%s" must be one of: %s', [AKey, string.Join(', ', Result.ValidValues)]);
end;

class function TValidationRule.Email(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtEmail;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid email address', [AKey]);
end;

class function TValidationRule.Url(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtUrl;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid URL', [AKey]);
end;

class function TValidationRule.IPAddress(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtIPAddress;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid IP address', [AKey]);
end;

class function TValidationRule.Port(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtPort;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Parameter "%s" must be a valid port number (1-65535)', [AKey]);
end;

class function TValidationRule.FileExists(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtFile;
  Result.Key := AKey;
  Result.ErrorMessage := Format('File specified in parameter "%s" does not exist', [AKey]);
end;

class function TValidationRule.DirectoryExists(const AKey: string): TValidationRule;
begin
  Result.ValidatorType := vtDirectory;
  Result.Key := AKey;
  Result.ErrorMessage := Format('Directory specified in parameter "%s" does not exist', [AKey]);
end;

class function TValidationRule.Custom(const AKey: string; AValidator: TCustomValidator; const AErrorMsg: string): TValidationRule;
begin
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
  Result := AddRule(TValidationRule.Pattern(Key, APattern));
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
    vtOptional: Result := TArgsError.ParseError(''); // 可选参数总是通过
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
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.RequiredMissing(Key);
end;

function TArgsValidator.ValidateRange(const Key: string; Min, Max: Int64): TArgsError;
var
  Value: string;
  IntValue: Int64;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if not TryStrToInt64(Value, IntValue) then
    Exit(TArgsError.InvalidValue(Key, 'integer', Value));
  
  if (IntValue < Min) or (IntValue > Max) then
    Result := TArgsError.ValidationError(Key, Format('Value %d is out of range [%d, %d]', [IntValue, Min, Max]))
  else
    Result := TArgsError.ParseError(''); // 成功
end;

function TArgsValidator.ValidateLength(const Key: string; MinLen, MaxLen: Integer): TArgsError;
var
  Value: string;
  Len: Integer;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  Len := Length(Value);
  if (Len < MinLen) or (Len > MaxLen) then
    Result := TArgsError.ValidationError(Key, Format('Length %d is out of range [%d, %d]', [Len, MinLen, MaxLen]))
  else
    Result := TArgsError.ParseError(''); // 成功
end;

function TArgsValidator.ValidatePattern(const Key, Pattern: string): TArgsError;
var
  Value: string;
  RegEx: TRegExpr;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := Pattern;
    if RegEx.Exec(Value) then
      Result := TArgsError.ParseError('') // 成功
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
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  for i := Low(ValidValues) to High(ValidValues) do
    if SameText(Value, ValidValues[i]) then
      Exit(TArgsError.ParseError('')); // 成功
  
  Result := TArgsError.ValidationError(Key, Format('Invalid value "%s". Valid values: %s', [Value, string.Join(', ', ValidValues)]));
end;

function TArgsValidator.ValidateEmail(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if IsValidEmail(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid email address', [Value]));
end;

function TArgsValidator.ValidateUrl(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if IsValidUrl(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid URL', [Value]));
end;

function TArgsValidator.ValidateIPAddress(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if IsValidIPAddress(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid IP address', [Value]));
end;

function TArgsValidator.ValidatePort(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if IsValidPort(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('"%s" is not a valid port number', [Value]));
end;

function TArgsValidator.ValidateFileExists(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if FileExists(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('File "%s" does not exist', [Value]));
end;

function TArgsValidator.ValidateDirectoryExists(const Key: string): TArgsError;
var
  Value: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if DirectoryExists(Value) then
    Result := TArgsError.ParseError('') // 成功
  else
    Result := TArgsError.ValidationError(Key, Format('Directory "%s" does not exist', [Value]));
end;

function TArgsValidator.ValidateCustom(const Key: string; Validator: TCustomValidator; const ErrorMsg: string): TArgsError;
var
  Value: string;
  CustomErrorMsg: string;
begin
  if not FArgs.TryGetValue(Key, Value) then
    Exit(TArgsError.ParseError('')); // 可选参数，跳过验证
  
  if Validator(Value, CustomErrorMsg) then
    Result := TArgsError.ParseError('') // 成功
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
    if Error.Message <> '' then // 有错误
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

// 便利函数实现
function ValidateArgs(const Args: IArgs): TArgsValidator;
begin
  Result := TArgsValidator.Create(Args);
end;

// 预定义验证器实现
function IsValidEmail(const Email: string): Boolean;
var
  RegEx: TRegExpr;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := EMAIL_PATTERN;
    Result := RegEx.Exec(Email);
  finally
    RegEx.Free;
  end;
end;

function IsValidUrl(const Url: string): Boolean;
var
  RegEx: TRegExpr;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := URL_PATTERN;
    Result := RegEx.Exec(Url);
  finally
    RegEx.Free;
  end;
end;

function IsValidIPAddress(const IP: string): Boolean;
var
  RegEx: TRegExpr;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := IPV4_PATTERN;
    Result := RegEx.Exec(IP);
  finally
    RegEx.Free;
  end;
end;

function IsValidPort(const Port: string): Boolean;
var
  PortNum: Integer;
begin
  Result := TryStrToInt(Port, PortNum) and (PortNum >= 1) and (PortNum <= 65535);
end;

end.
