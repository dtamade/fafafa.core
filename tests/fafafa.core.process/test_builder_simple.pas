unit test_builder_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type

  { TTestCase_BuilderSimple - 简化的 Builder API 测试
  
    测试 ProcessBuilder 的核心功能：
    1. 基本方法链
    2. 别名方法
    3. 便捷方法
    4. 构建和启动
  }
  TTestCase_BuilderSimple = class(TTestCase)
  private
    FBuilder: IProcessBuilder;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure TestBasicChaining;
    procedure TestAliaseMethods;
    procedure TestConvenienceMethods;
    procedure TestBuildAndStart;
    procedure TestValidation;
    procedure TestDebugging;
  end;

implementation

{ TTestCase_BuilderSimple }

procedure TTestCase_BuilderSimple.SetUp;
begin
  inherited SetUp;
  FBuilder := NewProcessBuilder;
end;

procedure TTestCase_BuilderSimple.TearDown;
begin
  FBuilder := nil;
  inherited TearDown;
end;

procedure TTestCase_BuilderSimple.TestBasicChaining;
var
  LStartInfo: IProcessStartInfo;
begin
  // 测试基本方法链
  FBuilder.Exe('test.exe')
          .Arg('arg1')
          .Arg('arg2')
          .Cwd('C:\test')
          .Env('VAR1', 'value1')
          .RedirectStdOut(True);
  
  LStartInfo := FBuilder.GetStartInfo;
  AssertEquals('可执行文件应该被设置', 'test.exe', LStartInfo.FileName);
  AssertTrue('参数应该包含 arg1', Pos('arg1', LStartInfo.Arguments) > 0);
  AssertTrue('参数应该包含 arg2', Pos('arg2', LStartInfo.Arguments) > 0);
  AssertEquals('工作目录应该被设置', 'C:\test', LStartInfo.WorkingDirectory);
  AssertEquals('环境变量应该被设置', 'value1', LStartInfo.GetEnvironmentVariable('VAR1'));
  AssertTrue('输出重定向应该被启用', LStartInfo.RedirectStandardOutput);
end;

procedure TTestCase_BuilderSimple.TestAliaseMethods;
var
  LStartInfo: IProcessStartInfo;
begin
  // 测试别名方法
  FBuilder.Command('command.exe')
          .SetEnv('ALIAS_VAR', 'alias_value')
          .WorkingDir('C:\working')
          .CaptureOutput;
  
  LStartInfo := FBuilder.GetStartInfo;
  AssertEquals('Command 别名应该工作', 'command.exe', LStartInfo.FileName);
  AssertEquals('SetEnv 别名应该工作', 'alias_value', LStartInfo.GetEnvironmentVariable('ALIAS_VAR'));
  AssertEquals('WorkingDir 别名应该工作', 'C:\working', LStartInfo.WorkingDirectory);
  AssertTrue('CaptureOutput 应该启用输出重定向', LStartInfo.RedirectStandardOutput);
  AssertTrue('CaptureOutput 应该启用错误重定向', LStartInfo.RedirectStandardError);
end;

procedure TTestCase_BuilderSimple.TestConvenienceMethods;
var
  LStartInfo: IProcessStartInfo;
begin
  // 测试便捷方法
  FBuilder.Executable('program.exe')
          .Silent
          .HighPriority;
  
  LStartInfo := FBuilder.GetStartInfo;
  AssertEquals('Executable 别名应该工作', 'program.exe', LStartInfo.FileName);
  AssertTrue('Silent 应该启用输出重定向', LStartInfo.RedirectStandardOutput);
  AssertTrue('Silent 应该启用错误重定向', LStartInfo.RedirectStandardError);
  AssertTrue('HighPriority 应该设置高优先级', LStartInfo.Priority = ppHigh);
  AssertTrue('Silent 应该隐藏窗口', LStartInfo.WindowShowState = wsHidden);
end;

procedure TTestCase_BuilderSimple.TestBuildAndStart;
var
  LProcess: IProcess;
  LChild: IChild;
begin
  // 测试构建和启动（使用最小非交互命令，避免环境相关的输出/管道差异）
  FBuilder.Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
          {$IFDEF WINDOWS}
          .Args(['/c', 'exit', '0'])
          {$ELSE}
          .Args(['-c', 'exit 0'])
          {$ENDIF}
          .NoRedirect;

  // 测试构建
  LProcess := FBuilder.Build;
  AssertNotNull('Build 应该返回进程实例', LProcess);
  
  // 测试启动
  LChild := FBuilder.Start;
  AssertNotNull('Start 应该返回子进程', LChild);
  AssertTrue('进程应该能正常结束', LChild.WaitForExit(5000));
  
  // 测试别名 - 创建新的 Builder 实例
  LChild := NewProcessBuilder
    .Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    {$IFDEF WINDOWS}
    .Args(['/c', 'exit', '0'])
    {$ELSE}
    .Args(['-c', 'exit 0'])
    {$ENDIF}
    .NoRedirect
    .Spawn;
  AssertNotNull('Spawn 应该返回子进程', LChild);
  AssertTrue('进程应该能正常结束', LChild.WaitForExit(5000));
end;

procedure TTestCase_BuilderSimple.TestValidation;
var
  LErrors: TStringList;
begin
  // 测试验证功能
  AssertFalse('空配置应该无效', FBuilder.IsValid);
  
  LErrors := FBuilder.GetValidationErrors;
  try
    AssertTrue('应该有验证错误', LErrors.Count > 0);
  finally
    LErrors.Free;
  end;
  
  // 设置有效配置
  FBuilder.Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF});
  AssertTrue('有效配置应该通过验证', FBuilder.IsValid);
end;

procedure TTestCase_BuilderSimple.TestDebugging;
var
  LCommandLine, LToString: string;
begin
  // 测试调试功能
  FBuilder.Exe('debug.exe')
          .Arg('debug_arg')
          .Env('DEBUG_VAR', 'debug_value');
  
  LCommandLine := FBuilder.GetCommandLine;
  AssertTrue('命令行应该包含可执行文件', Pos('debug.exe', LCommandLine) > 0);
  AssertTrue('命令行应该包含参数', Pos('debug_arg', LCommandLine) > 0);
  
  LToString := FBuilder.ToString;
  AssertTrue('ToString 应该包含可执行文件', Pos('debug.exe', LToString) > 0);
end;

initialization
  RegisterTest(TTestCase_BuilderSimple);

end.
