unit Test_fafafa_core_time_timezone_mode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.parse;

type
  {**
   * TTestCase_TimeZoneMode - 测试时区模式
   * 
   * 验证 ISSUE-37 修复：时区处理冲突
   *}
  TTestCase_TimeZoneMode = class(TTestCase)
  published
    procedure Test_Default_UsesLocalTimeZone;
    procedure Test_UTC_UsesUTCTimeZone;
    procedure Test_WithTimeZone_UsesSpecifiedTimeZone;
    procedure Test_StrictTimeZone_RequiresTimeZoneInfo;
    
    procedure Test_NoConflict_TimeZoneModeAndSpecified;
    procedure Test_TimeZoneModeEnum_HasFourValues;
    procedure Test_ParseOptions_UTC_Factory;
    procedure Test_ParseOptions_WithTimeZone_Factory;
    procedure Test_ParseOptions_StrictTimeZone_Factory;
  end;

implementation

{ TTestCase_TimeZoneMode }

procedure TTestCase_TimeZoneMode.Test_Default_UsesLocalTimeZone;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.Default;
  
  // 验证默认使用本地时区
  AssertEquals('Default should use local timezone', Ord(tzmLocal), Ord(opts.TimeZoneMode));
  AssertEquals('SpecifiedTimeZone should be empty', '', opts.SpecifiedTimeZone);
end;

procedure TTestCase_TimeZoneMode.Test_UTC_UsesUTCTimeZone;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.UTC;
  
  // 验证使用 UTC 时区
  AssertEquals('UTC should set timezone mode to UTC', Ord(tzmUTC), Ord(opts.TimeZoneMode));
end;

procedure TTestCase_TimeZoneMode.Test_WithTimeZone_UsesSpecifiedTimeZone;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.WithTimeZone('+08:00');
  
  // 验证使用指定时区
  AssertEquals('WithTimeZone should set mode to Specified', Ord(tzmSpecified), Ord(opts.TimeZoneMode));
  AssertEquals('Should store the specified timezone', '+08:00', opts.SpecifiedTimeZone);
  
  // 测试其他时区
  opts := TParseOptions.WithTimeZone('-05:00');
  AssertEquals('Should work with negative offset', '-05:00', opts.SpecifiedTimeZone);
end;

procedure TTestCase_TimeZoneMode.Test_StrictTimeZone_RequiresTimeZoneInfo;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.StrictTimeZone;
  
  // 验证严格模式
  AssertEquals('StrictTimeZone should set mode to Strict', Ord(tzmStrict), Ord(opts.TimeZoneMode));
end;

procedure TTestCase_TimeZoneMode.Test_NoConflict_TimeZoneModeAndSpecified;
var
  opts: TParseOptions;
begin
  // ISSUE-37 的核心：确保没有冲突
  // 旧的设计可能同时设置 DefaultTimeZone 和 AssumeUTC，导致冲突
  // 新设计使用枚举，在编译时就避免了这种冲突
  
  opts := TParseOptions.UTC;
  AssertEquals('UTC mode should be set', Ord(tzmUTC), Ord(opts.TimeZoneMode));
  
  // SpecifiedTimeZone 只在 tzmSpecified 模式下使用
  opts := TParseOptions.WithTimeZone('+08:00');
  AssertEquals('Specified mode should be set', Ord(tzmSpecified), Ord(opts.TimeZoneMode));
  AssertEquals('Timezone should be stored', '+08:00', opts.SpecifiedTimeZone);
  
  // 其他模式下 SpecifiedTimeZone 应该被忽略
  opts := TParseOptions.UTC;
  AssertEquals('UTC mode should ignore SpecifiedTimeZone', '', opts.SpecifiedTimeZone);
end;

procedure TTestCase_TimeZoneMode.Test_TimeZoneModeEnum_HasFourValues;
begin
  // 验证枚举有4个值
  AssertEquals('tzmLocal should be 0', 0, Ord(tzmLocal));
  AssertEquals('tzmUTC should be 1', 1, Ord(tzmUTC));
  AssertEquals('tzmSpecified should be 2', 2, Ord(tzmSpecified));
  AssertEquals('tzmStrict should be 3', 3, Ord(tzmStrict));
end;

procedure TTestCase_TimeZoneMode.Test_ParseOptions_UTC_Factory;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.UTC;
  
  // 验证 UTC 工厂方法设置了正确的默认值
  AssertEquals('Should use lenient mode', Ord(pmLenient), Ord(opts.Mode));
  AssertEquals('Should use UTC timezone', Ord(tzmUTC), Ord(opts.TimeZoneMode));
  AssertFalse('AllowPartialMatch should be false', opts.AllowPartialMatch);
  AssertFalse('CaseSensitive should be false', opts.CaseSensitive);
end;

procedure TTestCase_TimeZoneMode.Test_ParseOptions_WithTimeZone_Factory;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.WithTimeZone('+09:00');
  
  // 验证 WithTimeZone 工厂方法
  AssertEquals('Should use lenient mode', Ord(pmLenient), Ord(opts.Mode));
  AssertEquals('Should use Specified timezone mode', Ord(tzmSpecified), Ord(opts.TimeZoneMode));
  AssertEquals('Should store timezone', '+09:00', opts.SpecifiedTimeZone);
  AssertFalse('AllowPartialMatch should be false', opts.AllowPartialMatch);
  AssertFalse('CaseSensitive should be false', opts.CaseSensitive);
end;

procedure TTestCase_TimeZoneMode.Test_ParseOptions_StrictTimeZone_Factory;
var
  opts: TParseOptions;
begin
  opts := TParseOptions.StrictTimeZone;
  
  // 验证 StrictTimeZone 工厂方法
  AssertEquals('Should use lenient mode', Ord(pmLenient), Ord(opts.Mode));
  AssertEquals('Should use Strict timezone mode', Ord(tzmStrict), Ord(opts.TimeZoneMode));
  AssertFalse('AllowPartialMatch should be false', opts.AllowPartialMatch);
  AssertFalse('CaseSensitive should be false', opts.CaseSensitive);
end;

initialization
  RegisterTest(TTestCase_TimeZoneMode);

end.
