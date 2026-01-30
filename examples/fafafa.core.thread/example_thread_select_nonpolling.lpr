program example_thread_select_nonpolling;
{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.thread;

procedure DemoNonPolling;
var
  F1, F2, F3: IFuture;
  Idx: Integer;
begin
  WriteLn('Demo: Select first completed (non-polling macro recommended)');
  F1 := TThreads.Spawn(function: Boolean begin SysUtils.Sleep(150); Result := True; end);
  F2 := TThreads.Spawn(function: Boolean begin SysUtils.Sleep(80);  Result := True; end);
  F3 := TThreads.Spawn(function: Boolean begin SysUtils.Sleep(200); Result := True; end);

  Idx := Select([F1, F2, F3], 2000);
  WriteLn('First completed index = ', Idx);
end;

begin
  DemoNonPolling;
end.

