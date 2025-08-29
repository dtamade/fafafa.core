program test_console_debug;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  SysUtils;

begin
  WriteLn('=== Console Debug Test ===');
  WriteLn('This is a test message');
  WriteLn('Current time: ', DateTimeToStr(Now));
  WriteLn('Program directory: ', ExtractFilePath(ParamStr(0)));
  
  Write('Testing Write without newline... ');
  WriteLn('Done!');
  
  WriteLn('Testing exception handling...');
  try
    WriteLn('Before potential error');
    // Test normal operation
    WriteLn('No error occurred');
  except
    on E: Exception do
      WriteLn('Exception caught: ', E.Message);
  end;
  
  WriteLn('=== Test Complete ===');
  WriteLn('If you can see this, console output is working');
  
  // Force flush
  Flush(Output);
  
  WriteLn('Press Enter to continue...');
  ReadLn;
end.
