{$CODEPAGE UTF8}
program example_mem_pool_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  //fafafa.core.mem.stack_scope_helpers,
  fafafa.core.mem.pool.slab;

procedure DemoMemPool;
var
  LPool: TMemPool;
  P1, P2: Pointer;
begin
  WriteLn('--- TMemPool Demo ---');
  LPool := TMemPool.Create(64, 4);
  try
    P1 := LPool.Alloc;
    P2 := LPool.Alloc;
    if (P1 <> nil) and (P2 <> nil) then
      WriteLn('Allocated 2 blocks of 64 bytes');
    LPool.ReleasePtr(P2);
    LPool.ReleasePtr(P1);
    LPool.Reset;
    WriteLn('TMemPool reset complete');
  finally
    // 注意：TMemPool 定义了 Free(aPtr: Pointer) 方法，避免与 TObject.Free 冲突，这里用 Destroy
    LPool.Destroy;
  end;
end;

procedure DemoStackPool;
var
  LPool: TStackPool;
  P1, P2: Pointer;
begin
  WriteLn('--- TStackPool Demo ---');
  LPool := TStackPool.Create(1024);
  try
    P1 := LPool.Alloc(128);
    P2 := LPool.Alloc(256, 16);
    if (P1 <> nil) and (P2 <> nil) then
      WriteLn('Allocated 128 and 256 bytes (aligned)');
    LPool.Reset;
    WriteLn('TStackPool reset complete');
  finally
    LPool.Destroy;
  end;
  { 可选：也可使用作用域守卫风格 }
  //var G: TStackScopeGuard;
  //G := TStackScopeGuard.Enter(LPool);
  //try
  //  P1 := LPool.Alloc(128);
  //  P2 := LPool.Alloc(256, 16);
  //finally
  //  G.Leave;
  //end;

end;

procedure DemoSlabPool;
var
  LPool: TSlabPool;
  P1, P2: Pointer;
begin
  WriteLn('--- TSlabPool Demo ---');
  LPool := TSlabPool.Create(64*1024);
  try
    P1 := LPool.Alloc(128);
    P2 := LPool.Alloc(64);
    if (P1 <> nil) and (P2 <> nil) then
      WriteLn('Allocated 128 and 64 bytes from SlabPool');
    LPool.ReleasePtr(P2);
    LPool.ReleasePtr(P1);
    WriteLn('Freed Slab allocations');
  finally
    // 与 TObject.Free 冲突，使用 Destroy
    LPool.Destroy;
  end;
end;

begin
  try
    DemoMemPool;
    DemoStackPool;
    DemoSlabPool;
    WriteLn('All pool demos completed.');
  except
    on E: Exception do begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

