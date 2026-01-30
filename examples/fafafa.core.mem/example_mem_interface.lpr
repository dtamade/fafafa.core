program example_mem_interface;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.interfaces,
  fafafa.core.mem.adapters,
  fafafa.core.mem.allocator,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.pool.slab;

procedure DemoInterfaces;
var
  LAlloc: IAllocator;
  LMem: TMemPool;
  LIMem: IMemPool;
  LMemPtr: Pointer;
  LStack: TStackPool;
  LIStack: IStackPool;
  LPtr1: Pointer;
  LPtr2: Pointer;
  LSlab: TSlabPool;
  LISlab: ISlabPool;
  LSlabPtr: Pointer;
begin
  WriteLn('--- Interface-first Demo ---');

  LAlloc := GetRtlAllocator;

  LMem := TMemPool.Create(64, 8, LAlloc);
  try
    LIMem := TMemPoolAdapter.Create(LMem);
    LMemPtr := LIMem.Alloc;
    if LMemPtr <> nil then
    begin
      FillChar(LMemPtr^, 64, 0);
      LIMem.Free(LMemPtr);
    end;
    LIMem.Reset;
  finally
    LMem.Destroy;
  end;

  LStack := TStackPool.Create(1024, LAlloc);
  try
    LIStack := TStackPoolAdapter.Create(LStack);
    LPtr1 := LIStack.Alloc(128);
    LPtr2 := LIStack.Alloc(256, 16);
    if (LPtr1 <> nil) and (LPtr2 <> nil) then
      WriteLn('Stack allocations OK');
    LIStack.Reset;
  finally
    LStack.Destroy;
  end;

  LSlab := TSlabPool.Create(4096, LAlloc);
  try
    LISlab := TSlabPoolAdapter.Create(LSlab);
    LSlabPtr := LISlab.Alloc(200);
    if LSlabPtr <> nil then
      LISlab.Free(LSlabPtr);
    LISlab.Reset;
  finally
    LSlab.Destroy;
  end;

  WriteLn('--- Done ---');
end;

begin
  try
    DemoInterfaces;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
