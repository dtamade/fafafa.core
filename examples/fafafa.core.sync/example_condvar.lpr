program example_condvar;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync;

var
  M: ILock;
  CV: ICondVar;
  Ready: Boolean = False;

function Producer(P: Pointer): PtrInt;
begin
  Sleep(200);
  M.Acquire;
  try
    Ready := True;
    CV.Signal;
    WriteLn('Producer signaled');
  finally
    M.Release;
  end;
  Result := 0;
end;

function Consumer(P: Pointer): PtrInt;
var ok: Boolean;
begin
  M.Acquire;
  try
    while not Ready do
    begin
      ok := CV.Wait(M, 1000);
      if not ok then
      begin
        WriteLn('Consumer timeout waiting');
        Break;
      end;
    end;
    if Ready then WriteLn('Consumer observed Ready');
  finally
    M.Release;
  end;
  Result := 0;
end;

var T1, T2: TThreadID;
begin
  // 启用 Windows 条件变量路径（示例运行时需在 settings.inc 打开宏）
  M := MakeMutex;
  CV := MakeCondVar;

  BeginThread(@Consumer, nil, T1);
  BeginThread(@Producer, nil, T2);

  Sleep(1500);
end.

