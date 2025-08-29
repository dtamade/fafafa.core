unit fafafa.core.args.completion;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.aliases;

type
  // 补全类型
  TCompletionType = (
    ctNone,           // 无补全
    ctFile,           // 文件路径
    ctDirectory,      // 目录路径
    ctCommand,        // 子命令
    ctOption,         // 选项名
    ctValue,          // 选项值
    ctEnum,           // 枚举值
    ctCustom          // 自定义补全
  );

  // 补全项
  TCompletionItem = record
    Value: string;           // 补全值
    Description: string;     // 描述信息
    CompletionType: TCompletionType;
    
    class function Create(const AValue, ADescription: string; AType: TCompletionType = ctValue): TCompletionItem; static;
  end;

  // 补全提供者函数类型
  TCompletionProvider = function(const Context: string): TArray<TCompletionItem>;

  // 选项补全配置
  TOptionCompletion = record
    OptionName: string;
    CompletionType: TCompletionType;
    EnumValues: TStringArray;
    CustomProvider: TCompletionProvider;
    FilePattern: string;     // 文件过滤模式，如 '*.pas;*.pp'
    
    class function File(const AOptionName: string; const APattern: string = ''): TOptionCompletion; static;
    class function Directory(const AOptionName: string): TOptionCompletion; static;
    class function Enum(const AOptionName: string; const AValues: array of string): TOptionCompletion; static;
    class function Custom(const AOptionName: string; AProvider: TCompletionProvider): TOptionCompletion; static;
  end;

  // Shell 类型
  TShellType = (stBash, stZsh, stPowerShell, stFish);

  // 补全生成器接口
  ICompletionGenerator = interface
    ['{12345678-1234-5678-9ABC-123456789012}']
    function GenerateScript(const ProgramName: string): string;
    function GetShellType: TShellType;
  end;

  // 补全配置
  TCompletionConfig = class
  private
    FProgramName: string;
    FProgramDescription: string;
    FRootCommand: IRootCommand;
    FOptionCompletions: array of TOptionCompletion;
    FGlobalOptions: TStringArray;
    
  public
    constructor Create(const AProgramName, ADescription: string; ARootCommand: IRootCommand = nil);
    
    // 配置选项补全
    function AddOptionCompletion(const Config: TOptionCompletion): TCompletionConfig;
    function AddFileCompletion(const OptionName: string; const Pattern: string = ''): TCompletionConfig;
    function AddDirectoryCompletion(const OptionName: string): TCompletionConfig;
    function AddEnumCompletion(const OptionName: string; const Values: array of string): TCompletionConfig;
    function AddCustomCompletion(const OptionName: string; Provider: TCompletionProvider): TCompletionConfig;
    
    // 配置全局选项
    function AddGlobalOption(const OptionName: string): TCompletionConfig;
    function AddGlobalOptions(const OptionNames: array of string): TCompletionConfig;
    
    // 生成补全脚本
    function GenerateBash: string;
    function GenerateZsh: string;
    function GeneratePowerShell: string;
    function GenerateFish: string;
    function Generate(ShellType: TShellType): string;
    
    // 保存到文件
    procedure SaveBashCompletion(const FileName: string);
    procedure SaveZshCompletion(const FileName: string);
    procedure SavePowerShellCompletion(const FileName: string);
    procedure SaveFishCompletion(const FileName: string);
    procedure SaveAll(const OutputDir: string);
    
    // 属性
    property ProgramName: string read FProgramName write FProgramName;
    property ProgramDescription: string read FProgramDescription write FProgramDescription;
    property RootCommand: IRootCommand read FRootCommand write FRootCommand;
  end;

  // Bash 补全生成器
  TBashCompletionGenerator = class(TInterfacedObject, ICompletionGenerator)
  private
    FConfig: TCompletionConfig;
  public
    constructor Create(AConfig: TCompletionConfig);
    function GenerateScript(const ProgramName: string): string;
    function GetShellType: TShellType;
  end;

  // Zsh 补全生成器
  TZshCompletionGenerator = class(TInterfacedObject, ICompletionGenerator)
  private
    FConfig: TCompletionConfig;
  public
    constructor Create(AConfig: TCompletionConfig);
    function GenerateScript(const ProgramName: string): string;
    function GetShellType: TShellType;
  end;

  // PowerShell 补全生成器
  TPowerShellCompletionGenerator = class(TInterfacedObject, ICompletionGenerator)
  private
    FConfig: TCompletionConfig;
  public
    constructor Create(AConfig: TCompletionConfig);
    function GenerateScript(const ProgramName: string): string;
    function GetShellType: TShellType;
  end;

// 便利函数
function CreateCompletionConfig(const ProgramName, Description: string; RootCommand: IRootCommand = nil): TCompletionConfig;

// 预定义补全提供者
function FileCompletionProvider(const Context: string): TArray<TCompletionItem>;
function DirectoryCompletionProvider(const Context: string): TArray<TCompletionItem>;

implementation

{ TCompletionItem }

class function TCompletionItem.Create(const AValue, ADescription: string; AType: TCompletionType): TCompletionItem;
begin
  Result.Value := AValue;
  Result.Description := ADescription;
  Result.CompletionType := AType;
end;

{ TOptionCompletion }

class function TOptionCompletion.File(const AOptionName: string; const APattern: string): TOptionCompletion;
begin
  Result.OptionName := AOptionName;
  Result.CompletionType := ctFile;
  Result.FilePattern := APattern;
  Result.CustomProvider := nil;
  SetLength(Result.EnumValues, 0);
end;

class function TOptionCompletion.Directory(const AOptionName: string): TOptionCompletion;
begin
  Result.OptionName := AOptionName;
  Result.CompletionType := ctDirectory;
  Result.FilePattern := '';
  Result.CustomProvider := nil;
  SetLength(Result.EnumValues, 0);
end;

class function TOptionCompletion.Enum(const AOptionName: string; const AValues: array of string): TOptionCompletion;
var
  i: Integer;
begin
  Result.OptionName := AOptionName;
  Result.CompletionType := ctEnum;
  Result.FilePattern := '';
  Result.CustomProvider := nil;
  SetLength(Result.EnumValues, Length(AValues));
  for i := Low(AValues) to High(AValues) do
    Result.EnumValues[i] := AValues[i];
end;

class function TOptionCompletion.Custom(const AOptionName: string; AProvider: TCompletionProvider): TOptionCompletion;
begin
  Result.OptionName := AOptionName;
  Result.CompletionType := ctCustom;
  Result.FilePattern := '';
  Result.CustomProvider := AProvider;
  SetLength(Result.EnumValues, 0);
end;

{ TCompletionConfig }

constructor TCompletionConfig.Create(const AProgramName, ADescription: string; ARootCommand: IRootCommand);
begin
  inherited Create;
  FProgramName := AProgramName;
  FProgramDescription := ADescription;
  FRootCommand := ARootCommand;
  SetLength(FOptionCompletions, 0);
  SetLength(FGlobalOptions, 0);
end;

function TCompletionConfig.AddOptionCompletion(const Config: TOptionCompletion): TCompletionConfig;
var
  Len: Integer;
begin
  Len := Length(FOptionCompletions);
  SetLength(FOptionCompletions, Len + 1);
  FOptionCompletions[Len] := Config;
  Result := Self;
end;

function TCompletionConfig.AddFileCompletion(const OptionName: string; const Pattern: string): TCompletionConfig;
begin
  Result := AddOptionCompletion(TOptionCompletion.File(OptionName, Pattern));
end;

function TCompletionConfig.AddDirectoryCompletion(const OptionName: string): TCompletionConfig;
begin
  Result := AddOptionCompletion(TOptionCompletion.Directory(OptionName));
end;

function TCompletionConfig.AddEnumCompletion(const OptionName: string; const Values: array of string): TCompletionConfig;
begin
  Result := AddOptionCompletion(TOptionCompletion.Enum(OptionName, Values));
end;

function TCompletionConfig.AddCustomCompletion(const OptionName: string; Provider: TCompletionProvider): TCompletionConfig;
begin
  Result := AddOptionCompletion(TOptionCompletion.Custom(OptionName, Provider));
end;

function TCompletionConfig.AddGlobalOption(const OptionName: string): TCompletionConfig;
var
  Len: Integer;
begin
  Len := Length(FGlobalOptions);
  SetLength(FGlobalOptions, Len + 1);
  FGlobalOptions[Len] := OptionName;
  Result := Self;
end;

function TCompletionConfig.AddGlobalOptions(const OptionNames: array of string): TCompletionConfig;
var
  i: Integer;
begin
  for i := Low(OptionNames) to High(OptionNames) do
    AddGlobalOption(OptionNames[i]);
  Result := Self;
end;

function TCompletionConfig.GenerateBash: string;
var
  Generator: TBashCompletionGenerator;
begin
  Generator := TBashCompletionGenerator.Create(Self);
  try
    Result := Generator.GenerateScript(FProgramName);
  finally
    Generator.Free;
  end;
end;

function TCompletionConfig.GenerateZsh: string;
var
  Generator: TZshCompletionGenerator;
begin
  Generator := TZshCompletionGenerator.Create(Self);
  try
    Result := Generator.GenerateScript(FProgramName);
  finally
    Generator.Free;
  end;
end;

function TCompletionConfig.GeneratePowerShell: string;
var
  Generator: TPowerShellCompletionGenerator;
begin
  Generator := TPowerShellCompletionGenerator.Create(Self);
  try
    Result := Generator.GenerateScript(FProgramName);
  finally
    Generator.Free;
  end;
end;

function TCompletionConfig.GenerateFish: string;
begin
  // Fish 补全暂未实现
  Result := '# Fish completion not implemented yet';
end;

function TCompletionConfig.Generate(ShellType: TShellType): string;
begin
  case ShellType of
    stBash: Result := GenerateBash;
    stZsh: Result := GenerateZsh;
    stPowerShell: Result := GeneratePowerShell;
    stFish: Result := GenerateFish;
  else
    Result := '';
  end;
end;

procedure TCompletionConfig.SaveBashCompletion(const FileName: string);
var
  Content: string;
  FileStream: TFileStream;
begin
  Content := GenerateBash;
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(Content[1], Length(Content));
  finally
    FileStream.Free;
  end;
end;

procedure TCompletionConfig.SaveZshCompletion(const FileName: string);
var
  Content: string;
  FileStream: TFileStream;
begin
  Content := GenerateZsh;
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(Content[1], Length(Content));
  finally
    FileStream.Free;
  end;
end;

procedure TCompletionConfig.SavePowerShellCompletion(const FileName: string);
var
  Content: string;
  FileStream: TFileStream;
begin
  Content := GeneratePowerShell;
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(Content[1], Length(Content));
  finally
    FileStream.Free;
  end;
end;

procedure TCompletionConfig.SaveFishCompletion(const FileName: string);
var
  Content: string;
  FileStream: TFileStream;
begin
  Content := GenerateFish;
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(Content[1], Length(Content));
  finally
    FileStream.Free;
  end;
end;

procedure TCompletionConfig.SaveAll(const OutputDir: string);
begin
  ForceDirectories(OutputDir);
  SaveBashCompletion(IncludeTrailingPathDelimiter(OutputDir) + FProgramName + '.bash');
  SaveZshCompletion(IncludeTrailingPathDelimiter(OutputDir) + '_' + FProgramName);
  SavePowerShellCompletion(IncludeTrailingPathDelimiter(OutputDir) + FProgramName + '.ps1');
  SaveFishCompletion(IncludeTrailingPathDelimiter(OutputDir) + FProgramName + '.fish');
end;

{ TBashCompletionGenerator }

constructor TBashCompletionGenerator.Create(AConfig: TCompletionConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TBashCompletionGenerator.GenerateScript(const ProgramName: string): string;
var
  Script: TStringList;
  i: Integer;
  OptionComp: TOptionCompletion;
begin
  Script := TStringList.Create;
  try
    Script.Add('#!/bin/bash');
    Script.Add('# Bash completion script for ' + ProgramName);
    Script.Add('# Generated by fafafa.core.args.completion');
    Script.Add('');
    Script.Add('_' + ProgramName + '_completion() {');
    Script.Add('    local cur prev opts');
    Script.Add('    COMPREPLY=()');
    Script.Add('    cur="${COMP_WORDS[COMP_CWORD]}"');
    Script.Add('    prev="${COMP_WORDS[COMP_CWORD-1]}"');
    Script.Add('');
    
    // 生成选项列表
    Script.Add('    opts="');
    for i := Low(FConfig.FGlobalOptions) to High(FConfig.FGlobalOptions) do
      Script.Add('        --' + FConfig.FGlobalOptions[i]);
    Script.Add('        --help');
    Script.Add('        --version"');
    Script.Add('');
    
    // 生成选项值补全
    Script.Add('    case "${prev}" in');
    for i := Low(FConfig.FOptionCompletions) to High(FConfig.FOptionCompletions) do
    begin
      OptionComp := FConfig.FOptionCompletions[i];
      Script.Add('        --' + OptionComp.OptionName + ')');
      case OptionComp.CompletionType of
        ctFile:
          if OptionComp.FilePattern <> '' then
            Script.Add('            COMPREPLY=($(compgen -f -X "!(' + OptionComp.FilePattern + ')" -- "${cur}"))')
          else
            Script.Add('            COMPREPLY=($(compgen -f -- "${cur}"))');
        ctDirectory:
          Script.Add('            COMPREPLY=($(compgen -d -- "${cur}"))');
        ctEnum:
          Script.Add('            COMPREPLY=($(compgen -W "' + string.Join(' ', OptionComp.EnumValues) + '" -- "${cur}"))');
      end;
      Script.Add('            return 0');
      Script.Add('            ;;');
    end;
    Script.Add('        *)');
    Script.Add('            ;;');
    Script.Add('    esac');
    Script.Add('');
    
    // 默认选项补全
    Script.Add('    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))');
    Script.Add('    return 0');
    Script.Add('}');
    Script.Add('');
    Script.Add('complete -F _' + ProgramName + '_completion ' + ProgramName);
    
    Result := Script.Text;
  finally
    Script.Free;
  end;
end;

function TBashCompletionGenerator.GetShellType: TShellType;
begin
  Result := stBash;
end;

{ TZshCompletionGenerator }

constructor TZshCompletionGenerator.Create(AConfig: TCompletionConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TZshCompletionGenerator.GenerateScript(const ProgramName: string): string;
var
  Script: TStringList;
  i: Integer;
  OptionComp: TOptionCompletion;
begin
  Script := TStringList.Create;
  try
    Script.Add('#compdef ' + ProgramName);
    Script.Add('# Zsh completion script for ' + ProgramName);
    Script.Add('# Generated by fafafa.core.args.completion');
    Script.Add('');
    Script.Add('_' + ProgramName + '() {');
    Script.Add('    local context state line');
    Script.Add('    typeset -A opt_args');
    Script.Add('');
    Script.Add('    _arguments \');
    
    // 生成选项定义
    for i := Low(FConfig.FGlobalOptions) to High(FConfig.FGlobalOptions) do
      Script.Add('        "--' + FConfig.FGlobalOptions[i] + '[' + FConfig.FGlobalOptions[i] + ']" \');
    
    // 生成带值选项的补全
    for i := Low(FConfig.FOptionCompletions) to High(FConfig.FOptionCompletions) do
    begin
      OptionComp := FConfig.FOptionCompletions[i];
      case OptionComp.CompletionType of
        ctFile:
          Script.Add('        "--' + OptionComp.OptionName + '[' + OptionComp.OptionName + ']:file:_files" \');
        ctDirectory:
          Script.Add('        "--' + OptionComp.OptionName + '[' + OptionComp.OptionName + ']:directory:_directories" \');
        ctEnum:
          Script.Add('        "--' + OptionComp.OptionName + '[' + OptionComp.OptionName + ']:value:(' + string.Join(' ', OptionComp.EnumValues) + ')" \');
      end;
    end;
    
    Script.Add('        "--help[Show help]" \');
    Script.Add('        "--version[Show version]"');
    Script.Add('}');
    Script.Add('');
    Script.Add('_' + ProgramName + ' "$@"');
    
    Result := Script.Text;
  finally
    Script.Free;
  end;
end;

function TZshCompletionGenerator.GetShellType: TShellType;
begin
  Result := stZsh;
end;

{ TPowerShellCompletionGenerator }

constructor TPowerShellCompletionGenerator.Create(AConfig: TCompletionConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TPowerShellCompletionGenerator.GenerateScript(const ProgramName: string): string;
var
  Script: TStringList;
  i: Integer;
  OptionComp: TOptionCompletion;
begin
  Script := TStringList.Create;
  try
    Script.Add('# PowerShell completion script for ' + ProgramName);
    Script.Add('# Generated by fafafa.core.args.completion');
    Script.Add('');
    Script.Add('Register-ArgumentCompleter -Native -CommandName ' + ProgramName + ' -ScriptBlock {');
    Script.Add('    param($commandName, $wordToComplete, $cursorPosition)');
    Script.Add('');
    Script.Add('    $completions = @()');
    Script.Add('');
    
    // 生成选项补全
    Script.Add('    # Global options');
    for i := Low(FConfig.FGlobalOptions) to High(FConfig.FGlobalOptions) do
      Script.Add('    $completions += "--' + FConfig.FGlobalOptions[i] + '"');
    Script.Add('    $completions += "--help"');
    Script.Add('    $completions += "--version"');
    Script.Add('');
    
    // 生成值补全逻辑
    Script.Add('    # Option value completions');
    Script.Add('    $previousWord = $words[$words.Count - 2]');
    Script.Add('    switch ($previousWord) {');
    
    for i := Low(FConfig.FOptionCompletions) to High(FConfig.FOptionCompletions) do
    begin
      OptionComp := FConfig.FOptionCompletions[i];
      Script.Add('        "--' + OptionComp.OptionName + '" {');
      case OptionComp.CompletionType of
        ctFile:
          Script.Add('            $completions = Get-ChildItem -Path . -File | ForEach-Object { $_.Name }');
        ctDirectory:
          Script.Add('            $completions = Get-ChildItem -Path . -Directory | ForEach-Object { $_.Name }');
        ctEnum:
          Script.Add('            $completions = @("' + string.Join('", "', OptionComp.EnumValues) + '")');
      end;
      Script.Add('            break');
      Script.Add('        }');
    end;
    
    Script.Add('    }');
    Script.Add('');
    Script.Add('    $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {');
    Script.Add('        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)');
    Script.Add('    }');
    Script.Add('}');
    
    Result := Script.Text;
  finally
    Script.Free;
  end;
end;

function TPowerShellCompletionGenerator.GetShellType: TShellType;
begin
  Result := stPowerShell;
end;

// 便利函数实现
function CreateCompletionConfig(const ProgramName, Description: string; RootCommand: IRootCommand): TCompletionConfig;
begin
  Result := TCompletionConfig.Create(ProgramName, Description, RootCommand);
end;

// 预定义补全提供者实现
function FileCompletionProvider(const Context: string): TArray<TCompletionItem>;
begin
  // 简化实现，实际应该根据上下文提供文件补全
  SetLength(Result, 0);
end;

function DirectoryCompletionProvider(const Context: string): TArray<TCompletionItem>;
begin
  // 简化实现，实际应该根据上下文提供目录补全
  SetLength(Result, 0);
end;

end.
