program example_mem_microbench;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.pool.slab;

procedure BenchMemPool;
const
  N = 200000;
var
  LPool: TMemPool;
  LIndex: Integer;
  LPtr: Pointer;
  LStart: Int64;
  LEnd: Int64;
begin
  LPool := TMemPool.Create(64, 1024);
  try
    LStart := GetTickCount64;
    for LIndex := 1 to N do
    begin
      LPtr := LPool.Alloc;
      if LPtr <> nil then
        LPool.ReleasePtr(LPtr);
    end;
    LEnd := GetTickCount64;
    if (LEnd - LStart) > 0 then
      WriteLn('MemPool: ops=', N * 2, ' time(ms)=', LEnd - LStart,
              ' ops/ms=', (N * 2) / (LEnd - LStart):0:2)
    else
      WriteLn('MemPool: ops=', N * 2, ' time(ms)=', LEnd - LStart);
  finally
    if (LEnd - LStart) > 0 then
      WriteLn('MemPool: est MB/s≈', ((N * 2) * 64.0) / 1024.0 / 1024.0 / ((LEnd - LStart) / 1000.0):0:2);

    LPool.Destroy;
  end;
end;

procedure BenchStackPool;
const
  N = 200000;
var
  LPool: TStackPool;
  LIndex: Integer;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LStart: Int64;
  LEnd: Int64;
begin
  LPool := TStackPool.Create(1024 * 64);
  try
    LStart := GetTickCount64;
    for LIndex := 1 to N do
    begin
      LPtr1 := LPool.Alloc(64);
      LPtr2 := LPool.Alloc(128, 16);
      if (LIndex and 1023) = 0 then
        LPool.Reset;
    end;
    LEnd := GetTickCount64;
    if (LEnd - LStart) > 0 then
      WriteLn('StackPool: est MB/s≈', (((N) * 64.0 + (N) * 128.0)) / 1024.0 / 1024.0 / ((LEnd - LStart) / 1000.0):0:2);

    if (LEnd - LStart) > 0 then
      WriteLn('StackPool: ops≈', N * 2, ' time(ms)=', LEnd - LStart,
              ' ops/ms=', (N * 2) / (LEnd - LStart):0:2)
    else
      WriteLn('StackPool: ops≈', N * 2, ' time(ms)=', LEnd - LStart);
  finally
    LPool.Destroy;
  end;
end;

procedure BenchSlabPool;
const
  N = 200000;
var
  LPool: TSlabPool;
  LIndex: Integer;
  LPtr: Pointer;
  LStart: Int64;
  LEnd: Int64;
begin
  LPool := TSlabPool.Create(1024 * 256);
  try
    LStart := GetTickCount64;
    for LIndex := 1 to N do
    begin
      LPtr := LPool.Alloc(64);
      if LPtr <> nil then
        LPool.ReleasePtr(LPtr);
    end;
    LEnd := GetTickCount64;
    if (LEnd - LStart) > 0 then
    begin
      WriteLn('SlabPool: ops=', N * 2, ' time(ms)=', LEnd - LStart,
              ' ops/ms=', (N * 2) / (LEnd - LStart):0:2);
      WriteLn('SlabPool: est MB/s≈', ((N * 2) * 64.0) / 1024.0 / 1024.0 / ((LEnd - LStart) / 1000.0):0:2);
    end
    else
      WriteLn('SlabPool: ops=', N * 2, ' time(ms)=', LEnd - LStart);
  finally
    LPool.Destroy;
  end;
end;

begin
  BenchMemPool;
  BenchStackPool;
  BenchSlabPool;
end.
