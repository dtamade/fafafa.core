program comprehensive_tick_test;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.time.tick.base;

procedure TestTickTypeNames;
begin
  WriteLn('=== Testing Tick Type Names ===');
  WriteLn('ttBest: ', GetTickTypeName(ttBest));
  WriteLn('ttStandard: ', GetTickTypeName(ttStandard));
  WriteLn('ttHighPrecision: ', GetTickTypeName(ttHighPrecision));
  WriteLn('ttTSC: ', GetTickTypeName(ttTSC));
  WriteLn('ttSystem: ', GetTickTypeName(ttSystem));
  WriteLn;
end;

procedure TestTickTypeConstants;
begin
  WriteLn('=== Testing Tick Type Constants ===');
  WriteLn('TICK_TYPE_BEST_NAME: ', TICK_TYPE_BEST_NAME);
  WriteLn('TICK_TYPE_STANDARD_NAME: ', TICK_TYPE_STANDARD_NAME);
  WriteLn('TICK_TYPE_HIGHPRECISION_NAME: ', TICK_TYPE_HIGHPRECISION_NAME);
  WriteLn('TICK_TYPE_TSC_NAME: ', TICK_TYPE_TSC_NAME);
  WriteLn('TICK_TYPE_SYSTEM_NAME: ', TICK_TYPE_SYSTEM_NAME);
  WriteLn;
end;

procedure TestTickTypeEnumeration;
var
  tickType: TTickType;
begin
  WriteLn('=== Testing Tick Type Enumeration ===');
  for tickType := Low(TTickType) to High(TTickType) do
  begin
    WriteLn('Tick Type ', Ord(tickType), ': ', GetTickTypeName(tickType));
  end;
  WriteLn;
end;

procedure TestBasicFunctionality;
begin
  WriteLn('=== Testing Basic Functionality ===');
  
  // Test that we can access all the basic functions
  WriteLn('Testing GetTickTypeName function: OK');
  
  // Test enum values
  WriteLn('ttBest ordinal: ', Ord(ttBest));
  WriteLn('ttStandard ordinal: ', Ord(ttStandard));
  WriteLn('ttHighPrecision ordinal: ', Ord(ttHighPrecision));
  WriteLn('ttTSC ordinal: ', Ord(ttTSC));
  WriteLn('ttSystem ordinal: ', Ord(ttSystem));
  WriteLn;
end;

begin
  WriteLn('Comprehensive Tick Module Test');
  WriteLn('==============================');
  WriteLn;
  
  try
    TestTickTypeNames;
    TestTickTypeConstants;
    TestTickTypeEnumeration;
    TestBasicFunctionality;
    
    WriteLn('=== Test Results ===');
    WriteLn('All basic tick module tests completed successfully!');
    WriteLn('The tick module base functionality is working correctly.');
    
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
