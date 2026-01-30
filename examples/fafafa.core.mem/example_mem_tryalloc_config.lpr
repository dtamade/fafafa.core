program example_mem_tryalloc_config;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool;

procedure DemoMemPool_TryAlloc_Config;
var
  LConfig: TMemPoolConfig;
  LPool: TMemPool;
  LPtr: Pointer;
begin
  WriteLn('--- MemPool TryAlloc + Config ---');
  LConfig.BlockSize := 64;
  LConfig.Capacity := 2;
  LConfig.Alignment := SizeOf(Pointer);
  LConfig.ZeroOnAlloc := False;
  LConfig.Allocator := nil; // 使用默认 RTL 分配器
  LPool := TMemPool.Create(LConfig);
  try
    if LPool.TryAlloc(LPtr) then
    begin
      try
        WriteLn('TryAlloc succeeded (block size=64)');
      finally
        LPool.ReleasePtr(LPtr);
      end;
    end
    else
      WriteLn('TryAlloc failed');
  finally
    LPool.Destroy;
  end;
end;

procedure DemoStackPool_TryAlloc_Config;
var
  LConfig: TStackPoolConfig;
  LPool: TStackPool;
  LPtr: Pointer;
begin
  WriteLn('--- StackPool TryAlloc + Config ---');
  LConfig.TotalSize := 1024;
  LConfig.Alignment := SizeOf(Pointer);
  LConfig.ZeroOnAlloc := True; // 构造后清零缓冲
  LConfig.Allocator := nil;
  LPool := TStackPool.Create(LConfig);
  try
    if LPool.TryAlloc(128, LPtr) then
      WriteLn('TryAlloc(128) succeeded')
    else
      WriteLn('TryAlloc(128) failed');
    LPool.Reset;
  finally
    LPool.Destroy;
  end;
end;

begin
  DemoMemPool_TryAlloc_Config;
  DemoStackPool_TryAlloc_Config;
end.
