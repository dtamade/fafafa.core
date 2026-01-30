unit test_resource_cleanup_half_init;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_ResourceCleanup_HalfInit = class(TTestCase)
  published
    procedure Test_Cleanup_After_Start_Failure_HalfInitialized;
  end;

implementation

procedure TTestCase_ResourceCleanup_HalfInit.Test_Cleanup_After_Start_Failure_HalfInitialized;
var
  SI: IProcessStartInfo;
  P: IProcess;
  RaisedErr: Boolean;
begin
  // Arrange: 打开重定向以确保会创建管道，再让启动阶段失败（不存在的可执行或非法工作目录）
  SI := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  SI.FileName := 'definitely_nonexistent_exe_zzz.exe';
  {$ELSE}
  SI.FileName := '/definitely/nonexistent/ux_zzz_exe';
  {$ENDIF}
  SI.Arguments := '';
  SI.RedirectStandardOutput := True;
  SI.RedirectStandardError := True;
  SI.RedirectStandardInput := True;
  SI.SetDrainOutput(True);
  // 设置一个不存在的工作目录，进一步确保 Start 失败
  SI.WorkingDirectory := IncludeTrailingPathDelimiter(GetCurrentDir) + 'nonexistent_dir_for_test_cleanup';

  P := TProcess.Create(SI);
  RaisedErr := False;
  try
    try
      P.Start; // 预期抛出启动异常（CreatePipes 已创建 => 半初始化场景）
      Fail('Start should raise for invalid executable/working directory');
    except
      on E: Exception do
        RaisedErr := True;
    end;
  finally
    // 重点：释放半初始化对象不应崩溃或二次关闭句柄
    P := nil;
  end;
  CheckTrue(RaisedErr, 'Expected an exception during Start');
end;

initialization
  RegisterTest(TTestCase_ResourceCleanup_HalfInit);

end.

