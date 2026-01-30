unit Test_fafafa_core_time_parse_errors;

{$mode objfpc}{$H+}

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
    procedure Test_ErrorCode_CannotDetectFormat;
    
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
