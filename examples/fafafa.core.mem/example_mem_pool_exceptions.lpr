program example_mem_pool_exceptions;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.mem.memPool,
  fafafa.core.mem.allocator;

procedure DemoMemPoolExceptions;
var
  LPool: TMemPool;
  LPtr: Pointer;
begin
  WriteLn('--- MemPool Exceptions Demo ---');
  LPool := TMemPool.Create(32, 2);
  try
    LPool.ReleasePtr(nil);
    WriteLn('ReleasePtr(nil) is a no-op');

    LPtr := LPool.Alloc;
    LPool.ReleasePtr(LPtr);
    try
      LPool.ReleasePtr(LPtr);
    except
      on E: EMemPoolDoubleFree do
        WriteLn('Caught expected EMemPoolDoubleFree: ', E.Message);
    end;

    LPtr := GetRtlAllocator.GetMem(8);
    try
      try
        LPool.ReleasePtr(LPtr);
      except
        on E: EMemPoolInvalidPointer do
          WriteLn('Caught expected EMemPoolInvalidPointer (foreign): ', E.Message);
      end;
    finally
      GetRtlAllocator.FreeMem(LPtr);
    end;
  finally
    LPool.Destroy;
  end;
end;

begin
  try
    DemoMemPoolExceptions;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.
