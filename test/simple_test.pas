program simple_test;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.time.tick.base;

begin
  WriteLn('Testing basic tick module...');
  WriteLn('Tick type name for ttBest: ', GetTickTypeName(ttBest));
  WriteLn('Test completed successfully!');
end.
