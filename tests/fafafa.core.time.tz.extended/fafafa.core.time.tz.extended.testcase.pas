unit fafafa.core.time.tz.extended.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.tz,
  fafafa.core.time.offset,
  fafafa.core.time.instant;

type
  TTestCase_ExtendedTimeZones = class(TTestCase)
  published
    // === 南亚时区（非整小时偏移）===
    procedure Test_Kolkata_UTC530;
    procedure Test_Kathmandu_UTC545;
    
    // === 中东时区 ===
    procedure Test_Dubai_UTC4;
    procedure Test_Tehran_Winter;
    procedure Test_Tehran_Summer;
    
    // === 南美时区 ===
    procedure Test_SaoPaulo_Standard;
    procedure Test_BuenosAires_NoDS;
    
    // === 非洲时区 ===
    procedure Test_Cairo_Winter;
    procedure Test_Cairo_Summer;
    procedure Test_Johannesburg_NoDST;
    
    // === 更多欧洲时区 ===
    procedure Test_Rome_Winter;
    procedure Test_Rome_Summer;
    procedure Test_Madrid_Winter;
    procedure Test_Madrid_Summer;
    
    // === 加拿大时区 ===
    procedure Test_Toronto_Winter;
    procedure Test_Toronto_Summer;
    procedure Test_Vancouver_Winter;
    procedure Test_Vancouver_Summer;
  end;

implementation

// === 南亚时区（非整小时偏移）===

procedure TTestCase_ExtendedTimeZones.Test_Kolkata_UTC530;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 印度全年 UTC+5:30，无 DST
  CheckTrue(TTimeZone.TryFromId('Asia/Kolkata', Tz), 'Should support Asia/Kolkata');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(5 * 3600 + 30 * 60, Offset.TotalSeconds, 'Kolkata should be UTC+5:30');
end;

procedure TTestCase_ExtendedTimeZones.Test_Kathmandu_UTC545;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 尼泊尔全年 UTC+5:45，无 DST
  CheckTrue(TTimeZone.TryFromId('Asia/Kathmandu', Tz), 'Should support Asia/Kathmandu');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(5 * 3600 + 45 * 60, Offset.TotalSeconds, 'Kathmandu should be UTC+5:45');
end;

// === 中东时区 ===

procedure TTestCase_ExtendedTimeZones.Test_Dubai_UTC4;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 阿联酋全年 UTC+4，无 DST
  CheckTrue(TTimeZone.TryFromId('Asia/Dubai', Tz), 'Should support Asia/Dubai');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(4 * 3600, Offset.TotalSeconds, 'Dubai should be UTC+4');
end;

procedure TTestCase_ExtendedTimeZones.Test_Tehran_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 伊朗冬季 IRST UTC+3:30
  CheckTrue(TTimeZone.TryFromId('Asia/Tehran', Tz), 'Should support Asia/Tehran');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(3 * 3600 + 30 * 60, Offset.TotalSeconds, 'Tehran winter should be UTC+3:30');
end;

procedure TTestCase_ExtendedTimeZones.Test_Tehran_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 伊朗夏季 IRDT UTC+4:30
  CheckTrue(TTimeZone.TryFromId('Asia/Tehran', Tz), 'Should support Asia/Tehran');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(4 * 3600 + 30 * 60, Offset.TotalSeconds, 'Tehran summer should be UTC+4:30');
end;

// === 南美时区 ===

procedure TTestCase_ExtendedTimeZones.Test_SaoPaulo_Standard;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 巴西圣保罗 UTC-3（2019年后取消DST）
  CheckTrue(TTimeZone.TryFromId('America/Sao_Paulo', Tz), 'Should support America/Sao_Paulo');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-3 * 3600, Offset.TotalSeconds, 'Sao Paulo should be UTC-3');
end;

procedure TTestCase_ExtendedTimeZones.Test_BuenosAires_NoDS;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 阿根廷全年 UTC-3，无 DST
  CheckTrue(TTimeZone.TryFromId('America/Buenos_Aires', Tz), 'Should support America/Buenos_Aires');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-3 * 3600, Offset.TotalSeconds, 'Buenos Aires should be UTC-3');
end;

// === 非洲时区 ===

procedure TTestCase_ExtendedTimeZones.Test_Cairo_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 埃及冬季 EET UTC+2
  CheckTrue(TTimeZone.TryFromId('Africa/Cairo', Tz), 'Should support Africa/Cairo');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(2 * 3600, Offset.TotalSeconds, 'Cairo winter should be UTC+2');
end;

procedure TTestCase_ExtendedTimeZones.Test_Cairo_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 埃及夏季 EEST UTC+3（2023年恢复 DST）
  CheckTrue(TTimeZone.TryFromId('Africa/Cairo', Tz), 'Should support Africa/Cairo');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(3 * 3600, Offset.TotalSeconds, 'Cairo summer should be UTC+3');
end;

procedure TTestCase_ExtendedTimeZones.Test_Johannesburg_NoDST;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 南非全年 SAST UTC+2，无 DST
  CheckTrue(TTimeZone.TryFromId('Africa/Johannesburg', Tz), 'Should support Africa/Johannesburg');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(2 * 3600, Offset.TotalSeconds, 'Johannesburg should be UTC+2');
end;

// === 更多欧洲时区 ===

procedure TTestCase_ExtendedTimeZones.Test_Rome_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 意大利冬季 CET UTC+1
  CheckTrue(TTimeZone.TryFromId('Europe/Rome', Tz), 'Should support Europe/Rome');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(1 * 3600, Offset.TotalSeconds, 'Rome winter should be UTC+1');
end;

procedure TTestCase_ExtendedTimeZones.Test_Rome_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 意大利夏季 CEST UTC+2
  CheckTrue(TTimeZone.TryFromId('Europe/Rome', Tz), 'Should support Europe/Rome');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(2 * 3600, Offset.TotalSeconds, 'Rome summer should be UTC+2');
end;

procedure TTestCase_ExtendedTimeZones.Test_Madrid_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 西班牙冬季 CET UTC+1
  CheckTrue(TTimeZone.TryFromId('Europe/Madrid', Tz), 'Should support Europe/Madrid');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(1 * 3600, Offset.TotalSeconds, 'Madrid winter should be UTC+1');
end;

procedure TTestCase_ExtendedTimeZones.Test_Madrid_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 西班牙夏季 CEST UTC+2
  CheckTrue(TTimeZone.TryFromId('Europe/Madrid', Tz), 'Should support Europe/Madrid');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(2 * 3600, Offset.TotalSeconds, 'Madrid summer should be UTC+2');
end;

// === 加拿大时区 ===

procedure TTestCase_ExtendedTimeZones.Test_Toronto_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 多伦多冬季 EST UTC-5
  CheckTrue(TTimeZone.TryFromId('America/Toronto', Tz), 'Should support America/Toronto');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-5 * 3600, Offset.TotalSeconds, 'Toronto winter should be UTC-5');
end;

procedure TTestCase_ExtendedTimeZones.Test_Toronto_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 多伦多夏季 EDT UTC-4
  CheckTrue(TTimeZone.TryFromId('America/Toronto', Tz), 'Should support America/Toronto');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-4 * 3600, Offset.TotalSeconds, 'Toronto summer should be UTC-4');
end;

procedure TTestCase_ExtendedTimeZones.Test_Vancouver_Winter;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 温哥华冬季 PST UTC-8
  CheckTrue(TTimeZone.TryFromId('America/Vancouver', Tz), 'Should support America/Vancouver');
  Inst := TInstant.FromUnixSec(1705320000);  // 2024-01-15 (冬季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-8 * 3600, Offset.TotalSeconds, 'Vancouver winter should be UTC-8');
end;

procedure TTestCase_ExtendedTimeZones.Test_Vancouver_Summer;
var 
  Tz: TTimeZone;
  Inst: TInstant;
  Offset: TUtcOffset;
begin
  // 温哥华夏季 PDT UTC-7
  CheckTrue(TTimeZone.TryFromId('America/Vancouver', Tz), 'Should support America/Vancouver');
  Inst := TInstant.FromUnixSec(1721044800);  // 2024-07-15 (夏季)
  Offset := Tz.GetOffsetAt(Inst);
  CheckEquals(-7 * 3600, Offset.TotalSeconds, 'Vancouver summer should be UTC-7');
end;

initialization
  RegisterTest(TTestCase_ExtendedTimeZones);
end.
