program example_thread_select_bench;
{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.thread;

function ModeName: string;
begin
  {$IFDEF FAFAFA_THREAD_SELECT_NONPOLLING}
  Result := 'NonPolling(OnComplete)';
  {$ELSE}
  Result := 'Polling(WaitFor-slices)';
  {$ENDIF}
end;

var
  GStep, GSpan, GBase: Integer;

procedure BenchCase(const N, Iter: Integer);
var
  i, r, idx: Integer;
  startTick, endTick, total: QWord;
  Futs: array of IFuture;
  dur: Integer;
begin
  total := 0;
  for r := 1 to Iter do
  begin
    // Prepare a batch of N futures with staggered sleeps
    SetLength(Futs, N);
    for i := 0 to N - 1 do
    begin
      dur := GBase + (i * GStep) mod GSpan; // configurable distribution
      Futs[i] := TThreads.Spawn(function: Boolean
      begin
        SysUtils.Sleep(dur);
        Result := True;
      end);
    end;

    startTick := GetTickCount64;
    idx := Select(Futs, 5000);
    endTick := GetTickCount64;
    total += (endTick - startTick);

    // Drain to avoid piling up tasks
    for i := 0 to N - 1 do
      if Assigned(Futs[i]) then Futs[i].WaitFor(2000);
  end;
  WriteLn(Format('N=%d Iter=%d  avg=%.3f ms  mode=%s',
    [N, Iter, total / Iter, ModeName()]));
end;

var
  iter: Integer;
begin
  // Defaults
  iter := 200;
  GStep := 7; GSpan := 60; GBase := 20;
  // Args: 1=Iter, 2=Step, 3=Span, 4=Base
  if ParamCount >= 1 then iter := StrToIntDef(ParamStr(1), iter);
  if ParamCount >= 2 then GStep := StrToIntDef(ParamStr(2), GStep);
  if ParamCount >= 3 then GSpan := StrToIntDef(ParamStr(3), GSpan);
  if ParamCount >= 4 then GBase := StrToIntDef(ParamStr(4), GBase);

  WriteLn('Select bench (', ModeName(), ')');
  BenchCase(2, iter);
  BenchCase(8, iter);
  BenchCase(32, iter);
end.

