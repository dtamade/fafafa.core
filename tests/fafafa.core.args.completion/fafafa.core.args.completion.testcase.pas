{$CODEPAGE UTF8}
unit fafafa.core.args.completion.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  fafafa.core.args.completion,
  fafafa.core.args.command;

type
  TTestCase_ArgsCompletion = class(TTestCase)
  published
    procedure Test_CompletionConfig_Create;
    procedure Test_AddGlobalOption;
    procedure Test_AddFileCompletion;
    procedure Test_AddDirectoryCompletion;
    procedure Test_AddEnumCompletion;
    procedure Test_AddCustomCompletion;
    procedure Test_GenerateBash_Basic;
    procedure Test_GenerateZsh_Basic;
    procedure Test_GeneratePowerShell_Basic;
    procedure Test_BashScript_ContainsOptions;
    procedure Test_ZshScript_ContainsOptions;
    procedure Test_PowerShellScript_ContainsOptions;
    procedure Test_FileCompletion_WithPattern;
    procedure Test_EnumCompletion_Values;
    procedure Test_SaveCompletionFiles;
  end;

  TTestCase_CompletionGenerators = class(TTestCase)
  published
    procedure Test_BashGenerator_Create;
    procedure Test_ZshGenerator_Create;
    procedure Test_PowerShellGenerator_Create;
    procedure Test_BashGenerator_ShellType;
    procedure Test_ZshGenerator_ShellType;
    procedure Test_PowerShellGenerator_ShellType;
  end;

implementation

// 测试用的自定义补全提供者
function TestCompletionProvider(const Context: string): TArray<TCompletionItem>;
begin
  SetLength(Result, 2);
  Result[0] := TCompletionItem.Create('option1', 'First option', ctValue);
  Result[1] := TCompletionItem.Create('option2', 'Second option', ctValue);
end;

{ TTestCase_ArgsCompletion }

procedure TTestCase_ArgsCompletion.Test_CompletionConfig_Create;
var
  Config: TCompletionConfig;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    CheckEquals('testapp', Config.ProgramName);
    CheckEquals('Test Application', Config.ProgramDescription);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_AddGlobalOption;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddGlobalOption('verbose').AddGlobalOption('debug');
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--verbose', BashScript) > 0);
    CheckTrue(Pos('--debug', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_AddFileCompletion;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddFileCompletion('config', '*.conf');
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--config', BashScript) > 0);
    CheckTrue(Pos('compgen -f', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_AddDirectoryCompletion;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddDirectoryCompletion('output-dir');
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--output-dir', BashScript) > 0);
    CheckTrue(Pos('compgen -d', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_AddEnumCompletion;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddEnumCompletion('format', ['json', 'xml', 'yaml']);
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--format', BashScript) > 0);
    CheckTrue(Pos('json xml yaml', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_AddCustomCompletion;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddCustomCompletion('custom', @TestCompletionProvider);
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--custom', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_GenerateBash_Basic;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    BashScript := Config.GenerateBash;
    
    CheckTrue(Length(BashScript) > 0);
    CheckTrue(Pos('#!/bin/bash', BashScript) > 0);
    CheckTrue(Pos('_testapp_completion', BashScript) > 0);
    CheckTrue(Pos('complete -F', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_GenerateZsh_Basic;
var
  Config: TCompletionConfig;
  ZshScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    ZshScript := Config.GenerateZsh;
    
    CheckTrue(Length(ZshScript) > 0);
    CheckTrue(Pos('#compdef testapp', ZshScript) > 0);
    CheckTrue(Pos('_testapp()', ZshScript) > 0);
    CheckTrue(Pos('_arguments', ZshScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_GeneratePowerShell_Basic;
var
  Config: TCompletionConfig;
  PowerShellScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    PowerShellScript := Config.GeneratePowerShell;
    
    CheckTrue(Length(PowerShellScript) > 0);
    CheckTrue(Pos('Register-ArgumentCompleter', PowerShellScript) > 0);
    CheckTrue(Pos('-CommandName testapp', PowerShellScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_BashScript_ContainsOptions;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddGlobalOptions(['verbose', 'debug', 'quiet']);
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--verbose', BashScript) > 0);
    CheckTrue(Pos('--debug', BashScript) > 0);
    CheckTrue(Pos('--quiet', BashScript) > 0);
    CheckTrue(Pos('--help', BashScript) > 0);
    CheckTrue(Pos('--version', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_ZshScript_ContainsOptions;
var
  Config: TCompletionConfig;
  ZshScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddGlobalOptions(['verbose', 'debug']);
    ZshScript := Config.GenerateZsh;
    
    CheckTrue(Pos('--verbose', ZshScript) > 0);
    CheckTrue(Pos('--debug', ZshScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_PowerShellScript_ContainsOptions;
var
  Config: TCompletionConfig;
  PowerShellScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddGlobalOptions(['verbose', 'debug']);
    PowerShellScript := Config.GeneratePowerShell;
    
    CheckTrue(Pos('--verbose', PowerShellScript) > 0);
    CheckTrue(Pos('--debug', PowerShellScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_FileCompletion_WithPattern;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddFileCompletion('config', '*.conf;*.ini');
    BashScript := Config.GenerateBash;
    
    CheckTrue(Pos('--config', BashScript) > 0);
    CheckTrue(Pos('*.conf;*.ini', BashScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_EnumCompletion_Values;
var
  Config: TCompletionConfig;
  BashScript, ZshScript: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddEnumCompletion('format', ['json', 'xml', 'yaml']);
    
    BashScript := Config.GenerateBash;
    CheckTrue(Pos('json xml yaml', BashScript) > 0);
    
    ZshScript := Config.GenerateZsh;
    CheckTrue(Pos('json xml yaml', ZshScript) > 0);
  finally
    Config.Free;
  end;
end;

procedure TTestCase_ArgsCompletion.Test_SaveCompletionFiles;
var
  Config: TCompletionConfig;
  TempDir: string;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Config.AddGlobalOption('verbose');
    
    TempDir := GetTempDir + 'completion_test';
    try
      Config.SaveAll(TempDir);
      
      CheckTrue(FileExists(TempDir + PathDelim + 'testapp.bash'));
      CheckTrue(FileExists(TempDir + PathDelim + '_testapp'));
      CheckTrue(FileExists(TempDir + PathDelim + 'testapp.ps1'));
      CheckTrue(FileExists(TempDir + PathDelim + 'testapp.fish'));
    finally
      // 清理测试文件
      if DirectoryExists(TempDir) then
      begin
        DeleteFile(TempDir + PathDelim + 'testapp.bash');
        DeleteFile(TempDir + PathDelim + '_testapp');
        DeleteFile(TempDir + PathDelim + 'testapp.ps1');
        DeleteFile(TempDir + PathDelim + 'testapp.fish');
        RemoveDir(TempDir);
      end;
    end;
  finally
    Config.Free;
  end;
end;

{ TTestCase_CompletionGenerators }

procedure TTestCase_CompletionGenerators.Test_BashGenerator_Create;
var
  Config: TCompletionConfig;
  Generator: TBashCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TBashCompletionGenerator.Create(Config);
    try
      CheckNotNull(Generator);
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

procedure TTestCase_CompletionGenerators.Test_ZshGenerator_Create;
var
  Config: TCompletionConfig;
  Generator: TZshCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TZshCompletionGenerator.Create(Config);
    try
      CheckNotNull(Generator);
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

procedure TTestCase_CompletionGenerators.Test_PowerShellGenerator_Create;
var
  Config: TCompletionConfig;
  Generator: TPowerShellCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TPowerShellCompletionGenerator.Create(Config);
    try
      CheckNotNull(Generator);
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

procedure TTestCase_CompletionGenerators.Test_BashGenerator_ShellType;
var
  Config: TCompletionConfig;
  Generator: TBashCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TBashCompletionGenerator.Create(Config);
    try
      CheckEquals(Ord(stBash), Ord(Generator.GetShellType));
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

procedure TTestCase_CompletionGenerators.Test_ZshGenerator_ShellType;
var
  Config: TCompletionConfig;
  Generator: TZshCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TZshCompletionGenerator.Create(Config);
    try
      CheckEquals(Ord(stZsh), Ord(Generator.GetShellType));
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

procedure TTestCase_CompletionGenerators.Test_PowerShellGenerator_ShellType;
var
  Config: TCompletionConfig;
  Generator: TPowerShellCompletionGenerator;
begin
  Config := CreateCompletionConfig('testapp', 'Test Application');
  try
    Generator := TPowerShellCompletionGenerator.Create(Config);
    try
      CheckEquals(Ord(stPowerShell), Ord(Generator.GetShellType));
    finally
      Generator.Free;
    end;
  finally
    Config.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ArgsCompletion);
  RegisterTest(TTestCase_CompletionGenerators);
end.
