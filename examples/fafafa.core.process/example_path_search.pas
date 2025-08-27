program example_path_search;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.process;

procedure DemonstratePathSearch;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LOutput: string;
begin
  WriteLn('=== PATH 搜索功能演示 ===');
  WriteLn;
  
  // 演示 1: 使用完整文件名（带扩展名）
  WriteLn('1. 使用完整文件名启动进程:');
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  LStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo "Hello from cmd.exe"'{$ELSE}'"Hello from echo"'{$ENDIF};
  LStartInfo.RedirectStandardOutput := True;
  
  LProcess := TProcess.Create(LStartInfo);
  try
    LProcess.Start;
    LOutput := LProcess.StandardOutput.ReadToEnd;
    LProcess.WaitForExit(5000);
    WriteLn('  输出: ', Trim(LOutput));
  finally
    LProcess := nil;
  end;
  WriteLn;
  
  // 演示 2: 使用无扩展名的文件名（依赖 PATHEXT）
  {$IFDEF WINDOWS}
  WriteLn('2. 使用无扩展名文件名启动进程 (依赖 PATHEXT):');
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'cmd';  // 无扩展名，将通过 PATHEXT 找到 cmd.exe
  LStartInfo.Arguments := '/c echo "Hello from cmd (no extension)"';
  LStartInfo.RedirectStandardOutput := True;
  
  LProcess := TProcess.Create(LStartInfo);
  try
    LProcess.Start;
    LOutput := LProcess.StandardOutput.ReadToEnd;
    LProcess.WaitForExit(5000);
    WriteLn('  输出: ', Trim(LOutput));
  finally
    LProcess := nil;
  end;
  WriteLn;
  
  // 演示 3: 使用其他 PATHEXT 扩展名
  WriteLn('3. 使用其他可执行文件 (通过 PATHEXT):');
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'notepad';  // 将找到 notepad.exe
  LStartInfo.Arguments := '';
  
  LProcess := TProcess.Create(LStartInfo);
  try
    LProcess.Start;
    WriteLn('  成功启动 notepad，PID: ', LProcess.ProcessId);
    Sleep(1000);  // 让 notepad 启动
    LProcess.Kill;  // 关闭 notepad
    WriteLn('  已关闭 notepad');
  finally
    LProcess := nil;
  end;
  WriteLn;
  {$ENDIF}
  
  // 演示 4: 错误处理 - 不存在的文件
  WriteLn('4. 错误处理 - 不存在的文件:');
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'nonexistent_program_12345';
  
  try
    LStartInfo.Validate;  // 这里会抛出异常
    WriteLn('  错误：应该抛出异常但没有');
  except
    on E: EProcessStartError do
      WriteLn('  正确捕获异常: ', E.Message);
  end;
  WriteLn;
  
  WriteLn('=== 演示完成 ===');
end;

begin
  try
    DemonstratePathSearch;
  except
    on E: Exception do
    begin
      WriteLn('❌ 异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  {$IFDEF WINDOWS}
  WriteLn('按任意键退出...');
  ReadLn;
  {$ENDIF}
end.
