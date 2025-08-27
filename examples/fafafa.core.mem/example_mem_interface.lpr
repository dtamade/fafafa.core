{$CODEPAGE UTF8}
program example_mem_interface;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.interfaces,
  fafafa.core.mem.adapters,
  fafafa.core.mem.allocator,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.slabPool;

procedure DemoInterfaces;
var
  LAlloc: TAllocator;
  LMem: TMemPool; LIMem: IMemPool; PMem: Pointer;
  LStack: TStackPool; LIStack: IStackPool; P1, P2: Pointer;
  LSlab: TSlabPool; LISlab: ISlabPool; PS: Pointer;
begin
  WriteLn('--- Interface-first Demo ---');

  // 使用框架分配器（示例）
  LAlloc := GetRtlAllocator;

  // IMemPool
  LMem := TMemPool.Create(64, 8, LAlloc);
  try
    LIMem := TMemPoolAdapter.Create(LMem);
    PMem := LIMem.Alloc;
    if PMem <> nil then
    begin
      // 模拟使用内存
      FillChar(PMem^, 64, 0);
      LIMem.Free(PMem);
    end;
    LIMem.Reset;
  finally
    LMem.Destroy;
  end;

  // IStackPool
  LStack := TStackPool.Create(1024, LAlloc);
  try
    LIStack := TStackPoolAdapter.Create(LStack);
    P1 := LIStack.Alloc(128);
    P2 := LIStack.Alloc(256, 16);
    if (P1 <> nil) and (P2 <> nil) then
      WriteLn('Stack allocations OK');
    LIStack.Reset; // 批量释放
  finally
    LStack.Destroy;
  end;

  // ISlabPool
  LSlab := TSlabPool.Create(4096, LAlloc);
  try
    LISlab := TSlabPoolAdapter.Create(LSlab);
    PS := LISlab.Alloc(200);
    if PS <> nil then
      LISlab.Free(PS);
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

