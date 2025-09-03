program manual_enhanced_test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils;

type
  TTickType = (ttBest, ttStandard, ttHighPrecision, ttTSC, ttSystem);

const
  TICK_TYPE_BEST_NAME = 'Best Available Timer';
  TICK_TYPE_STANDARD_NAME = 'Standard Precision Timer';
  TICK_TYPE_HIGHPRECISION_NAME = 'High Precision Timer';
  TICK_TYPE_TSC_NAME = 'TSC Hardware Timer';
  TICK_TYPE_SYSTEM_NAME = 'System Clock Timer';

function GetTickTypeName(const AType: TTickType): string;
begin
  case AType of
    ttBest: Result := TICK_TYPE_BEST_NAME;
    ttStandard: Result := TICK_TYPE_STANDARD_NAME;
    ttHighPrecision: Result := TICK_TYPE_HIGHPRECISION_NAME;
    ttTSC: Result := TICK_TYPE_TSC_NAME;
    ttSystem: Result := TICK_TYPE_SYSTEM_NAME;
  else
    Result := 'Unknown Tick Type';
  end;
end;

var
  TestCount, PassCount, FailCount: Integer;

procedure Assert(condition: Boolean; const msg: string);
begin
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    WriteLn('PASS: ', msg);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('FAIL: ', msg);
  end;
end;

procedure RunEnhancedTests;
var
  tickType: TTickType;
  name: string;
  i: Integer;
  count: Integer;
begin
  WriteLn('=== Enhanced Tick Test Suite ===');
  WriteLn('Running enhanced tests...');
  WriteLn;
  
  // 基础枚举测试
  WriteLn('--- Basic Enum Tests ---');
  Assert(Ord(ttBest) = 0, 'ttBest ordinal should be 0');
  Assert(Ord(ttStandard) = 1, 'ttStandard ordinal should be 1');
  Assert(Ord(ttHighPrecision) = 2, 'ttHighPrecision ordinal should be 2');
  Assert(Ord(ttTSC) = 3, 'ttTSC ordinal should be 3');
  Assert(Ord(ttSystem) = 4, 'ttSystem ordinal should be 4');
  
  // 范围测试
  WriteLn('--- Range Tests ---');
  Assert(Ord(Low(TTickType)) = Ord(ttBest), 'Low(TTickType) should be ttBest');
  Assert(Ord(High(TTickType)) = Ord(ttSystem), 'High(TTickType) should be ttSystem');
  
  // 计数测试
  WriteLn('--- Count Tests ---');
  count := 0;
  for tickType := Low(TTickType) to High(TTickType) do
    Inc(count);
  Assert(count = 5, 'Should have exactly 5 enum values');
  
  // 名称映射测试
  WriteLn('--- Name Mapping Tests ---');
  Assert(GetTickTypeName(ttBest) = 'Best Available Timer', 'ttBest name should be correct');
  Assert(GetTickTypeName(ttStandard) = 'Standard Precision Timer', 'ttStandard name should be correct');
  Assert(GetTickTypeName(ttHighPrecision) = 'High Precision Timer', 'ttHighPrecision name should be correct');
  Assert(GetTickTypeName(ttTSC) = 'TSC Hardware Timer', 'ttTSC name should be correct');
  Assert(GetTickTypeName(ttSystem) = 'System Clock Timer', 'ttSystem name should be correct');
  
  // 所有名称测试
  WriteLn('--- All Names Tests ---');
  for tickType := Low(TTickType) to High(TTickType) do
  begin
    name := GetTickTypeName(tickType);
    Assert(Length(name) > 0, 'Name should not be empty for ' + IntToStr(Ord(tickType)));
    Assert(Pos('Unknown', name) = 0, 'Valid type should not return Unknown');
  end;
  
  // 无效值测试
  WriteLn('--- Invalid Value Tests ---');
  {$PUSH}
  {$R-}
  name := GetTickTypeName(TTickType(99));
  Assert(Pos('Unknown', name) > 0, 'Invalid type should return Unknown');
  
  name := GetTickTypeName(TTickType(-1));
  Assert(Pos('Unknown', name) > 0, 'Negative type should return Unknown');
  {$POP}
  
  // 常量测试
  WriteLn('--- Constants Tests ---');
  Assert(Length(TICK_TYPE_BEST_NAME) > 0, 'BEST_NAME should be defined');
  Assert(Length(TICK_TYPE_STANDARD_NAME) > 0, 'STANDARD_NAME should be defined');
  Assert(TICK_TYPE_BEST_NAME <> TICK_TYPE_STANDARD_NAME, 'Names should be unique');
  
  // 性能测试
  WriteLn('--- Performance Tests ---');
  for i := 1 to 10000 do
    name := GetTickTypeName(ttBest);
  Assert(name = 'Best Available Timer', '10000 calls should maintain correctness');
  
  WriteLn;
  WriteLn('=== Test Results ===');
  WriteLn('Total tests: ', TestCount);
  WriteLn('Passed: ', PassCount);
  WriteLn('Failed: ', FailCount);
  
  if FailCount = 0 then
    WriteLn('*** ALL TESTS PASSED! ***')
  else
    WriteLn('*** SOME TESTS FAILED! ***');
end;

begin
  TestCount := 0;
  PassCount := 0;
  FailCount := 0;
  
  RunEnhancedTests;
  
  if FailCount = 0 then
    ExitCode := 0
  else
    ExitCode := 1;
end.
