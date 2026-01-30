unit fafafa.core.time.dst.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.tz,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset,
  fafafa.core.time.instant;

type
  TTestCase_DST = class(TTestCase)
  published
    // === 美国东部时区 DST ===
    procedure Test_NewYork_Winter_EST;
    procedure Test_NewYork_Summer_EDT;
    procedure Test_NewYork_SpringForward;
    procedure Test_NewYork_FallBack;
    
    // === 美国太平洋时区 DST ===
    procedure Test_LosAngeles_Winter_PST;
    procedure Test_LosAngeles_Summer_PDT;
    
    // === 欧洲时区 DST ===
    procedure Test_London_Winter_GMT;
    procedure Test_London_Summer_BST;
    procedure Test_Paris_Winter_CET;
    procedure Test_Paris_Summer_CEST;
    
    // === 无 DST 时区 ===
    procedure Test_Shanghai_NoDST;
    procedure Test_Tokyo_NoDST;
    
    // === 南半球 DST（反向）===
    procedure Test_Sydney_Summer;
    procedure Test_Sydney_Winter;
  end;

implementation

// === 美国东部时区 DST ===

procedure TTestCase_DST.Test_NewYork_Winter_EST;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-01-15 12:00:00 UTC - 冬季，应该是 EST (UTC-5)
  TTimeZone.TryFromId('America/New_York', Tz);
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-5 * 3600, Offset.TotalSeconds, 'Winter should be EST (UTC-5)');
end;

procedure TTestCase_DST.Test_NewYork_Summer_EDT;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-07-15 12:00:00 UTC - 夏季，应该是 EDT (UTC-4)
  TTimeZone.TryFromId('America/New_York', Tz);
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-4 * 3600, Offset.TotalSeconds, 'Summer should be EDT (UTC-4)');
end;

procedure TTestCase_DST.Test_NewYork_SpringForward;
var 
  Tz: TTimeZone;
  Inst1, Inst2: TInstant;
  Off1, Off2: TUtcOffset;
begin
  // 2024 DST 开始：3月10日 02:00 EST -> 03:00 EDT
  // UTC 时间：2024-03-10 07:00:00 UTC
  TTimeZone.TryFromId('America/New_York', Tz);
  
  // 转换前（06:59 UTC = 01:59 EST）
  Inst1 := TInstant.FromUnixSec(1710054000 - 60);  // 2024-03-10 06:59 UTC
  Off1 := Tz.GetOffsetAt(Inst1);
  
  // 转换后（07:01 UTC = 03:01 EDT）
  Inst2 := TInstant.FromUnixSec(1710054000 + 60);  // 2024-03-10 07:01 UTC
  Off2 := Tz.GetOffsetAt(Inst2);
  
  CheckEquals(-5 * 3600, Off1.TotalSeconds, 'Before spring forward: EST');
  CheckEquals(-4 * 3600, Off2.TotalSeconds, 'After spring forward: EDT');
end;

procedure TTestCase_DST.Test_NewYork_FallBack;
var 
  Tz: TTimeZone;
  Inst1, Inst2: TInstant;
  Off1, Off2: TUtcOffset;
begin
  // 2024 DST 结束：11月3日 02:00 EDT -> 01:00 EST
  // UTC 时间：2024-11-03 06:00:00 UTC
  TTimeZone.TryFromId('America/New_York', Tz);
  
  // 转换前（05:59 UTC = 01:59 EDT）
  Inst1 := TInstant.FromUnixSec(1730613600 - 60);  // 2024-11-03 05:59 UTC
  Off1 := Tz.GetOffsetAt(Inst1);
  
  // 转换后（06:01 UTC = 01:01 EST）
  Inst2 := TInstant.FromUnixSec(1730613600 + 60);  // 2024-11-03 06:01 UTC
  Off2 := Tz.GetOffsetAt(Inst2);
  
  CheckEquals(-4 * 3600, Off1.TotalSeconds, 'Before fall back: EDT');
  CheckEquals(-5 * 3600, Off2.TotalSeconds, 'After fall back: EST');
end;

// === 美国太平洋时区 DST ===

procedure TTestCase_DST.Test_LosAngeles_Winter_PST;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-01-15 12:00:00 UTC - 冬季，应该是 PST (UTC-8)
  TTimeZone.TryFromId('America/Los_Angeles', Tz);
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-8 * 3600, Offset.TotalSeconds, 'Winter should be PST (UTC-8)');
end;

procedure TTestCase_DST.Test_LosAngeles_Summer_PDT;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-07-15 12:00:00 UTC - 夏季，应该是 PDT (UTC-7)
  TTimeZone.TryFromId('America/Los_Angeles', Tz);
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-7 * 3600, Offset.TotalSeconds, 'Summer should be PDT (UTC-7)');
end;

// === 欧洲时区 DST ===

procedure TTestCase_DST.Test_London_Winter_GMT;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-01-15 12:00:00 UTC - 冬季，应该是 GMT (UTC+0)
  TTimeZone.TryFromId('Europe/London', Tz);
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(0, Offset.TotalSeconds, 'Winter should be GMT (UTC+0)');
end;

procedure TTestCase_DST.Test_London_Summer_BST;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-07-15 12:00:00 UTC - 夏季，应该是 BST (UTC+1)
  TTimeZone.TryFromId('Europe/London', Tz);
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(1 * 3600, Offset.TotalSeconds, 'Summer should be BST (UTC+1)');
end;

procedure TTestCase_DST.Test_Paris_Winter_CET;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-01-15 12:00:00 UTC - 冬季，应该是 CET (UTC+1)
  TTimeZone.TryFromId('Europe/Paris', Tz);
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(1 * 3600, Offset.TotalSeconds, 'Winter should be CET (UTC+1)');
end;

procedure TTestCase_DST.Test_Paris_Summer_CEST;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-07-15 12:00:00 UTC - 夏季，应该是 CEST (UTC+2)
  TTimeZone.TryFromId('Europe/Paris', Tz);
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(2 * 3600, Offset.TotalSeconds, 'Summer should be CEST (UTC+2)');
end;

// === 无 DST 时区 ===

procedure TTestCase_DST.Test_Shanghai_NoDST;
var 
  Tz: TTimeZone;
  InstWinter, InstSummer: TInstant;
  OffWinter, OffSummer: TUtcOffset;
begin
  // 中国没有 DST，全年 UTC+8
  TTimeZone.TryFromId('Asia/Shanghai', Tz);
  
  InstWinter := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  InstSummer := TInstant.FromUnixSec(1721044800);  // 2024-07-15
  
  OffWinter := Tz.GetOffsetAt(InstWinter);
  OffSummer := Tz.GetOffsetAt(InstSummer);
  
  CheckEquals(8 * 3600, OffWinter.TotalSeconds, 'Winter should be UTC+8');
  CheckEquals(8 * 3600, OffSummer.TotalSeconds, 'Summer should be UTC+8');
end;

procedure TTestCase_DST.Test_Tokyo_NoDST;
var 
  Tz: TTimeZone;
  InstWinter, InstSummer: TInstant;
  OffWinter, OffSummer: TUtcOffset;
begin
  // 日本没有 DST，全年 UTC+9
  TTimeZone.TryFromId('Asia/Tokyo', Tz);
  
  InstWinter := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  InstSummer := TInstant.FromUnixSec(1721044800);  // 2024-07-15
  
  OffWinter := Tz.GetOffsetAt(InstWinter);
  OffSummer := Tz.GetOffsetAt(InstSummer);
  
  CheckEquals(9 * 3600, OffWinter.TotalSeconds, 'Winter should be UTC+9');
  CheckEquals(9 * 3600, OffSummer.TotalSeconds, 'Summer should be UTC+9');
end;

// === 南半球 DST（反向）===

procedure TTestCase_DST.Test_Sydney_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-01-15 - 南半球夏季，应该是 AEDT (UTC+11)
  TTimeZone.TryFromId('Australia/Sydney', Tz);
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(11 * 3600, Offset.TotalSeconds, 'Jan should be AEDT (UTC+11)');
end;

procedure TTestCase_DST.Test_Sydney_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 2024-07-15 - 南半球冬季，应该是 AEST (UTC+10)
  TTimeZone.TryFromId('Australia/Sydney', Tz);
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 12:00:00 UTC
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(10 * 3600, Offset.TotalSeconds, 'Jul should be AEST (UTC+10)');
end;

initialization
  RegisterTest(TTestCase_DST);
end.
