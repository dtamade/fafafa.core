program Test_MonthName;

{
──────────────────────────────────────────────────────────────
   ✅ ISSUE-46: 跨 locale 月份名称解析测试
   TDD: 红 → 绿 → 重构
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, fpcunit, testregistry, consoletestrunner,
  fafafa.core.time.parse;

type
  TTestMonthNameParsing = class(TTestCase)
  published
    // ✅ 英文完整名称
    procedure Test_ParseMonth_English_January;
    procedure Test_ParseMonth_English_December;
    procedure Test_ParseMonth_English_CaseInsensitive;
    
    // ✅ 英文缩写
    procedure Test_ParseMonth_English_Jan;
    procedure Test_ParseMonth_English_Dec;
    
    // ✅ 中文月份
    procedure Test_ParseMonth_Chinese_January;
    procedure Test_ParseMonth_Chinese_December;
    procedure Test_ParseMonth_Chinese_ElevenMonth;
    
    // ✅ 日文月份
    procedure Test_ParseMonth_Japanese_January;
    procedure Test_ParseMonth_Japanese_December;
    procedure Test_ParseMonth_Japanese_October;
    
    // ✅ 德文月份
    procedure Test_ParseMonth_German_January;
    procedure Test_ParseMonth_German_March;
    procedure Test_ParseMonth_German_Abbr;
    
    // ✅ 法文月份
    procedure Test_ParseMonth_French_January;
    procedure Test_ParseMonth_French_August;
    procedure Test_ParseMonth_French_Abbr;
    
    // ✅ 边界条件
    procedure Test_ParseMonth_Empty_ReturnsFalse;
    procedure Test_ParseMonth_Invalid_ReturnsFalse;
    procedure Test_ParseMonth_WhitespaceOnly_ReturnsFalse;
    procedure Test_ParseMonth_WithTrim;
    
    // ✅ 全部12个月测试
    procedure Test_ParseMonth_AllMonths_English;
    procedure Test_ParseMonth_AllMonths_Chinese;
  end;

{ TTestMonthNameParsing }

procedure TTestMonthNameParsing.Test_ParseMonth_English_January;
var
  month: Integer;
begin
  AssertTrue('january should parse', TryParseMonthName('january', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_English_December;
var
  month: Integer;
begin
  AssertTrue('december should parse', TryParseMonthName('december', month));
  AssertEquals(12, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_English_CaseInsensitive;
var
  month: Integer;
begin
  AssertTrue('JANUARY should parse', TryParseMonthName('JANUARY', month));
  AssertEquals(1, month);
  AssertTrue('March should parse', TryParseMonthName('March', month));
  AssertEquals(3, month);
  AssertTrue('SEPTEMBER should parse', TryParseMonthName('SEPTEMBER', month));
  AssertEquals(9, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_English_Jan;
var
  month: Integer;
begin
  AssertTrue('jan should parse', TryParseMonthName('jan', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_English_Dec;
var
  month: Integer;
begin
  AssertTrue('dec should parse', TryParseMonthName('dec', month));
  AssertEquals(12, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Chinese_January;
var
  month: Integer;
begin
  AssertTrue('一月 should parse', TryParseMonthName('一月', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Chinese_December;
var
  month: Integer;
begin
  AssertTrue('十二月 should parse', TryParseMonthName('十二月', month));
  AssertEquals(12, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Chinese_ElevenMonth;
var
  month: Integer;
begin
  AssertTrue('十一月 should parse', TryParseMonthName('十一月', month));
  AssertEquals(11, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Japanese_January;
var
  month: Integer;
begin
  AssertTrue('1月 should parse', TryParseMonthName('1月', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Japanese_December;
var
  month: Integer;
begin
  AssertTrue('12月 should parse', TryParseMonthName('12月', month));
  AssertEquals(12, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Japanese_October;
var
  month: Integer;
begin
  AssertTrue('10月 should parse', TryParseMonthName('10月', month));
  AssertEquals(10, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_German_January;
var
  month: Integer;
begin
  AssertTrue('januar should parse', TryParseMonthName('januar', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_German_March;
var
  month: Integer;
begin
  AssertTrue('märz should parse', TryParseMonthName('märz', month));
  AssertEquals(3, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_German_Abbr;
var
  month: Integer;
begin
  AssertTrue('okt should parse', TryParseMonthName('okt', month));
  AssertEquals(10, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_French_January;
var
  month: Integer;
begin
  AssertTrue('janvier should parse', TryParseMonthName('janvier', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_French_August;
var
  month: Integer;
begin
  AssertTrue('août should parse', TryParseMonthName('août', month));
  AssertEquals(8, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_French_Abbr;
var
  month: Integer;
begin
  AssertTrue('sept should parse', TryParseMonthName('sept', month));
  AssertEquals(9, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Empty_ReturnsFalse;
var
  month: Integer;
begin
  AssertFalse('empty should not parse', TryParseMonthName('', month));
end;

procedure TTestMonthNameParsing.Test_ParseMonth_Invalid_ReturnsFalse;
var
  month: Integer;
begin
  AssertFalse('xyz should not parse', TryParseMonthName('xyz', month));
  AssertFalse('foo should not parse', TryParseMonthName('foo', month));
  AssertFalse('13 should not parse', TryParseMonthName('13', month));
end;

procedure TTestMonthNameParsing.Test_ParseMonth_WhitespaceOnly_ReturnsFalse;
var
  month: Integer;
begin
  AssertFalse('whitespace should not parse', TryParseMonthName('   ', month));
end;

procedure TTestMonthNameParsing.Test_ParseMonth_WithTrim;
var
  month: Integer;
begin
  AssertTrue(' january  should parse with trim', TryParseMonthName(' january ', month));
  AssertEquals(1, month);
end;

procedure TTestMonthNameParsing.Test_ParseMonth_AllMonths_English;
const
  MONTHS: array[1..12] of string = (
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'
  );
var
  i, month: Integer;
begin
  for i := 1 to 12 do
  begin
    AssertTrue(Format('%s should parse', [MONTHS[i]]), TryParseMonthName(MONTHS[i], month));
    AssertEquals(Format('Month %d', [i]), i, month);
  end;
end;

procedure TTestMonthNameParsing.Test_ParseMonth_AllMonths_Chinese;
const
  MONTHS: array[1..12] of string = (
    '一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'
  );
var
  i, month: Integer;
begin
  for i := 1 to 12 do
  begin
    AssertTrue(Format('%s should parse', [MONTHS[i]]), TryParseMonthName(MONTHS[i], month));
    AssertEquals(Format('Month %d', [i]), i, month);
  end;
end;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  try
    RegisterTest(TTestMonthNameParsing);
    Application.Initialize;
    Application.Title := 'ISSUE-46: Cross-Locale Month Name Parsing';
    Application.Run;
  finally
    Application.Free;
  end;
end.
