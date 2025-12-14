unit fafafa.core.time.dst.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.tz,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.offset;

type
  TTestCase_DST = class(TTestCase)
  published
    // TTimeZone DST 检测
    procedure Test_NewYork_IsDST_Summer;
    procedure Test_NewYork_IsDST_Winter;
    procedure Test_London_IsDST_Summer;
    procedure Test_London_IsDST_Winter;
    procedure Test_Shanghai_NoDST;
    
    // DST 偏移量
    procedure Test_NewYork_Offset_Summer;
    procedure Test_NewYork_Offset_Winter;
    procedure Test_London_Offset_Summer;
    procedure Test_London_Offset_Winter;
    
    // DST 边界转换
    procedure Test_NewYork_SpringForward;
    procedure Test_NewYork_FallBack;
    procedure Test_London_SpringForward;
    procedure Test_London_FallBack;
    
    // UTC 转换
    procedure Test_NewYork_ToUTC_Summer;
    procedure Test_NewYork_ToUTC_Winter;
    procedure Test_London_ToUTC_Summer;
  end;

implementation

{ TTestCase_DST }

procedure TTestCase_DST.Test_NewYork_IsDST_Summer;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024-07-15 12:00:00 - 夏季，应该是 DST
  LDt := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  AssertTrue('Summer should be DST', LTz.IsDST(LDt));
end;

procedure TTestCase_DST.Test_NewYork_IsDST_Winter;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024-01-15 12:00:00 - 冬季，不应该是 DST
  LDt := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  AssertFalse('Winter should not be DST', LTz.IsDST(LDt));
end;

procedure TTestCase_DST.Test_London_IsDST_Summer;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 2024-07-15 12:00:00 - 夏季，应该是 DST (BST)
  LDt := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  AssertTrue('Summer should be DST', LTz.IsDST(LDt));
end;

procedure TTestCase_DST.Test_London_IsDST_Winter;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 2024-01-15 12:00:00 - 冬季，不应该是 DST
  LDt := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  AssertFalse('Winter should not be DST', LTz.IsDST(LDt));
end;

procedure TTestCase_DST.Test_Shanghai_NoDST;
var
  LTz: TTimeZone;
  LDtSummer, LDtWinter: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('Asia/Shanghai', LTz) then
    Fail('Failed to load Asia/Shanghai timezone');
  
  // 中国不使用 DST
  LDtSummer := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  LDtWinter := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  
  AssertFalse('Shanghai summer should not be DST', LTz.IsDST(LDtSummer));
  AssertFalse('Shanghai winter should not be DST', LTz.IsDST(LDtWinter));
end;

procedure TTestCase_DST.Test_NewYork_Offset_Summer;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 夏季 EDT = UTC-4
  LDt := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  LOffset := LTz.GetOffsetAt(LDt);
  AssertEquals(-4 * 3600, LOffset.TotalSeconds);
end;

procedure TTestCase_DST.Test_NewYork_Offset_Winter;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 冬季 EST = UTC-5
  LDt := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  LOffset := LTz.GetOffsetAt(LDt);
  AssertEquals(-5 * 3600, LOffset.TotalSeconds);
end;

procedure TTestCase_DST.Test_London_Offset_Summer;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 夏季 BST = UTC+1
  LDt := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  LOffset := LTz.GetOffsetAt(LDt);
  AssertEquals(1 * 3600, LOffset.TotalSeconds);
end;

procedure TTestCase_DST.Test_London_Offset_Winter;
var
  LTz: TTimeZone;
  LDt: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 冬季 GMT = UTC+0
  LDt := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  LOffset := LTz.GetOffsetAt(LDt);
  AssertEquals(0, LOffset.TotalSeconds);
end;

// DST 边界测试

procedure TTestCase_DST.Test_NewYork_SpringForward;
var
  LTz: TTimeZone;
  LDtBefore, LDtAfter: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024 年美国 DST 开始：3月10日 02:00 AM -> 03:00 AM
  // 01:59 应该是 EST (UTC-5)
  LDtBefore := TNaiveDateTime.Create(2024, 3, 10, 1, 59, 0);
  AssertEquals(-5 * 3600, LTz.GetOffsetAt(LDtBefore).TotalSeconds);
  
  // 03:00 应该是 EDT (UTC-4)
  LDtAfter := TNaiveDateTime.Create(2024, 3, 10, 3, 0, 0);
  AssertEquals(-4 * 3600, LTz.GetOffsetAt(LDtAfter).TotalSeconds);
end;

procedure TTestCase_DST.Test_NewYork_FallBack;
var
  LTz: TTimeZone;
  LDtBefore, LDtAfter: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024 年美国 DST 结束：11月3日 02:00 AM -> 01:00 AM
  // 00:59 应该是 EDT (UTC-4)
  LDtBefore := TNaiveDateTime.Create(2024, 11, 3, 0, 59, 0);
  AssertEquals(-4 * 3600, LTz.GetOffsetAt(LDtBefore).TotalSeconds);
  
  // 03:00 应该是 EST (UTC-5)
  LDtAfter := TNaiveDateTime.Create(2024, 11, 3, 3, 0, 0);
  AssertEquals(-5 * 3600, LTz.GetOffsetAt(LDtAfter).TotalSeconds);
end;

procedure TTestCase_DST.Test_London_SpringForward;
var
  LTz: TTimeZone;
  LDtBefore, LDtAfter: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 2024 年英国 DST 开始：3月31日 01:00 AM -> 02:00 AM
  // 00:59 应该是 GMT (UTC+0)
  LDtBefore := TNaiveDateTime.Create(2024, 3, 31, 0, 59, 0);
  AssertEquals(0, LTz.GetOffsetAt(LDtBefore).TotalSeconds);
  
  // 02:00 应该是 BST (UTC+1)
  LDtAfter := TNaiveDateTime.Create(2024, 3, 31, 2, 0, 0);
  AssertEquals(1 * 3600, LTz.GetOffsetAt(LDtAfter).TotalSeconds);
end;

procedure TTestCase_DST.Test_London_FallBack;
var
  LTz: TTimeZone;
  LDtBefore, LDtAfter: TNaiveDateTime;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 2024 年英国 DST 结束：10月27日 02:00 AM -> 01:00 AM
  // 00:59 应该是 BST (UTC+1)
  LDtBefore := TNaiveDateTime.Create(2024, 10, 27, 0, 59, 0);
  AssertEquals(1 * 3600, LTz.GetOffsetAt(LDtBefore).TotalSeconds);
  
  // 02:00 应该是 GMT (UTC+0)
  LDtAfter := TNaiveDateTime.Create(2024, 10, 27, 2, 0, 0);
  AssertEquals(0, LTz.GetOffsetAt(LDtAfter).TotalSeconds);
end;

// UTC 转换测试

procedure TTestCase_DST.Test_NewYork_ToUTC_Summer;
var
  LTz: TTimeZone;
  LLocal: TNaiveDateTime;
  LZdt: TZonedDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024-07-15 12:00 EDT -> 2024-07-15 16:00 UTC
  LLocal := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  LZdt := TZonedDateTime.FromTimeZone(LLocal, LTz);
  
  AssertEquals(16, LZdt.ToUTC.GetHour);
end;

procedure TTestCase_DST.Test_NewYork_ToUTC_Winter;
var
  LTz: TTimeZone;
  LLocal: TNaiveDateTime;
  LZdt: TZonedDateTime;
begin
  if not TTimeZone.TryFromId('America/New_York', LTz) then
    Fail('Failed to load America/New_York timezone');
  
  // 2024-01-15 12:00 EST -> 2024-01-15 17:00 UTC
  LLocal := TNaiveDateTime.Create(2024, 1, 15, 12, 0, 0);
  LZdt := TZonedDateTime.FromTimeZone(LLocal, LTz);
  
  AssertEquals(17, LZdt.ToUTC.GetHour);
end;

procedure TTestCase_DST.Test_London_ToUTC_Summer;
var
  LTz: TTimeZone;
  LLocal: TNaiveDateTime;
  LZdt: TZonedDateTime;
begin
  if not TTimeZone.TryFromId('Europe/London', LTz) then
    Fail('Failed to load Europe/London timezone');
  
  // 2024-07-15 12:00 BST -> 2024-07-15 11:00 UTC
  LLocal := TNaiveDateTime.Create(2024, 7, 15, 12, 0, 0);
  LZdt := TZonedDateTime.FromTimeZone(LLocal, LTz);
  
  AssertEquals(11, LZdt.ToUTC.GetHour);
end;

initialization
  RegisterTest(TTestCase_DST);

end.
