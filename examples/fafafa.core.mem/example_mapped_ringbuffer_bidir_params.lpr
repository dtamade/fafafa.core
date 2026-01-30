program example_mapped_ringbuffer_bidir_params;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.mem.mappedRingBuffer;

procedure Usage;
begin
  Writeln('Usage: ', ParamStr(0), ' [creator|opener] <name> [capacity] [count] [sleep_ms]');
  Writeln('  capacity: element count (default 1024, rounded to power of 2)');
  Writeln('  count:    messages to send (default 10000)');
  Writeln('  sleep_ms: optional sleep between ops (default 0)');
end;

procedure RunCreator(const Name: string; Capacity, Count: Integer; SleepMs: Integer);
var
  rb: TMappedRingBuffer;
  i, v: Integer;
  startTick, endTick: QWord;
  elapsedMs: Double;
begin
  rb := TMappedRingBuffer.Create;
  try
    if not rb.CreateShared(Name, Capacity, SizeOf(Integer)) then
      raise Exception.Create('CreateShared failed');

    startTick := GetTickCount64;
    for i := 1 to Count do
    begin
      v := i;
      while not rb.Push(@v) do ;
      if SleepMs > 0 then Sleep(SleepMs);
      while not rb.Pop(@v) do ;
    end;
    endTick := GetTickCount64;
    elapsedMs := (endTick - startTick);
    Writeln(Format('[Creator] count=%d elapsed=%.0f ms, qps=%.0f',
      [Count, elapsedMs, (Count*2) / (elapsedMs/1000.0)]));
  finally
    rb.Free;
  end;
end;

procedure RunOpener(const Name: string; SleepMs: Integer);
var
  rb: TMappedRingBuffer;
  v: Integer;
  i, count: Integer;
begin
  rb := TMappedRingBuffer.Create;
  try
    if not rb.OpenShared(Name) then
      raise Exception.Create('OpenShared failed');
    // responder: echo back incremented value
    count := High(Integer);
    for i := 1 to count do
    begin
      while not rb.Pop(@v) do ;
      Inc(v);
      if SleepMs > 0 then Sleep(SleepMs);
      while not rb.Push(@v) do ;
    end;
  finally
    rb.Free;
  end;
end;

var
  Mode, Name: string;
  Capacity, Count, SleepMs: Integer;
begin
  if ParamCount < 2 then begin Usage; Halt(1); end;
  Mode := LowerCase(ParamStr(1));
  Name := ParamStr(2);
  Capacity := 1024;
  Count := 10000;
  SleepMs := 0;
  if ParamCount >= 3 then Val(ParamStr(3), Capacity);
  if ParamCount >= 4 then Val(ParamStr(4), Count);
  if ParamCount >= 5 then Val(ParamStr(5), SleepMs);
  if Mode = 'creator' then
    RunCreator(Name, Capacity, Count, SleepMs)
  else if Mode = 'opener' then
    RunOpener(Name, SleepMs)
  else begin Usage; Halt(1); end;
end.

