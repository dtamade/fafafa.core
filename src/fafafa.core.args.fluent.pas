unit fafafa.core.args.fluent;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.validation,
  fafafa.core.args.completion,
  fafafa.core.args.help.enhanced,
  fafafa.core.result,
  fafafa.core.option,
  fafafa.core.aliases;

type
  // 前向声明
  IFluentArgs = interface;
  IFluentCommand = interface;
  IFluentOption = interface;
  IFluentValidation = interface;

  // 流式参数解析器接口
  IFluentArgs = interface
    ['{12345678-1234-5678-9ABC-123456789012}']
    
    // 基础配置
    function WithOptions(const Options: TArgsOptions): IFluentArgs;
    function CaseInsensitive: IFluentArgs;
    function CaseSensitive: IFluentArgs;
    function AllowShortCombo: IFluentArgs;
    function DisallowShortCombo: IFluentArgs;
    function StopAtDoubleDash: IFluentArgs;
    function ContinueAfterDoubleDash: IFluentArgs;
    
    // 选项定义
    function Option(const Name: string): IFluentOption;
    function Flag(const Name: string): IFluentOption;
    function RequiredOption(const Name: string): IFluentOption;
    function OptionalOption(const Name: string): IFluentOption;
    
    // 命令定义
    function Command(const Name: string): IFluentCommand;
    function SubCommand(const Name: string): IFluentCommand;
    
    // 验证
    function Validate: IFluentValidation;
    
    // 帮助系统
    function WithHelp(const Description: string): IFluentArgs;
    function WithVersion(const Version: string): IFluentArgs;
    function WithUsage(const Usage: string): IFluentArgs;
    function WithExamples(const Examples: array of string): IFluentArgs;
    
    // 补全系统
    function WithCompletion: IFluentArgs;
    function GenerateCompletion(ShellType: TShellType): string;
    
    // 解析和执行
    function Parse(const Args: array of string): IFluentArgs;
    function ParseProcess: IFluentArgs;
    function Execute: Integer;
    
    // 获取结果
    function GetArgs: IArgs;
    function GetValue(const Key: string): string;
    function GetValueOr(const Key, DefaultValue: string): string;
    function GetInt(const Key: string): Int64;
    function GetIntOr(const Key: string; DefaultValue: Int64): Int64;
    function GetBool(const Key: string): Boolean;
    function GetBoolOr(const Key: string; DefaultValue: Boolean): Boolean;
    function HasFlag(const Key: string): Boolean;
    function GetPositionals: TStringArray;
    
    // 错误处理
    function OnError(Handler: TProc<Exception>): IFluentArgs;
    function OnValidationError(Handler: TProc<TValidationResult>): IFluentArgs;
  end;

  // 流式选项配置接口
  IFluentOption = interface
    ['{23456789-2345-6789-BCDE-23456789ABCD}']
    
    // 基础配置
    function WithAlias(const Alias: string): IFluentOption;
    function WithAliases(const Aliases: array of string): IFluentOption;
    function WithDescription(const Description: string): IFluentOption;
    function WithDefaultValue(const Value: string): IFluentOption;
    function Required: IFluentOption;
    function Optional: IFluentOption;
    
    // 类型配置
    function AsString: IFluentOption;
    function AsInteger: IFluentOption;
    function AsFloat: IFluentOption;
    function AsBoolean: IFluentOption;
    function AsFile: IFluentOption;
    function AsDirectory: IFluentOption;
    
    // 验证配置
    function WithRange(Min, Max: Int64): IFluentOption;
    function WithMinLength(MinLen: Integer): IFluentOption;
    function WithMaxLength(MaxLen: Integer): IFluentOption;
    function WithPattern(const Pattern: string): IFluentOption;
    function WithEnum(const Values: array of string): IFluentOption;
    function WithCustomValidator(Validator: TCustomValidator): IFluentOption;
    
    // 补全配置
    function WithFileCompletion(const Pattern: string = ''): IFluentOption;
    function WithDirectoryCompletion: IFluentOption;
    function WithEnumCompletion(const Values: array of string): IFluentOption;
    function WithCustomCompletion(Provider: TCompletionProvider): IFluentOption;
    
    // 帮助配置
    function WithExample(const Example: string): IFluentOption;
    function WithEnvironmentVar(const EnvVar: string): IFluentOption;
    
    // 返回父级
    function EndOption: IFluentArgs;
  end;

  // 流式命令配置接口
  IFluentCommand = interface
    ['{34567890-3456-7890-CDEF-3456789ABCDE}']
    
    // 基础配置
    function WithAlias(const Alias: string): IFluentCommand;
    function WithAliases(const Aliases: array of string): IFluentCommand;
    function WithDescription(const Description: string): IFluentCommand;
    function WithLongDescription(const Description: string): IFluentCommand;
    function WithUsage(const Usage: string): IFluentCommand;
    
    // 处理器配置
    function WithHandler(Handler: TCommandHandler): IFluentCommand;
    function WithHandlerFunc(Handler: TCommandHandlerFunc): IFluentCommand;
    
    // 选项配置
    function Option(const Name: string): IFluentOption;
    function Flag(const Name: string): IFluentOption;
    function RequiredOption(const Name: string): IFluentOption;
    
    // 子命令配置
    function SubCommand(const Name: string): IFluentCommand;
    
    // 帮助配置
    function WithExample(const Command, Description: string): IFluentCommand;
    function WithExamples(const Examples: array of THelpExample): IFluentCommand;
    
    // 返回父级
    function EndCommand: IFluentArgs;
  end;

  // 流式验证配置接口
  IFluentValidation = interface
    ['{45678901-4567-8901-DEF0-456789ABCDEF}']
    
    // 基础验证
    function Required(const Key: string): IFluentValidation;
    function Optional(const Key: string): IFluentValidation;
    
    // 类型验证
    function Range(const Key: string; Min, Max: Int64): IFluentValidation;
    function MinLength(const Key: string; MinLen: Integer): IFluentValidation;
    function MaxLength(const Key: string; MaxLen: Integer): IFluentValidation;
    function Pattern(const Key, RegexPattern: string): IFluentValidation;
    function Enum(const Key: string; const Values: array of string): IFluentValidation;
    function Email(const Key: string): IFluentValidation;
    function Url(const Key: string): IFluentValidation;
    function IPAddress(const Key: string): IFluentValidation;
    function Port(const Key: string): IFluentValidation;
    function FileExists(const Key: string): IFluentValidation;
    function DirectoryExists(const Key: string): IFluentValidation;
    function Custom(const Key: string; Validator: TCustomValidator): IFluentValidation;
    
    // 关系验证
    function MutuallyExclusive(const Key1, Key2: string): IFluentValidation;
    function AtLeastOne(const Keys: array of string): IFluentValidation;
    function PositionalCount(Min, Max: Integer): IFluentValidation;
    
    // 配置选项
    function StopOnFirstError: IFluentValidation;
    function ContinueOnError: IFluentValidation;
    
    // 执行验证
    function Check: TValidationResult;
    function CheckAndThrow: IFluentValidation;
    
    // 返回父级
    function EndValidation: IFluentArgs;
  end;

  // 流式参数解析器实现
  TFluentArgs = class(TInterfacedObject, IFluentArgs)
  private
    FOptions: TArgsOptions;
    FArgs: IArgs;
    FRootCommand: IRootCommand;
    FCurrentCommand: ICommand;
    FCompletionConfig: TCompletionConfig;
    FHelpRenderer: TEnhancedHelpRenderer;
    FParsed: Boolean;
    FErrorHandler: TProc<Exception>;
    FValidationErrorHandler: TProc<TValidationResult>;
    
    // 帮助信息
    FProgramDescription: string;
    FProgramVersion: string;
    FProgramUsage: string;
    FProgramExamples: TStringArray;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // IFluentArgs 实现
    function WithOptions(const Options: TArgsOptions): IFluentArgs;
    function CaseInsensitive: IFluentArgs;
    function CaseSensitive: IFluentArgs;
    function AllowShortCombo: IFluentArgs;
    function DisallowShortCombo: IFluentArgs;
    function StopAtDoubleDash: IFluentArgs;
    function ContinueAfterDoubleDash: IFluentArgs;
    
    function Option(const Name: string): IFluentOption;
    function Flag(const Name: string): IFluentOption;
    function RequiredOption(const Name: string): IFluentOption;
    function OptionalOption(const Name: string): IFluentOption;
    
    function Command(const Name: string): IFluentCommand;
    function SubCommand(const Name: string): IFluentCommand;
    
    function Validate: IFluentValidation;
    
    function WithHelp(const Description: string): IFluentArgs;
    function WithVersion(const Version: string): IFluentArgs;
    function WithUsage(const Usage: string): IFluentArgs;
    function WithExamples(const Examples: array of string): IFluentArgs;
    
    function WithCompletion: IFluentArgs;
    function GenerateCompletion(ShellType: TShellType): string;
    
    function Parse(const Args: array of string): IFluentArgs;
    function ParseProcess: IFluentArgs;
    function Execute: Integer;
    
    function GetArgs: IArgs;
    function GetValue(const Key: string): string;
    function GetValueOr(const Key, DefaultValue: string): string;
    function GetInt(const Key: string): Int64;
    function GetIntOr(const Key: string; DefaultValue: Int64): Int64;
    function GetBool(const Key: string): Boolean;
    function GetBoolOr(const Key: string; DefaultValue: Boolean): Boolean;
    function HasFlag(const Key: string): Boolean;
    function GetPositionals: TStringArray;
    
    function OnError(Handler: TProc<Exception>): IFluentArgs;
    function OnValidationError(Handler: TProc<TValidationResult>): IFluentArgs;
  end;

  // 流式选项实现
  TFluentOption = class(TInterfacedObject, IFluentOption)
  private
    FParent: IFluentArgs;
    FOptionName: string;
    FOptionConfig: record
      Aliases: TStringArray;
      Description: string;
      DefaultValue: string;
      Required: Boolean;
      OptionType: string;
      ValidationRules: array of TValidationRule;
      CompletionConfig: TOptionCompletion;
      Example: string;
      EnvironmentVar: string;
    end;
    
  public
    constructor Create(AParent: IFluentArgs; const AOptionName: string);
    
    // IFluentOption 实现
    function WithAlias(const Alias: string): IFluentOption;
    function WithAliases(const Aliases: array of string): IFluentOption;
    function WithDescription(const Description: string): IFluentOption;
    function WithDefaultValue(const Value: string): IFluentOption;
    function Required: IFluentOption;
    function Optional: IFluentOption;
    
    function AsString: IFluentOption;
    function AsInteger: IFluentOption;
    function AsFloat: IFluentOption;
    function AsBoolean: IFluentOption;
    function AsFile: IFluentOption;
    function AsDirectory: IFluentOption;
    
    function WithRange(Min, Max: Int64): IFluentOption;
    function WithMinLength(MinLen: Integer): IFluentOption;
    function WithMaxLength(MaxLen: Integer): IFluentOption;
    function WithPattern(const Pattern: string): IFluentOption;
    function WithEnum(const Values: array of string): IFluentOption;
    function WithCustomValidator(Validator: TCustomValidator): IFluentOption;
    
    function WithFileCompletion(const Pattern: string): IFluentOption;
    function WithDirectoryCompletion: IFluentOption;
    function WithEnumCompletion(const Values: array of string): IFluentOption;
    function WithCustomCompletion(Provider: TCompletionProvider): IFluentOption;
    
    function WithExample(const Example: string): IFluentOption;
    function WithEnvironmentVar(const EnvVar: string): IFluentOption;
    
    function EndOption: IFluentArgs;
  end;

  // 流式命令实现
  TFluentCommand = class(TInterfacedObject, IFluentCommand)
  private
    FParent: IFluentArgs;
    FCommandName: string;
    FCommand: ICommand;
    
  public
    constructor Create(AParent: IFluentArgs; const ACommandName: string);
    
    // IFluentCommand 实现
    function WithAlias(const Alias: string): IFluentCommand;
    function WithAliases(const Aliases: array of string): IFluentCommand;
    function WithDescription(const Description: string): IFluentCommand;
    function WithLongDescription(const Description: string): IFluentCommand;
    function WithUsage(const Usage: string): IFluentCommand;
    
    function WithHandler(Handler: TCommandHandler): IFluentCommand;
    function WithHandlerFunc(Handler: TCommandHandlerFunc): IFluentCommand;
    
    function Option(const Name: string): IFluentOption;
    function Flag(const Name: string): IFluentOption;
    function RequiredOption(const Name: string): IFluentOption;
    
    function SubCommand(const Name: string): IFluentCommand;
    
    function WithExample(const Command, Description: string): IFluentCommand;
    function WithExamples(const Examples: array of THelpExample): IFluentCommand;
    
    function EndCommand: IFluentArgs;
  end;

  // 流式验证实现
  TFluentValidation = class(TInterfacedObject, IFluentValidation)
  private
    FParent: IFluentArgs;
    FValidator: TArgsValidator;
    
  public
    constructor Create(AParent: IFluentArgs; AValidator: TArgsValidator);
    destructor Destroy; override;
    
    // IFluentValidation 实现
    function Required(const Key: string): IFluentValidation;
    function Optional(const Key: string): IFluentValidation;
    
    function Range(const Key: string; Min, Max: Int64): IFluentValidation;
    function MinLength(const Key: string; MinLen: Integer): IFluentValidation;
    function MaxLength(const Key: string; MaxLen: Integer): IFluentValidation;
    function Pattern(const Key, RegexPattern: string): IFluentValidation;
    function Enum(const Key: string; const Values: array of string): IFluentValidation;
    function Email(const Key: string): IFluentValidation;
    function Url(const Key: string): IFluentValidation;
    function IPAddress(const Key: string): IFluentValidation;
    function Port(const Key: string): IFluentValidation;
    function FileExists(const Key: string): IFluentValidation;
    function DirectoryExists(const Key: string): IFluentValidation;
    function Custom(const Key: string; Validator: TCustomValidator): IFluentValidation;
    
    function MutuallyExclusive(const Key1, Key2: string): IFluentValidation;
    function AtLeastOne(const Keys: array of string): IFluentValidation;
    function PositionalCount(Min, Max: Integer): IFluentValidation;
    
    function StopOnFirstError: IFluentValidation;
    function ContinueOnError: IFluentValidation;
    
    function Check: TValidationResult;
    function CheckAndThrow: IFluentValidation;
    
    function EndValidation: IFluentArgs;
  end;

// 便利函数
function Args: IFluentArgs;
function ArgsWithOptions(const Options: TArgsOptions): IFluentArgs;

implementation

// 便利函数实现
function Args: IFluentArgs;
begin
  Result := TFluentArgs.Create;
end;

function ArgsWithOptions(const Options: TArgsOptions): IFluentArgs;
begin
  Result := TFluentArgs.Create.WithOptions(Options);
end;

{ TFluentArgs }

constructor TFluentArgs.Create;
begin
  inherited Create;
  FOptions := ArgsOptionsDefault;
  FRootCommand := NewRootCommand;
  FParsed := False;
  SetLength(FProgramExamples, 0);
end;

destructor TFluentArgs.Destroy;
begin
  if FCompletionConfig <> nil then
    FCompletionConfig.Free;
  if FHelpRenderer <> nil then
    FHelpRenderer.Free;
  inherited Destroy;
end;

function TFluentArgs.WithOptions(const Options: TArgsOptions): IFluentArgs;
begin
  FOptions := Options;
  Result := Self;
end;

function TFluentArgs.CaseInsensitive: IFluentArgs;
begin
  FOptions.CaseInsensitiveKeys := True;
  Result := Self;
end;

function TFluentArgs.CaseSensitive: IFluentArgs;
begin
  FOptions.CaseInsensitiveKeys := False;
  Result := Self;
end;

function TFluentArgs.AllowShortCombo: IFluentArgs;
begin
  FOptions.AllowShortFlagsCombo := True;
  Result := Self;
end;

function TFluentArgs.DisallowShortCombo: IFluentArgs;
begin
  FOptions.AllowShortFlagsCombo := False;
  Result := Self;
end;

function TFluentArgs.StopAtDoubleDash: IFluentArgs;
begin
  FOptions.StopAtDoubleDash := True;
  Result := Self;
end;

function TFluentArgs.ContinueAfterDoubleDash: IFluentArgs;
begin
  FOptions.StopAtDoubleDash := False;
  Result := Self;
end;

function TFluentArgs.Option(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(Self, Name);
end;

function TFluentArgs.Flag(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(Self, Name).AsBoolean;
end;

function TFluentArgs.RequiredOption(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(Self, Name).Required;
end;

function TFluentArgs.OptionalOption(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(Self, Name).Optional;
end;

function TFluentArgs.Command(const Name: string): IFluentCommand;
begin
  Result := TFluentCommand.Create(Self, Name);
end;

function TFluentArgs.SubCommand(const Name: string): IFluentCommand;
begin
  Result := TFluentCommand.Create(Self, Name);
end;

function TFluentArgs.Validate: IFluentValidation;
var
  Validator: TArgsValidator;
begin
  if not FParsed then
    raise Exception.Create('Must parse arguments before validation');
  
  Validator := ValidateArgs(FArgs);
  Result := TFluentValidation.Create(Self, Validator);
end;

function TFluentArgs.WithHelp(const Description: string): IFluentArgs;
begin
  FProgramDescription := Description;
  Result := Self;
end;

function TFluentArgs.WithVersion(const Version: string): IFluentArgs;
begin
  FProgramVersion := Version;
  Result := Self;
end;

function TFluentArgs.WithUsage(const Usage: string): IFluentArgs;
begin
  FProgramUsage := Usage;
  Result := Self;
end;

function TFluentArgs.WithExamples(const Examples: array of string): IFluentArgs;
var
  i: Integer;
begin
  SetLength(FProgramExamples, Length(Examples));
  for i := Low(Examples) to High(Examples) do
    FProgramExamples[i] := Examples[i];
  Result := Self;
end;

function TFluentArgs.WithCompletion: IFluentArgs;
begin
  if FCompletionConfig = nil then
    FCompletionConfig := CreateCompletionConfig('app', FProgramDescription);
  Result := Self;
end;

function TFluentArgs.GenerateCompletion(ShellType: TShellType): string;
begin
  if FCompletionConfig = nil then
    WithCompletion;
  Result := FCompletionConfig.Generate(ShellType);
end;

function TFluentArgs.Parse(const Args: array of string): IFluentArgs;
var
  ArgsArray: TStringArray;
  i: Integer;
begin
  SetLength(ArgsArray, Length(Args));
  for i := Low(Args) to High(Args) do
    ArgsArray[i] := Args[i];
  
  FArgs := TArgs.FromArray(ArgsArray, FOptions);
  FParsed := True;
  Result := Self;
end;

function TFluentArgs.ParseProcess: IFluentArgs;
begin
  FArgs := TArgs.FromProcess(FOptions);
  FParsed := True;
  Result := Self;
end;

function TFluentArgs.Execute: Integer;
begin
  if not FParsed then
    ParseProcess;
  
  try
    if FRootCommand <> nil then
      Result := FRootCommand.Run(FArgs)
    else
      Result := 0;
  except
    on E: Exception do
    begin
      if Assigned(FErrorHandler) then
        FErrorHandler(E)
      else
        raise;
      Result := 1;
    end;
  end;
end;

function TFluentArgs.GetArgs: IArgs;
begin
  if not FParsed then
    raise Exception.Create('Must parse arguments first');
  Result := FArgs;
end;

function TFluentArgs.GetValue(const Key: string): string;
begin
  if not GetArgs.TryGetValue(Key, Result) then
    raise Exception.CreateFmt('Key "%s" not found', [Key]);
end;

function TFluentArgs.GetValueOr(const Key, DefaultValue: string): string;
begin
  if not GetArgs.TryGetValue(Key, Result) then
    Result := DefaultValue;
end;

function TFluentArgs.GetInt(const Key: string): Int64;
begin
  if not GetArgs.TryGetInt64(Key, Result) then
    raise Exception.CreateFmt('Key "%s" not found or not a valid integer', [Key]);
end;

function TFluentArgs.GetIntOr(const Key: string; DefaultValue: Int64): Int64;
begin
  if not GetArgs.TryGetInt64(Key, Result) then
    Result := DefaultValue;
end;

function TFluentArgs.GetBool(const Key: string): Boolean;
begin
  Result := GetArgs.HasFlag(Key);
end;

function TFluentArgs.GetBoolOr(const Key: string; DefaultValue: Boolean): Boolean;
var
  Value: string;
begin
  if GetArgs.HasFlag(Key) then
    Result := True
  else if GetArgs.TryGetValue(Key, Value) then
  begin
    Value := LowerCase(Trim(Value));
    Result := (Value = 'true') or (Value = '1') or (Value = 'yes') or (Value = 'on');
  end
  else
    Result := DefaultValue;
end;

function TFluentArgs.HasFlag(const Key: string): Boolean;
begin
  Result := GetArgs.HasFlag(Key);
end;

function TFluentArgs.GetPositionals: TStringArray;
begin
  Result := GetArgs.Positionals;
end;

function TFluentArgs.OnError(Handler: TProc<Exception>): IFluentArgs;
begin
  FErrorHandler := Handler;
  Result := Self;
end;

function TFluentArgs.OnValidationError(Handler: TProc<TValidationResult>): IFluentArgs;
begin
  FValidationErrorHandler := Handler;
  Result := Self;
end;

{ TFluentOption }

constructor TFluentOption.Create(AParent: IFluentArgs; const AOptionName: string);
begin
  inherited Create;
  FParent := AParent;
  FOptionName := AOptionName;
  
  // 初始化配置
  SetLength(FOptionConfig.Aliases, 0);
  FOptionConfig.Description := '';
  FOptionConfig.DefaultValue := '';
  FOptionConfig.Required := False;
  FOptionConfig.OptionType := 'string';
  SetLength(FOptionConfig.ValidationRules, 0);
  FOptionConfig.Example := '';
  FOptionConfig.EnvironmentVar := '';
end;

function TFluentOption.WithAlias(const Alias: string): IFluentOption;
var
  Len: Integer;
begin
  Len := Length(FOptionConfig.Aliases);
  SetLength(FOptionConfig.Aliases, Len + 1);
  FOptionConfig.Aliases[Len] := Alias;
  Result := Self;
end;

function TFluentOption.WithAliases(const Aliases: array of string): IFluentOption;
var
  i: Integer;
begin
  for i := Low(Aliases) to High(Aliases) do
    WithAlias(Aliases[i]);
  Result := Self;
end;

function TFluentOption.WithDescription(const Description: string): IFluentOption;
begin
  FOptionConfig.Description := Description;
  Result := Self;
end;

function TFluentOption.WithDefaultValue(const Value: string): IFluentOption;
begin
  FOptionConfig.DefaultValue := Value;
  Result := Self;
end;

function TFluentOption.Required: IFluentOption;
begin
  FOptionConfig.Required := True;
  Result := Self;
end;

function TFluentOption.Optional: IFluentOption;
begin
  FOptionConfig.Required := False;
  Result := Self;
end;

function TFluentOption.AsString: IFluentOption;
begin
  FOptionConfig.OptionType := 'string';
  Result := Self;
end;

function TFluentOption.AsInteger: IFluentOption;
begin
  FOptionConfig.OptionType := 'integer';
  Result := Self;
end;

function TFluentOption.AsFloat: IFluentOption;
begin
  FOptionConfig.OptionType := 'float';
  Result := Self;
end;

function TFluentOption.AsBoolean: IFluentOption;
begin
  FOptionConfig.OptionType := 'boolean';
  Result := Self;
end;

function TFluentOption.AsFile: IFluentOption;
begin
  FOptionConfig.OptionType := 'file';
  Result := Self;
end;

function TFluentOption.AsDirectory: IFluentOption;
begin
  FOptionConfig.OptionType := 'directory';
  Result := Self;
end;

function TFluentOption.WithRange(Min, Max: Int64): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Range(FOptionName, Min, Max);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithMinLength(MinLen: Integer): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.MinLength(FOptionName, MinLen);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithMaxLength(MaxLen: Integer): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.MaxLength(FOptionName, MaxLen);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithPattern(const Pattern: string): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Pattern(FOptionName, Pattern);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithEnum(const Values: array of string): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Enum(FOptionName, Values);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithCustomValidator(Validator: TCustomValidator): IFluentOption;
var
  Len: Integer;
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Custom(FOptionName, Validator);
  Len := Length(FOptionConfig.ValidationRules);
  SetLength(FOptionConfig.ValidationRules, Len + 1);
  FOptionConfig.ValidationRules[Len] := Rule;
  Result := Self;
end;

function TFluentOption.WithFileCompletion(const Pattern: string): IFluentOption;
begin
  FOptionConfig.CompletionConfig := TOptionCompletion.File(FOptionName, Pattern);
  Result := Self;
end;

function TFluentOption.WithDirectoryCompletion: IFluentOption;
begin
  FOptionConfig.CompletionConfig := TOptionCompletion.Directory(FOptionName);
  Result := Self;
end;

function TFluentOption.WithEnumCompletion(const Values: array of string): IFluentOption;
begin
  FOptionConfig.CompletionConfig := TOptionCompletion.Enum(FOptionName, Values);
  Result := Self;
end;

function TFluentOption.WithCustomCompletion(Provider: TCompletionProvider): IFluentOption;
begin
  FOptionConfig.CompletionConfig := TOptionCompletion.Custom(FOptionName, Provider);
  Result := Self;
end;

function TFluentOption.WithExample(const Example: string): IFluentOption;
begin
  FOptionConfig.Example := Example;
  Result := Self;
end;

function TFluentOption.WithEnvironmentVar(const EnvVar: string): IFluentOption;
begin
  FOptionConfig.EnvironmentVar := EnvVar;
  Result := Self;
end;

function TFluentOption.EndOption: IFluentArgs;
begin
  // 这里应该将选项配置应用到父级 Args 对象
  // 简化实现，实际需要更复杂的集成
  Result := FParent;
end;

{ TFluentCommand }

constructor TFluentCommand.Create(AParent: IFluentArgs; const ACommandName: string);
begin
  inherited Create;
  FParent := AParent;
  FCommandName := ACommandName;
  FCommand := NewCommand(ACommandName);
end;

function TFluentCommand.WithAlias(const Alias: string): IFluentCommand;
begin
  FCommand.AddAlias(Alias);
  Result := Self;
end;

function TFluentCommand.WithAliases(const Aliases: array of string): IFluentCommand;
var
  i: Integer;
begin
  for i := Low(Aliases) to High(Aliases) do
    FCommand.AddAlias(Aliases[i]);
  Result := Self;
end;

function TFluentCommand.WithDescription(const Description: string): IFluentCommand;
begin
  FCommand.SetDescription(Description);
  Result := Self;
end;

function TFluentCommand.WithLongDescription(const Description: string): IFluentCommand;
begin
  // 扩展描述需要增强的命令接口支持
  Result := Self;
end;

function TFluentCommand.WithUsage(const Usage: string): IFluentCommand;
begin
  // 用法信息需要增强的命令接口支持
  Result := Self;
end;

function TFluentCommand.WithHandler(Handler: TCommandHandler): IFluentCommand;
begin
  FCommand.SetHandler(Handler);
  Result := Self;
end;

function TFluentCommand.WithHandlerFunc(Handler: TCommandHandlerFunc): IFluentCommand;
begin
  FCommand.SetHandlerFunc(Handler);
  Result := Self;
end;

function TFluentCommand.Option(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(FParent, Name);
end;

function TFluentCommand.Flag(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(FParent, Name).AsBoolean;
end;

function TFluentCommand.RequiredOption(const Name: string): IFluentOption;
begin
  Result := TFluentOption.Create(FParent, Name).Required;
end;

function TFluentCommand.SubCommand(const Name: string): IFluentCommand;
begin
  Result := TFluentCommand.Create(FParent, Name);
end;

function TFluentCommand.WithExample(const Command, Description: string): IFluentCommand;
begin
  // 示例需要增强的命令接口支持
  Result := Self;
end;

function TFluentCommand.WithExamples(const Examples: array of THelpExample): IFluentCommand;
begin
  // 示例需要增强的命令接口支持
  Result := Self;
end;

function TFluentCommand.EndCommand: IFluentArgs;
begin
  // 这里应该将命令注册到父级 Args 对象
  // 简化实现
  Result := FParent;
end;

{ TFluentValidation }

constructor TFluentValidation.Create(AParent: IFluentArgs; AValidator: TArgsValidator);
begin
  inherited Create;
  FParent := AParent;
  FValidator := AValidator;
end;

destructor TFluentValidation.Destroy;
begin
  // 注意：不要释放 FValidator，它由调用者管理
  inherited Destroy;
end;

function TFluentValidation.Required(const Key: string): IFluentValidation;
begin
  FValidator.Required(Key);
  Result := Self;
end;

function TFluentValidation.Optional(const Key: string): IFluentValidation;
begin
  FValidator.Optional(Key);
  Result := Self;
end;

function TFluentValidation.Range(const Key: string; Min, Max: Int64): IFluentValidation;
begin
  FValidator.Range(Key, Min, Max);
  Result := Self;
end;

function TFluentValidation.MinLength(const Key: string; MinLen: Integer): IFluentValidation;
begin
  FValidator.MinLength(Key, MinLen);
  Result := Self;
end;

function TFluentValidation.MaxLength(const Key: string; MaxLen: Integer): IFluentValidation;
begin
  FValidator.MaxLength(Key, MaxLen);
  Result := Self;
end;

function TFluentValidation.Pattern(const Key, RegexPattern: string): IFluentValidation;
begin
  FValidator.Pattern(Key, RegexPattern);
  Result := Self;
end;

function TFluentValidation.Enum(const Key: string; const Values: array of string): IFluentValidation;
begin
  FValidator.Enum(Key, Values);
  Result := Self;
end;

function TFluentValidation.Email(const Key: string): IFluentValidation;
begin
  FValidator.Email(Key);
  Result := Self;
end;

function TFluentValidation.Url(const Key: string): IFluentValidation;
begin
  FValidator.Url(Key);
  Result := Self;
end;

function TFluentValidation.IPAddress(const Key: string): IFluentValidation;
begin
  FValidator.IPAddress(Key);
  Result := Self;
end;

function TFluentValidation.Port(const Key: string): IFluentValidation;
begin
  FValidator.Port(Key);
  Result := Self;
end;

function TFluentValidation.FileExists(const Key: string): IFluentValidation;
begin
  FValidator.FileExists(Key);
  Result := Self;
end;

function TFluentValidation.DirectoryExists(const Key: string): IFluentValidation;
begin
  FValidator.DirectoryExists(Key);
  Result := Self;
end;

function TFluentValidation.Custom(const Key: string; Validator: TCustomValidator): IFluentValidation;
begin
  FValidator.Custom(Key, Validator);
  Result := Self;
end;

function TFluentValidation.MutuallyExclusive(const Key1, Key2: string): IFluentValidation;
begin
  FValidator.MutuallyExclusive(Key1, Key2);
  Result := Self;
end;

function TFluentValidation.AtLeastOne(const Keys: array of string): IFluentValidation;
begin
  FValidator.AtLeastOne(Keys);
  Result := Self;
end;

function TFluentValidation.PositionalCount(Min, Max: Integer): IFluentValidation;
begin
  FValidator.PositionalCount(Min, Max);
  Result := Self;
end;

function TFluentValidation.StopOnFirstError: IFluentValidation;
begin
  FValidator.StopOnFirstError(True);
  Result := Self;
end;

function TFluentValidation.ContinueOnError: IFluentValidation;
begin
  FValidator.StopOnFirstError(False);
  Result := Self;
end;

function TFluentValidation.Check: TValidationResult;
begin
  Result := FValidator.Validate;
end;

function TFluentValidation.CheckAndThrow: IFluentValidation;
begin
  FValidator.ValidateAndThrow;
  Result := Self;
end;

function TFluentValidation.EndValidation: IFluentArgs;
begin
  Result := FParent;
end;

end.
