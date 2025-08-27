program smoke_ringbuffer;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree.ringBuffer;

var
  RB: specialize TLockFreeRingBuffer<Integer>;
  i, v: Integer;
  ok: Boolean;
  doTimer: Boolean;
  ops, enqCnt, deqCnt: Int64;
  t0, t1: QWord;
  s: String;
begin
  try
    RB := specialize TLockFreeRingBuffer<Integer>.Create(16);
    try
      WriteLn('RingBuffer smoke...');
      for i := 1 to 10 do
      begin
        ok := RB.try_enqueue(i);
        if not ok then raise Exception.CreateFmt('RingBuffer try_enqueue failed at %d', [i]);
      end;
      for i := 1 to 10 do
      begin
        ok := RB.try_dequeue(v);
        if not ok then raise Exception.CreateFmt('RingBuffer try_dequeue failed at %d', [i]);
        if v <> i then raise Exception.CreateFmt('RingBuffer value mismatch: got %d expect %d', [v, i]);
      end;

      // Optional timing (set env SMOKE_TIMER=1, SMOKE_OPS=N)
      s := GetEnvironmentVariable('SMOKE_TIMER');
      doTimer := (s = '1');
      if doTimer then
      begin
        ops := StrToIntDef(GetEnvironmentVariable('SMOKE_OPS'), 100000);
        enqCnt := 0; deqCnt := 0;
        t0 := GetTickCount64;
        for i := 1 to ops do
        begin
          // ensure room
          while not RB.try_enqueue(i) do
          begin
            if RB.try_dequeue(v) then Inc(deqCnt);
          end;
          Inc(enqCnt);
        end;
        // drain
        while RB.try_dequeue(v) do Inc(deqCnt);
        t1 := GetTickCount64;
        if t1 = t0 then Inc(t1);
        WriteLn(Format('RingBuffer smoke timer: ops=%d ms=%d ops_per_sec=%d',
          [ops, t1 - t0, (ops * 1000) div (t1 - t0)]));
      end;

      WriteLn('RingBuffer smoke OK');
    finally
      RB.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Failed: ', E.Message);
      Halt(1);
    end;
  end;
end.

