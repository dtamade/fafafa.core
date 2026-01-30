program test_padding_smoke;
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.mpmcQueue;

procedure Smoke_SPSC;
var
  Q: TIntegerSPSCQueue;
  i, x: Integer;
begin
  WriteLn('SPSC smoke...');
  Q := CreateIntSPSCQueue(64);
  try
    for i := 1 to 10 do
      if not Q.Enqueue(i) then raise Exception.Create('SPSC enqueue failed');
    for i := 1 to 10 do
    begin
      if not Q.Dequeue(x) then raise Exception.Create('SPSC dequeue failed');
      if x <> i then raise Exception.Create('SPSC value mismatch');
    end;
  finally
    Q.Free;
  end;
end;

procedure Smoke_MPMC;
var
  Q: TIntMPMCQueue;
  i, x: Integer;
begin
  WriteLn('MPMC smoke...');
  Q := CreateIntMPMCQueue(64);
  try
    for i := 1 to 10 do
      if not Q.Enqueue(i) then raise Exception.Create('MPMC enqueue failed');
    for i := 1 to 10 do
    begin
      if not Q.Dequeue(x) then raise Exception.Create('MPMC dequeue failed');
      if x <> i then raise Exception.Create('MPMC value mismatch');
    end;
  finally
    Q := nil;
  end;
end;

begin
  try
    Smoke_SPSC;
    Smoke_MPMC;
    WriteLn('Padding smoke OK');
  except
    on E: Exception do begin
      WriteLn('Failed: ', E.Message);
      Halt(1);
    end;
  end;
end.

