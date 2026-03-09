unit Test_fafafa_core_time_parse_errors;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.parse,
  fafafa.core.time.duration,
  fafafa.core.time.date,
  fafafa.core.time.timeofday;

type
  {**
   * TTestCase_ParseErrors - 测试解析错误代码和国际化
   * 
   * 验证 ISSUE-38 修复：错误消息国际化
   *}
  TTestCase_ParseErrors = class(TTestCase)
  published
    procedure Test_ErrorCode_InvalidDateTime;
    procedure Test_ErrorCode_InvalidDate;
    procedure Test_ErrorCode_InvalidTime;
    procedure Test_ErrorCode_InvalidDuration;
    procedure Test_ErrorCode_EmptyInput;
    procedure Test_ErrorCode_InputTooLong;
    procedure Test_ErrorCode_FormatTooLong;
    procedure Test_ErrorCode_FormatEmpty;
    procedure Test_ErrorCode_UnsafeFormat;
    procedure Test_ErrorCode_FormatMismatch_DateByFormat;
    procedure Test_ErrorCode_FormatMismatch_DateTimeByFormat;
    procedure Test_ErrorCode_ParseDuration_FormatPrecise_ParsesClockStyle;
    procedure Test_ErrorCode_ParseDuration_FormatPrecise_RejectsCompactStyle;
    procedure Test_ErrorCode_CannotDetectFormat;
    procedure Test_SmartParse_DateTime_AssignsParsedValue;
    procedure Test_OptionsMode_Smart_ParseDateTime_FromIsoDate;
    procedure Test_OptionsMode_Smart_ParseDate_FromDateTimeInput;
    procedure Test_OptionsMode_Smart_ParseTime_FromDateTimeInput;
    procedure Test_OptionsMode_Smart_ParseDuration_ParsesPrecise;
    procedure Test_Options_AllowPartialMatch_DateTime_AllowsTrailing;
    procedure Test_Options_AllowPartialMatch_Date_AllowsTrailing;
    procedure Test_Options_AllowPartialMatch_Time_AllowsTrailing;
    procedure Test_Options_AllowPartialMatch_Duration_AllowsTrailing;
    procedure Test_DurationParser_Options_AllowPartialMatch_AllowsTrailing;
    procedure Test_ParseDuration_Base_ParsesPrecise;
    procedure Test_ParseDateTime_Base_ParsesIsoDate;
    procedure Test_ParseDate_Base_ParsesDateTimeInput;
    procedure Test_ParseTime_Base_ParsesDateTimeInput;
    
    procedure Test_LocalizedMessage_English;
    procedure Test_LocalizedMessage_Chinese;
    procedure Test_LocalizedMessage_Japanese;
    procedure Test_Result_HasErrorCode;
    procedure Test_FormatValidation_HasErrorCode;
  end;

implementation

{ TTestCase_ParseErrors }

procedure TTestCase_ParseErrors.Test_ErrorCode_InvalidDateTime;
var
  dt: TDateTime;
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDateTime('invalid-datetime', dt);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have InvalidDateTime error code', Ord(pecInvalidDateTime), Ord(res.ErrorCode));
  AssertTrue('Should have error message', Length(res.ErrorMessage) > 0);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_InvalidDate;
var
  d: TDate;
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDate('invalid-date', d);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have InvalidDate error code', Ord(pecInvalidDate), Ord(res.ErrorCode));
  AssertTrue('Should have error message', Length(res.ErrorMessage) > 0);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_InvalidTime;
var
  t: TTimeOfDay;
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseTime('invalid-time', t);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have InvalidTime error code', Ord(pecInvalidTime), Ord(res.ErrorCode));
  AssertTrue('Should have error message', Length(res.ErrorMessage) > 0);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_InvalidDuration;
var
  dur: TDuration;
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDuration('xyz', dur);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have InvalidDuration error code', Ord(pecInvalidDuration), Ord(res.ErrorCode));
  AssertTrue('Should have error message', Length(res.ErrorMessage) > 0);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_EmptyInput;
var
  dur: TDuration;
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDuration('', dur);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have EmptyInput error code', Ord(pecEmptyInput), Ord(res.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_InputTooLong;
var
  dt: TDateTime;
  res: TParseResult;
  longInput: string;
begin
  // 创建超长输入（默认限制是 10,000 字符）
  SetLength(longInput, 10001);
  FillChar(longInput[1], 10001, 'x');
  
  res := DefaultTimeParser.ParseDateTime(longInput, dt);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have InputTooLong error code', Ord(pecInputTooLong), Ord(res.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_FormatTooLong;
var
  validation: TFormatValidationResult;
  longFormat: string;
begin
  // 创建超长格式（默认限制是 1,000 字符）
  SetLength(longFormat, 1001);
  FillChar(longFormat[1], 1001, 'y');
  
  validation := ValidateFormatString(longFormat);
  AssertFalse('Should fail', validation.IsValid);
  AssertEquals('Should have FormatTooLong error code', Ord(pecFormatTooLong), Ord(validation.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_FormatEmpty;
var
  validation: TFormatValidationResult;
begin
  validation := ValidateFormatString('');
  AssertFalse('Should fail', validation.IsValid);
  AssertEquals('Should have FormatEmpty error code', Ord(pecFormatEmpty), Ord(validation.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_UnsafeFormat;
var
  validation: TFormatValidationResult;
begin
  // 测试危险字符
  validation := ValidateFormatString('yyyy-mm-dd(test)');
  AssertFalse('Should fail on parentheses', validation.IsValid);
  AssertEquals('Should have UnsafeFormat error code', Ord(pecUnsafeFormat), Ord(validation.ErrorCode));
  
  validation := ValidateFormatString('yyyy-mm-dd*');
  AssertFalse('Should fail on asterisk', validation.IsValid);
  AssertEquals('Should have UnsafeFormat error code', Ord(pecUnsafeFormat), Ord(validation.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_FormatMismatch_DateByFormat;
var
  LDate: TDate;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDate('2024/10/15', 'yyyy-mm-dd', LDate);
  AssertFalse('Should fail when date does not match specified format', LResult.Success);
  AssertEquals('Should have FormatMismatch error code', Ord(pecFormatMismatch), Ord(LResult.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_FormatMismatch_DateTimeByFormat;
var
  LDateTime: TDateTime;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDateTime('2024-10-15 12:30:00', 'yyyy-mm-dd', LDateTime);
  AssertFalse('Should fail when datetime does not match specified format', LResult.Success);
  AssertEquals('Should have FormatMismatch error code', Ord(pecFormatMismatch), Ord(LResult.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_ParseDuration_FormatPrecise_ParsesClockStyle;
var
  LDuration: TDuration;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDuration('01:30:00', 'precise', LDuration);
  AssertTrue('Should parse clock-style duration with precise format', LResult.Success);
  AssertEquals('Duration seconds should be 5400', 5400, LDuration.AsSec);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_ParseDuration_FormatPrecise_RejectsCompactStyle;
var
  LDuration: TDuration;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDuration('90s', 'precise', LDuration);
  AssertFalse('Should reject compact duration under precise format', LResult.Success);
  AssertEquals('Should return InvalidDuration error code', Ord(pecInvalidDuration), Ord(LResult.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_SmartParse_DateTime_AssignsParsedValue;
var
  LDateTime: TDateTime;
  LExpected: TDateTime;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.SmartParse('15-10-2024', LDateTime);
  AssertTrue('SmartParse should succeed for local date format', LResult.Success);

  LExpected := EncodeDate(2024, 10, 15);
  AssertTrue('SmartParse should assign parsed datetime output', Abs(LDateTime - LExpected) < (1.0 / 86400.0));
end;

procedure TTestCase_ParseErrors.Test_OptionsMode_Smart_ParseDateTime_FromIsoDate;
var
  LDateTime: TDateTime;
  LExpected: TDateTime;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Smart;
  LResult := DefaultTimeParser.ParseDateTime('2024-10-15', LOptions, LDateTime);
  AssertTrue('Smart mode should parse ISO date as datetime', LResult.Success);

  LExpected := EncodeDate(2024, 10, 15);
  AssertTrue('Parsed datetime should match expected date', Abs(LDateTime - LExpected) < (1.0 / 86400.0));
end;

procedure TTestCase_ParseErrors.Test_OptionsMode_Smart_ParseDate_FromDateTimeInput;
var
  LDate: TDate;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Smart;
  LResult := DefaultTimeParser.ParseDate('15-10-2024 12:30:00', LOptions, LDate);
  AssertTrue('Smart mode should extract date from datetime input', LResult.Success);
  AssertEquals('Year should match', 2024, LDate.GetYear);
  AssertEquals('Month should match', 10, LDate.GetMonth);
  AssertEquals('Day should match', 15, LDate.GetDay);
end;
procedure TTestCase_ParseErrors.Test_OptionsMode_Smart_ParseTime_FromDateTimeInput;
var
  LTime: TTimeOfDay;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Smart;
  LResult := DefaultTimeParser.ParseTime('15-10-2024 12:30:45', LOptions, LTime);
  AssertTrue('Smart mode should extract time from datetime input', LResult.Success);
  AssertEquals('Hour should match', 12, LTime.GetHour);
  AssertEquals('Minute should match', 30, LTime.GetMinute);
  AssertEquals('Second should match', 45, LTime.GetSecond);
end;

procedure TTestCase_ParseErrors.Test_OptionsMode_Smart_ParseDuration_ParsesPrecise;
var
  LDuration: TDuration;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Smart;
  LResult := DefaultTimeParser.ParseDuration('01:30:00', LOptions, LDuration);
  AssertTrue('Smart mode should parse precise duration format', LResult.Success);
  AssertEquals('Duration seconds should be 5400', 5400, LDuration.AsSec);
end;

procedure TTestCase_ParseErrors.Test_Options_AllowPartialMatch_DateTime_AllowsTrailing;
var
  LDateTime: TDateTime;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Default;
  LOptions.AllowPartialMatch := False;
  LResult := DefaultTimeParser.ParseDateTime('2024-10-15 trailing', LOptions, LDateTime);
  AssertFalse('AllowPartialMatch=False should reject trailing datetime text', LResult.Success);

  LOptions.AllowPartialMatch := True;
  LResult := DefaultTimeParser.ParseDateTime('2024-10-15 trailing', LOptions, LDateTime);
  AssertTrue('AllowPartialMatch=True should accept trailing datetime text', LResult.Success);
end;

procedure TTestCase_ParseErrors.Test_Options_AllowPartialMatch_Date_AllowsTrailing;
var
  LDate: TDate;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Default;
  LOptions.AllowPartialMatch := True;
  LResult := DefaultTimeParser.ParseDate('2024-10-15 trailing', LOptions, LDate);
  AssertTrue('AllowPartialMatch=True should accept trailing date text', LResult.Success);
  AssertEquals('Year should match', 2024, LDate.GetYear);
  AssertEquals('Month should match', 10, LDate.GetMonth);
  AssertEquals('Day should match', 15, LDate.GetDay);
end;

procedure TTestCase_ParseErrors.Test_Options_AllowPartialMatch_Time_AllowsTrailing;
var
  LTime: TTimeOfDay;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Default;
  LOptions.AllowPartialMatch := True;
  LResult := DefaultTimeParser.ParseTime('12:30:45 trailing', LOptions, LTime);
  AssertTrue('AllowPartialMatch=True should accept trailing time text', LResult.Success);
  AssertEquals('Hour should match', 12, LTime.GetHour);
  AssertEquals('Minute should match', 30, LTime.GetMinute);
  AssertEquals('Second should match', 45, LTime.GetSecond);
end;

procedure TTestCase_ParseErrors.Test_Options_AllowPartialMatch_Duration_AllowsTrailing;
var
  LDuration: TDuration;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Default;
  LOptions.AllowPartialMatch := True;
  LResult := DefaultTimeParser.ParseDuration('01:30:00 trailing', LOptions, LDuration);
  AssertTrue('AllowPartialMatch=True should accept trailing duration text', LResult.Success);
  AssertEquals('Duration seconds should be 5400', 5400, LDuration.AsSec);
end;

procedure TTestCase_ParseErrors.Test_DurationParser_Options_AllowPartialMatch_AllowsTrailing;
var
  LDuration: TDuration;
  LOptions: TParseOptions;
  LResult: TParseResult;
begin
  LOptions := TParseOptions.Default;
  LOptions.AllowPartialMatch := False;
  LResult := DefaultDurationParser.Parse('01:30:00 trailing', LOptions, LDuration);
  AssertFalse('AllowPartialMatch=False should reject trailing duration text (DurationParser)', LResult.Success);

  LOptions.AllowPartialMatch := True;
  LResult := DefaultDurationParser.Parse('01:30:00 trailing', LOptions, LDuration);
  AssertTrue('AllowPartialMatch=True should accept trailing duration text (DurationParser)', LResult.Success);
  AssertEquals('Duration seconds should be 5400 (DurationParser)', 5400, LDuration.AsSec);
end;

procedure TTestCase_ParseErrors.Test_ParseDuration_Base_ParsesPrecise;
var
  LDuration: TDuration;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDuration('01:30:00', LDuration);
  AssertTrue('Base ParseDuration should parse precise duration format', LResult.Success);
  AssertEquals('Duration seconds should be 5400', 5400, LDuration.AsSec);
end;

procedure TTestCase_ParseErrors.Test_ParseDateTime_Base_ParsesIsoDate;
var
  LDateTime: TDateTime;
  LExpected: TDateTime;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDateTime('2024-10-15', LDateTime);
  AssertTrue('Base ParseDateTime should parse ISO date', LResult.Success);

  LExpected := EncodeDate(2024, 10, 15);
  AssertTrue('Parsed datetime should match expected date', Abs(LDateTime - LExpected) < (1.0 / 86400.0));
end;

procedure TTestCase_ParseErrors.Test_ParseDate_Base_ParsesDateTimeInput;
var
  LDate: TDate;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseDate('15-10-2024 12:30:00', LDate);
  AssertTrue('Base ParseDate should parse datetime input', LResult.Success);
  AssertEquals('Year should match', 2024, LDate.GetYear);
  AssertEquals('Month should match', 10, LDate.GetMonth);
  AssertEquals('Day should match', 15, LDate.GetDay);
end;

procedure TTestCase_ParseErrors.Test_ParseTime_Base_ParsesDateTimeInput;
var
  LTime: TTimeOfDay;
  LResult: TParseResult;
begin
  LResult := DefaultTimeParser.ParseTime('15-10-2024 12:30:45', LTime);
  AssertTrue('Base ParseTime should parse datetime input', LResult.Success);
  AssertEquals('Hour should match', 12, LTime.GetHour);
  AssertEquals('Minute should match', 30, LTime.GetMinute);
  AssertEquals('Second should match', 45, LTime.GetSecond);
end;

procedure TTestCase_ParseErrors.Test_ErrorCode_CannotDetectFormat;
var
  dt: TDateTime;
  res: TParseResult;
begin
  res := DefaultTimeParser.SmartParse('gibberish nonsense', dt);
  AssertFalse('Should fail', res.Success);
  AssertEquals('Should have CannotDetectFormat error code', Ord(pecCannotDetectFormat), Ord(res.ErrorCode));
end;

procedure TTestCase_ParseErrors.Test_LocalizedMessage_English;
var
  res: TParseResult;
  msg: string;
begin
  res := TParseResult.CreateErrorCode(pecInvalidDateTime, 0);
  
  // 默认应该是英文
  AssertEquals('Default message should be English', 'Invalid date/time value', res.ErrorMessage);
  
  // 显式请求英文
  msg := res.GetLocalizedErrorMessage('en');
  AssertEquals('English message', 'Invalid date/time value', msg);
end;

procedure TTestCase_ParseErrors.Test_LocalizedMessage_Chinese;
var
  res: TParseResult;
  msg: string;
begin
  res := TParseResult.CreateErrorCode(pecInvalidDateTime, 0);
  
  msg := res.GetLocalizedErrorMessage('zh-cn');
  AssertEquals('Chinese message', '日期时间值无效', msg);
  
  msg := res.GetLocalizedErrorMessage('zh');
  AssertEquals('Chinese message (short code)', '日期时间值无效', msg);
end;

procedure TTestCase_ParseErrors.Test_LocalizedMessage_Japanese;
var
  res: TParseResult;
  msg: string;
begin
  res := TParseResult.CreateErrorCode(pecInvalidDateTime, 0);
  
  msg := res.GetLocalizedErrorMessage('ja');
  AssertEquals('Japanese message', '無効な日付/時刻値', msg);
  
  msg := res.GetLocalizedErrorMessage('ja-jp');
  AssertEquals('Japanese message (full code)', '無効な日付/時刻値', msg);
end;

procedure TTestCase_ParseErrors.Test_Result_HasErrorCode;
var
  res: TParseResult;
begin
  // 测试成功情况
  res := TParseResult.CreateSuccess(10, 'test');
  AssertTrue('Success should be true', res.Success);
  AssertEquals('Success should have pecNone code', Ord(pecNone), Ord(res.ErrorCode));
  
  // 测试错误情况
  res := TParseResult.CreateError(pecInvalidDate, 'Test error', 5);
  AssertFalse('Should be failure', res.Success);
  AssertEquals('Should have InvalidDate code', Ord(pecInvalidDate), Ord(res.ErrorCode));
  AssertEquals('Should have custom message', 'Test error', res.ErrorMessage);
  AssertEquals('Should have error position', 5, res.ErrorPosition);
end;

procedure TTestCase_ParseErrors.Test_FormatValidation_HasErrorCode;
var
  validation: TFormatValidationResult;
begin
  // 测试成功情况
  validation := TFormatValidationResult.Valid;
  AssertTrue('Should be valid', validation.IsValid);
  AssertEquals('Valid should have pecNone code', Ord(pecNone), Ord(validation.ErrorCode));
  
  // 测试错误情况
  validation := TFormatValidationResult.Invalid(pecUnsafeFormat, 'Dangerous char', 10);
  AssertFalse('Should be invalid', validation.IsValid);
  AssertEquals('Should have UnsafeFormat code', Ord(pecUnsafeFormat), Ord(validation.ErrorCode));
  AssertEquals('Should have error message', 'Dangerous char', validation.ErrorMessage);
  AssertEquals('Should have position', 10, validation.InvalidPosition);
end;

initialization
  RegisterTest(TTestCase_ParseErrors);

end.
