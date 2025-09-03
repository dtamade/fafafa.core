program simple_tick_test;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.time.tick.base;

begin
  WriteLn('Testing basic tick module...');
  
  try
    WriteLn('Tick type name for ttBest: ', GetTickTypeName(ttBest));
    WriteLn('Tick type name for ttHighPrecision: ', GetTickTypeName(ttHighPrecision));
    WriteLn('Tick type name for ttStandard: ', GetTickTypeName(ttStandard));
    WriteLn('Tick type name for ttSystem: ', GetTickTypeName(ttSystem));
    WriteLn('Tick type name for ttTSC: ', GetTickTypeName(ttTSC));
    
    WriteLn('Basic tick module test completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
