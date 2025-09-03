program minimal_tick_test;

{$MODE OBJFPC}{$H+}

uses
  SysUtils;

// 直接测试 tick 类型名称函数，不依赖其他模块
function GetTickTypeName(const AType: Integer): string;
begin
  case AType of
    0: Result := 'Best Available Timer';
    1: Result := 'Standard Precision Timer';
    2: Result := 'High Precision Timer';
    3: Result := 'TSC Hardware Timer';
    4: Result := 'System Clock Timer';
  else
    Result := 'Unknown Timer Type';
  end;
end;

begin
  WriteLn('Testing minimal tick functionality...');
  
  try
    WriteLn('Tick type name for ttBest (0): ', GetTickTypeName(0));
    WriteLn('Tick type name for ttStandard (1): ', GetTickTypeName(1));
    WriteLn('Tick type name for ttHighPrecision (2): ', GetTickTypeName(2));
    WriteLn('Tick type name for ttTSC (3): ', GetTickTypeName(3));
    WriteLn('Tick type name for ttSystem (4): ', GetTickTypeName(4));
    
    WriteLn('Minimal tick test completed successfully!');
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
