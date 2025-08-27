{$CODEPAGE UTF8}
program example_mem_pool_exceptions;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.allocator;

procedure DemoMemPoolExceptions;
var
  Pool: TMemPool;
  P: Pointer;
begin
  WriteLn('--- MemPool Exceptions Demo ---');
  Pool := TMemPool.Create(32, 2);
  try
    // nil 指针释放
    try
      Pool.Free(nil);
    except on E: EMemPoolInvalidPointer do
      WriteLn('Caught expected EMemPoolInvalidPointer: ', E.Message);
    end;

    // Double free
    P := Pool.Alloc;
    Pool.Free(P);
    try
      Pool.Free(P);
    except on E: EMemPoolDoubleFree do
      WriteLn('Caught expected EMemPoolDoubleFree: ', E.Message);
    end;

    // 非池指针
    P := GetRtlAllocator.GetMem(8);
    try
      try
        Pool.Free(P);
      except on E: EMemPoolInvalidPointer do
        WriteLn('Caught expected EMemPoolInvalidPointer (foreign): ', E.Message);
      end;
    finally
      GetRtlAllocator.FreeMem(P);
    end;
  finally
    Pool.Destroy;
  end;
end;

begin
  try
    DemoMemPoolExceptions;
  except
    on E: Exception do begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

