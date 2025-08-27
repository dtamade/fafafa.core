{$CODEPAGE UTF8}
program example_enhanced_stack_pool;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.enhancedStackPool;

var
  LPolicy: TStackPoolPolicy;
  LPool: TEnhancedStackPool;
  LPtr: Pointer;
begin
  LPolicy := CreateDefaultStackPolicy;
  LPolicy.EnableStatistics := True;
  LPool := TEnhancedStackPool.Create(4096, LPolicy);
  try
    Writeln('Enhanced Stack Pool Demo');
    LPtr := LPool.Alloc(128);
    Writeln(Format('Alloc 128 bytes: %p', [LPtr]));
    LPool.Reset;
    Writeln('Reset done. UsedSize=', LPool.UsedSize);
  finally
    LPool.Free;
  end;
end.

