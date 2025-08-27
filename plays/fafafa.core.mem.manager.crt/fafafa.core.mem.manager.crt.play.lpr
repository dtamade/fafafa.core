{$CODEPAGE UTF8}
program fafafa_core_mem_manager_crt_play;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  fafafa.core.mem.manager.crt
  {$ENDIF}
  ;

var
  P, Q: Pointer;
begin
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  try
    InstallCrtMemoryManager;
    try
      GetMem(P, 128);
      if P = nil then Halt(1);
      Q := ReAllocMem(P, 512);
      if Q = nil then Halt(2);
      P := Q;
      FreeMem(P);
      Writeln('CRT manager play OK');
      Flush(Output);
      Halt(0);
    finally
      UninstallCrtMemoryManager;
    end;
  except
    on E: Exception do
    begin
      Writeln('crt play failed: ', E.ClassName, ': ', E.Message);
      Flush(Output);
      Halt(100);
    end;
  end;
  {$ELSE}
  Writeln('CRT allocator macro disabled');
  Flush(Output);
  Halt(0);
  {$ENDIF}
end.

