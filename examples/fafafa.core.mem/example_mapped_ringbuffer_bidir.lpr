program example_mapped_ringbuffer_bidir;
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes, fafafa.core.mem.mappedRingBuffer;

function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;


procedure RunCreator(const Name: string; Capacity: UInt64; ElemSize: UInt32; MsgCount: Integer; BatchSize: Integer; SleepUs: Integer);
var
  rb: TMappedRingBuffer;
  i, j, v: Integer;
  StartTs, EndTs, ElapsedMs: QWord;
  Writeln('[Creator] creating shared ring: ', Name);
  rb := TMappedRingBuffer.Create;
  try
    if not rb.CreateShared(Name, Capacity, ElemSize) then
      raise Exception.Create('CreateShared failed');
    Writeln('[Creator] ready. Pushing ', MsgCount, ' integers then waiting for replies...');
    // 发送阶段
    i := 0;
    StartTs := NowMs;
    while i < MsgCount do
    begin
      // 批量推送
      for j := 1 to BatchSize do
      begin
        if i >= MsgCount then Break;
        v := (i+1) * 100;
        while not rb.Push(@v) do ;
        Inc(i);
      end;
      if SleepUs > 0 then Sleep(SleepUs div 1000);
    end;
    // 接收同等数量的回包
    i := 0;
    while i < MsgCount do
    begin
      while not rb.Pop(@v) do ;
      Inc(i);
    end;
    EndTs := NowMs;
    ElapsedMs := EndTs - StartTs;
    if ElapsedMs = 0 then ElapsedMs := 1;
    Writeln(Format('[Creator] Done. msgs=%d, batch=%d, time=%.3fs, qps=%.2f',
      [MsgCount, BatchSize, ElapsedMs/1000.0, (MsgCount*2) / (ElapsedMs/1000.0)]));
  finally
    rb.Free;
  end;
end;

procedure RunOpener(const Name: string; MsgCount: Integer; BatchSize: Integer; SleepUs: Integer);
var
  rb: TMappedRingBuffer;
  i, j, v: Integer;
  StartTs, EndTs, ElapsedMs: QWord;
  Writeln('[Opener] opening shared ring: ', Name);
  rb := TMappedRingBuffer.Create;
  try
    if not rb.OpenShared(Name) then
      raise Exception.Create('OpenShared failed');
    Writeln('[Opener] ready. Receiving ', MsgCount, ' integers and replying...');
    i := 0;
    StartTs := NowMs;
    while i < MsgCount do
    begin
      // 批量接收
      for j := 1 to BatchSize do
      begin
        if i >= MsgCount then Break;
        while not rb.Pop(@v) do ;
        // 立即回复
        Inc(v);
        while not rb.Push(@v) do ;
        Inc(i);
      end;
      if SleepUs > 0 then Sleep(SleepUs div 1000);
    end;
    EndTs := NowMs;
    ElapsedMs := EndTs - StartTs;
    if ElapsedMs = 0 then ElapsedMs := 1;
    Writeln(Format('[Opener] Done. msgs=%d, batch=%d, time=%.3fs, qps=%.2f',
      [MsgCount, BatchSize, ElapsedMs/1000.0, (MsgCount*2) / (ElapsedMs/1000.0)]));
  finally
    rb.Free;
  end;
end;

var
  Mode, Name: string;
  Capacity: UInt64 = 1024;
  ElemSize: UInt32 = SizeOf(Integer);
  MsgCount: Integer = 10;
  BatchSize: Integer = 1;
  SleepUs: Integer = 0;
begin
  if ParamCount < 2 then
  begin
    Writeln('Usage: ', ParamStr(0), ' [creator|opener] <shared-name> [capacity] [elemSize] [msgCount] [batchSize] [sleepUs]');
    Writeln('  creator needs capacity & elemSize; opener ignores them');
    Halt(1);
  end;
  Mode := LowerCase(ParamStr(1));
  Name := ParamStr(2);
  if ParamCount >= 3 then
  begin
    if (Mode = 'creator') and (ParamCount >= 4) then
    begin
      Capacity := StrToQWordDef(ParamStr(3), Capacity);
      ElemSize := StrToIntDef(ParamStr(4), ElemSize);
    end;
    if ParamCount >= 5 then
      MsgCount := StrToIntDef(ParamStr(5), MsgCount);
    if ParamCount >= 6 then
      BatchSize := StrToIntDef(ParamStr(6), BatchSize);
    if ParamCount >= 7 then
      SleepUs := StrToIntDef(ParamStr(7), SleepUs);
  end;
  if Mode = 'creator' then
    RunCreator(Name, Capacity, ElemSize, MsgCount, BatchSize, SleepUs)
  else if Mode = 'opener' then
    RunOpener(Name, MsgCount, BatchSize, SleepUs)
  else
  begin
    Writeln('Unknown mode: ', Mode);
    Halt(1);
  end;
end.

