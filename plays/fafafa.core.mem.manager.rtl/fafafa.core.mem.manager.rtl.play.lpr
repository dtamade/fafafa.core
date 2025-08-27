{$CODEPAGE UTF8}
program fafafa_core_mem_manager_rtl_play;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.manager.rtl;

var
  P, Q: Pointer;
begin
  try
    InstallRtlMemoryManager;
    try
      GetMem(P, 128);
      if P = nil then Halt(1);
      Q := ReAllocMem(P, 512);
      if Q = nil then Halt(2);
      P := Q;
      FreeMem(P);
      Writeln('RTL manager play OK');
      Flush(Output);
      Halt(0);
    finally
      UninstallRtlMemoryManager;
    end;
  except
    on E: Exception do
    begin
      Writeln('rtl play failed: ', E.ClassName, ': ', E.Message);
      Flush(Output);
      Halt(100);
    end;
  end;
end.

