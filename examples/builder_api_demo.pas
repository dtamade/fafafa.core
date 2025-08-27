program builder_api_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.process;

procedure DemoBasicUsage;
var
  LOutput: string;
  LSuccess: Boolean;
begin
  WriteLn('=== 基础使用示例 ===');
  
  // 简单命令执行
  LOutput := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
    {$IFDEF WINDOWS}
    .Args(['/c', 'echo', 'Hello from Builder API!'])
    {$ELSE}
    .Args(['Hello from Builder API!'])
    {$ENDIF}
    .Output;
  
  WriteLn('输出: ', Trim(LOutput));
  
  // 检查命令是否成功
  LSuccess := NewProcessBuilder
    .Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
    {$IFDEF WINDOWS}
    .Args(['/c', 'echo', 'Success test'])
    {$ELSE}
    .Args(['Success test'])
    {$ENDIF}
    .Success;
  
  WriteLn('命令执行成功: ', LSuccess);
end;

procedure DemoFluentInterface;
var
  LChild: IChild;
begin
  WriteLn(#13#10'=== 流畅接口示例 ===');
  
  // 复杂的方法链配置
  LChild := NewProcessBuilder
    .Executable({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
    {$IFDEF WINDOWS}
    .ArgsFrom('/c echo "Fluent Interface Demo"')
    {$ELSE}
    .ArgsFrom('"Fluent Interface Demo"')
    {$ENDIF}
    .SetEnv('DEMO_VAR', 'demo_value')
    .SetEnv('BUILDER_API', 'modern')
    .Silent
    .HighPriority
    .NoShell
    .Spawn;
  
  WriteLn('进程已启动，等待完成...');
  if LChild.WaitForExit(5000) then
    WriteLn('进程执行完成')
  else
    WriteLn('进程执行超时');
end;

procedure DemoConvenienceMethods;
var
  LBuilder: IProcessBuilder;
  LCommandLine: string;
begin
  WriteLn(#13#10'=== 便捷方法示例 ===');
  
  // 使用便捷方法配置
  LBuilder := NewProcessBuilder
    .Command('example.exe')
    .Args(['arg1', 'arg2', 'argument with spaces'])
    .WorkingDir('C:\temp')
    .Envs(['VAR1=value1', 'VAR2=value2', 'VAR3=value3'])
    .Background
    .CaptureOutput;
  
  // 调试信息
  LCommandLine := LBuilder.GetCommandLine;
  WriteLn('生成的命令行: ', LCommandLine);
  WriteLn('配置摘要: ', LBuilder.ToString);
  WriteLn('环境变量摘要: ', LBuilder.GetEnvironmentSummary);
  
  // 验证配置
  if LBuilder.IsValid then
    WriteLn('配置验证: 通过')
  else
    WriteLn('配置验证: 失败');
end;

procedure DemoAliasesAndOverloads;
var
  LArgs: TStringList;
  LEnvVars: TStringList;
  LBuilder: IProcessBuilder;
begin
  WriteLn(#13#10'=== 别名和重载示例 ===');
  
  // 使用 TStringList 参数
  LArgs := TStringList.Create;
  LEnvVars := TStringList.Create;
  try
    LArgs.Add('--verbose');
    LArgs.Add('--output=result.txt');
    LArgs.Add('input.txt');
    
    LEnvVars.Add('LOG_LEVEL=DEBUG');
    LEnvVars.Add('OUTPUT_FORMAT=JSON');
    
    LBuilder := NewProcessBuilder
      .Executable('processor.exe')
      .Args(LArgs)
      .CurrentDir('C:\workspace')
      .EnvsFrom(LEnvVars)
      .Interactive
      .NormalPriority
      .WindowNormal;
    
    WriteLn('使用 TStringList 配置完成');
    WriteLn('命令行: ', LBuilder.GetCommandLine);
    
  finally
    LArgs.Free;
    LEnvVars.Free;
  end;
end;

procedure DemoErrorHandling;
var
  LBuilder: IProcessBuilder;
  LErrors: TStringList;
  LIndex: Integer;
begin
  WriteLn(#13#10'=== 错误处理示例 ===');
  
  // 创建无效配置
  LBuilder := NewProcessBuilder
    .WorkingDir('C:\nonexistent_directory_12345');
  
  // 检查验证错误
  LErrors := LBuilder.GetValidationErrors;
  try
    WriteLn('验证错误数量: ', LErrors.Count);
    for LIndex := 0 to LErrors.Count - 1 do
      WriteLn('  错误 ', LIndex + 1, ': ', LErrors[LIndex]);
  finally
    LErrors.Free;
  end;
  
  // 尝试验证（会抛出异常）
  try
    LBuilder.Validate;
    WriteLn('验证通过');
  except
    on E: Exception do
      WriteLn('验证异常: ', E.Message);
  end;
end;

begin
  WriteLn('fafafa.core.process - 现代化 Builder API 演示');
  WriteLn('================================================');
  
  try
    DemoBasicUsage;
    DemoFluentInterface;
    DemoConvenienceMethods;
    DemoAliasesAndOverloads;
    DemoErrorHandling;
    
    WriteLn(#13#10'演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  {$IFDEF WINDOWS}
  WriteLn('按任意键退出...');
  ReadLn;
  {$ENDIF}
end.
