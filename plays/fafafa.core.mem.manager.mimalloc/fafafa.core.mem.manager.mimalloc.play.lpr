{$CODEPAGE UTF8}
program fafafa_core_mem_manager_mimalloc_play;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  fafafa.core.mem.manager.mimalloc
  {$ENDIF}
  ;

var
  P, Q: Pointer;
begin
  {$IFDEF FAFAFA_CORE_MIMALLOC_ALLOCATOR}
  try
    InstallMimallocMemoryManager;
    try
      GetMem(P, 128);
      if P = nil then Halt(1);
      Q := ReAllocMem(P, 512);
      if Q = nil then Halt(2);
      P := Q;
      FreeMem(P);
      Writeln('mimalloc manager play OK');
      Flush(Output);
      Halt(0);
    finally
      UninstallMimallocMemoryManager;
    end;
  except
    on E: Exception do
    begin
      Writeln('mimalloc play failed: ', E.ClassName, ': ', E.Message);
      Flush(Output);
      Halt(100);
    end;
  end;
  {$ELSE}
  Writeln('mimalloc allocator macro disabled');
  Flush(Output);
  Halt(0);
  {$ENDIF}
end.

