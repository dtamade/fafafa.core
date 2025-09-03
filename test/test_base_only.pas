program test_base_only;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.time.tick.base;

begin
  WriteLn('Testing base tick module...');
  WriteLn('Tick type name for ttBest: ', GetTickTypeName(ttBest));
  WriteLn('Test completed successfully!');
end.
