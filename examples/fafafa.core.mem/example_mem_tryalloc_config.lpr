{$CODEPAGE UTF8}
program example_mem_tryalloc_config;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool;

procedure DemoMemPool_TryAlloc_Config;
var
  C: TMemPoolConfig;
  M: TMemPool;
  P: Pointer;
begin
  WriteLn('--- MemPool TryAlloc + Config ---');
  C.BlockSize := 64;
  C.Capacity := 2;
  C.Alignment := SizeOf(Pointer);
  C.ZeroOnAlloc := False;
  C.Allocator := nil; // 使用默认 RTL 分配器
  M := TMemPool.Create(C);
  try
    if M.TryAlloc(P) then
    begin
      try
        WriteLn('TryAlloc succeeded (block size=64)');
      finally
        M.ReleasePtr(P);
      end;
    end
    else
      WriteLn('TryAlloc failed');
  finally
    M.Destroy;
  end;
end;

procedure DemoStackPool_TryAlloc_Config;
var
  C: TStackPoolConfig;
  S: TStackPool;
  P: Pointer;
begin
  WriteLn('--- StackPool TryAlloc + Config ---');
  C.TotalSize := 1024;
  C.Alignment := SizeOf(Pointer);
  C.ZeroOnAlloc := True; // 构造后清零缓冲
  C.Allocator := nil;
  S := TStackPool.Create(C);
  try
    if S.TryAlloc(128, P) then
      WriteLn('TryAlloc(128) succeeded')
    else
      WriteLn('TryAlloc(128) failed');
    S.Reset;
  finally
    S.Destroy;
  end;
end;

begin
  try
    DemoMemPool_TryAlloc_Config;
    DemoStackPool_TryAlloc_Config;
    WriteLn('Demo completed.');
  except
    on E: Exception do begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

