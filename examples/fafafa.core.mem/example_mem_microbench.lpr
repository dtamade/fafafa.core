{$CODEPAGE UTF8}
program example_mem_microbench;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.slabPool;

function NowTick: Int64; inline;
begin
  Result := MilliSecondOf(Now);
end;

procedure BenchMemPool;
const N = 200000;
var L: TMemPool; i: Integer; p: Pointer; t0,t1: Int64;
begin
  L := TMemPool.Create(64, 1024);
  try
    t0 := GetTickCount64;
    for i := 1 to N do begin p := L.Alloc; if p<>nil then L.ReleasePtr(p); end;
    t1 := GetTickCount64;
    if (t1-t0)>0 then
      WriteLn('MemPool: ops=', N*2, ' time(ms)=', t1-t0, ' ops/ms=', (N*2) / (t1-t0):0:2)
    else
      WriteLn('MemPool: ops=', N*2, ' time(ms)=', t1-t0);
  finally
    // 估算 MB/s：以 64 字节块估算
    if (t1-t0)>0 then
      WriteLn('MemPool: est MB/s≈', ((N*2)*64.0) / 1024.0 / 1024.0 / ((t1-t0)/1000.0):0:2);

    L.Destroy;
  end;
end;

procedure BenchStackPool;
const N = 200000;
var L: TStackPool; i: Integer; p1,p2: Pointer; t0,t1: Int64;
begin
  L := TStackPool.Create(1024*64);
  try
    t0 := GetTickCount64;
    for i := 1 to N do begin p1 := L.Alloc(64); p2 := L.Alloc(128, 16); if (i and 1023)=0 then L.Reset; end;
    t1 := GetTickCount64;
    // 估算 MB/s：以 64/128 字节估算
    if (t1-t0)>0 then
      WriteLn('StackPool: est MB/s≈', (((N)*64.0+(N)*128.0)) / 1024.0 / 1024.0 / ((t1-t0)/1000.0):0:2);

    if (t1-t0)>0 then
      WriteLn('StackPool: ops≈', N*2, ' time(ms)=', t1-t0, ' ops/ms=', (N*2) / (t1-t0):0:2)
    else
      WriteLn('StackPool: ops≈', N*2, ' time(ms)=', t1-t0);
  finally
    L.Destroy;
  end;
end;

procedure BenchSlabPool;
const N = 200000;
var L: TSlabPool; i: Integer; p: Pointer; t0,t1: Int64;
begin
  L := TSlabPool.Create(1024*256);
  try
    t0 := GetTickCount64;
    for i := 1 to N do begin p := L.Alloc(64); if p<>nil then L.ReleasePtr(p); end;
    t1 := GetTickCount64;
    if (t1-t0)>0 then
    begin
      WriteLn('SlabPool: ops=', N*2, ' time(ms)=', t1-t0, ' ops/ms=', (N*2) / (t1-t0):0:2);
      // 估算 MB/s：以 64 字节估算
      WriteLn('SlabPool: est MB/s≈', ((N*2)*64.0) / 1024.0 / 1024.0 / ((t1-t0)/1000.0):0:2);
    end
    else
      WriteLn('SlabPool: ops=', N*2, ' time(ms)=', t1-t0);
  finally
    L.Destroy;
  end;
end;

begin
  BenchMemPool;
  BenchStackPool;
  BenchSlabPool;
end.

