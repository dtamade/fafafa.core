{$CODEPAGE UTF8}
unit test_process_group_exceptions;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, Classes, fafafa.core.process;

type
  {$IFDEF WINDOWS}
  // 测试专用的失败组：任何 Add 调用均抛出异常
  TFailGroup = class(TInterfacedObject, IProcessGroup)
  public
    procedure Add(const AProcess: IProcess);
    procedure TerminateGroup(aExitCode: Cardinal = 1);
    procedure KillTree(aExitCode: Cardinal = 1);
    function Count: Integer;
  end;
  {$ENDIF}

  TTestCase_ProcessGroup_Exceptions = class(TTestCase)
  published
    procedure Test_Add_NotStarted_Raises;
    procedure Test_Builder_WithGroup_AddFailure_DoesNotCrash;
  end;

implementation

{$IFDEF WINDOWS}
procedure TFailGroup.Add(const AProcess: IProcess);
begin
  raise EProcessError.Create('Injected Add failure');
end;

procedure TFailGroup.TerminateGroup(aExitCode: Cardinal);
begin
  // no-op
end;

procedure TFailGroup.KillTree(aExitCode: Cardinal);
begin
  // alias of TerminateGroup for test stub
end;

function TFailGroup.Count: Integer;
begin
  Result := 0;
end;
{$ENDIF}

procedure TTestCase_ProcessGroup_Exceptions.Test_Add_NotStarted_Raises;
var
  G: IProcessGroup;
  P: IProcess;
  B: IProcessBuilder;
  Caught: Boolean;
begin
  Caught := False;
  G := NewProcessGroup;
  if Assigned(G) then
  begin
    B := NewProcessBuilder.Exe('cmd.exe').Args(['/c','echo','HELLO']);
    P := B.Build; // 尚未启动，PID=0，应触发 Add 异常
    try
      G.Add(P);
    except
      on E: Exception do Caught := True;
    end;
    AssertTrue('Add should raise when process not started', Caught);
  end
  else
    AssertTrue(True); // 宏未启用则跳过
end;

procedure TTestCase_ProcessGroup_Exceptions.Test_Builder_WithGroup_AddFailure_DoesNotCrash;
var
  FG: IProcessGroup;
  C: IChild;
begin
  {$IFDEF WINDOWS}
  FG := TFailGroup.Create;
  C := NewProcessBuilder.Exe('cmd.exe').Args(['/c','echo','OK']).WithGroup(FG).Start;
  try
    // Add 失败由 Builder 内部吞掉，不应影响子进程完成
    AssertTrue(C.WaitForExit(3000));
  finally
    // no-op
  end;
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ProcessGroup_Exceptions);
end.

