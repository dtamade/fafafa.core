{$CODEPAGE UTF8}
unit test_shell_shellexecute_minimal;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_ShellExecute_Min = class(TTestCase)
  published
    {$IFDEF WINDOWS}
    procedure Test_ShellExecute_Success_NoRedirect_NoEnv;
    procedure Test_ShellExecute_Reject_When_Redirect;
    procedure Test_ShellExecute_Reject_When_CustomEnv;
    {$ENDIF}
  end;

implementation

{$IFDEF WINDOWS}

procedure TTestCase_ShellExecute_Min.Test_ShellExecute_Success_NoRedirect_NoEnv;
var
  B: IProcessBuilder;
  P: IProcess;
begin
  // 使用 cmd.exe /c exit 0，确保快速退出且不依赖 GUI 交互
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','exit','0'])
        .UseShell(True);
  P := B.Build;
  P.Start;
  AssertTrue(P.ProcessId > 0);
  AssertTrue('Process should exit quickly', P.WaitForExit(3000));
end;

procedure TTestCase_ShellExecute_Min.Test_ShellExecute_Reject_When_Redirect;
var
  B: IProcessBuilder;
  P: IProcess;
  Raised: Boolean = False;
begin
  // UseShellExecute=True 且存在任意重定向/合流 → 拒绝
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','exit','0'])
        .UseShell(True)
        .RedirectStdOut(True);
  try
    P := B.Build;
    P.Start;
  except
    on E: EProcessStartError do Raised := True;
  end;
  AssertTrue('ShellExecute 模式下应拒绝重定向', Raised);
end;

procedure TTestCase_ShellExecute_Min.Test_ShellExecute_Reject_When_CustomEnv;
var
  B: IProcessBuilder;
  P: IProcess;
  Raised: Boolean = False;
begin
  // UseShellExecute=True 且自定义环境 → 拒绝（最小子集约束）
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','exit','0'])
        .UseShell(True)
        .Env('X_TEST','1');
  try
    P := B.Build;
    P.Start;
  except
    on E: EProcessStartError do Raised := True;
  end;
  AssertTrue('ShellExecute 模式下应拒绝自定义环境', Raised);
end;

{$ENDIF}

initialization
  RegisterTest(TTestCase_ShellExecute_Min);

end.

