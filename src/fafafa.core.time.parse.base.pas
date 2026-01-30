unit fafafa.core.time.parse.base;

{
  fafafa.core.time.parse.base - 时间解析基础类型

  提供时间解析模块的核心类型定义：
  - TParseMode: 解析模式枚举
  - TTimeZoneMode: 时区处理模式
  - TParseErrorCode: 错误代码枚举
  - TParseOptions: 解析选项记录
  - TParseResult: 解析结果记录
  - TFormatValidationResult: 格式验证结果

  Phase 2.2: 从 parse.pas 拆分出基础类型
}

{$modeswitch advancedrecords}
{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

type
  TStringArray = array of string;

  {**
   * TParseMode - 解析模式
   *
   * @value pmStrict - 严格模式：要求完全匹配格式
   * @value pmLenient - 宽松模式：允许一定格式变化
   * @value pmSmart - 智能模式：自动检测格式
   *}
  TParseMode = (
    pmStrict,
    pmLenient,
    pmSmart
  );

  {**
   * TTimeZoneMode - 时区处理模式
   *
   * @value tzmLocal - 假设本地时区
   * @value tzmUTC - 假设 UTC
   * @value tzmSpecified - 使用指定时区
   * @value tzmStrict - 必须包含时区信息
   *}
  TTimeZoneMode = (
    tzmLocal,
    tzmUTC,
    tzmSpecified,
    tzmStrict
  );

  {**
   * TParseErrorCode - 解析错误代码
   *}
  TParseErrorCode = (
    pecNone,                  // 无错误
    pecEmptyInput,            // 输入为空
    pecInvalidFormat,         // 格式无效
    pecInvalidDateTime,       // 日期时间值无效
    pecInvalidDate,           // 日期值无效
    pecInvalidTime,           // 时间值无效
    pecInvalidDuration,       // 持续时间值无效
    pecFormatMismatch,        // 格式不匹配
    pecOutOfRange,            // 超出范围
    pecAmbiguousInput,        // 存在歧义
    pecPartialMatch,          // 部分匹配
    pecUnsafeFormat,          // 格式不安全
    pecFormatTooLong,         // 格式过长
    pecFormatEmpty,           // 格式为空
    pecRegexTooComplex,       // 正则太复杂
    pecInputTooLong,          // 输入过长
    pecCannotDetectFormat,    // 无法检测格式
    pecLocaleNotSupported,    // locale 不支持
    pecTimeZoneNotSupported,  // 时区不支持
    pecInternalError          // 内部错误
  );

  {**
   * TParseOptions - 解析选项
   *}
  TParseOptions = record
    Mode: TParseMode;
    TimeZoneMode: TTimeZoneMode;
    SpecifiedTimeZone: string;
    Format: string;
    Locale: string;
    MaxInputLength: Integer;
    AllowLeadingZeros: Boolean;
    AllowTrailingText: Boolean;
    CaseSensitive: Boolean;

    class function Default: TParseOptions; static;
    class function Strict: TParseOptions; static;
    class function Lenient: TParseOptions; static;
    class function Smart: TParseOptions; static;
    function WithFormat(const AFormat: string): TParseOptions;
    function WithLocale(const ALocale: string): TParseOptions;
    function WithTimeZone(const ATimeZone: string): TParseOptions;
    function WithMode(AMode: TParseMode): TParseOptions;
  end;

  {**
   * TParseResult - 解析结果
   *}
  TParseResult = record
    Success: Boolean;
    ErrorCode: TParseErrorCode;
    ErrorMessage: string;
    MatchedFormat: string;
    ConsumedLength: Integer;
    RemainingText: string;

    class function Ok: TParseResult; static; overload;
    class function Ok(const AMatchedFormat: string; AConsumedLength: Integer): TParseResult; static; overload;
    class function Fail(ACode: TParseErrorCode; const AMessage: string = ''): TParseResult; static;
    function GetDefaultErrorMessage: string;
    function GetLocalizedErrorMessage(const ALocale: string = ''): string;
  end;

  {**
   * TFormatValidationResult - 格式验证结果
   *}
  TFormatValidationResult = record
    IsValid: Boolean;
    ErrorCode: TParseErrorCode;
    ErrorMessage: string;
    InvalidPosition: Integer;

    class function Valid: TFormatValidationResult; static;
    class function Invalid(ACode: TParseErrorCode; const AMessage: string; APosition: Integer = -1): TFormatValidationResult; static;
  end;

const
  // 安全限制常量
  MAX_FORMAT_LENGTH = 256;
  MAX_INPUT_LENGTH = 4096;
  MAX_REGEX_COMPLEXITY = 500;

// 错误消息函数
function GetErrorCodeMessage(ACode: TParseErrorCode): string;
function GetErrorCodeMessageLocalized(ACode: TParseErrorCode; const ALocale: string = ''): string;

implementation

{ TParseOptions }

class function TParseOptions.Default: TParseOptions;
begin
  Result.Mode := pmStrict;
  Result.TimeZoneMode := tzmLocal;
  Result.SpecifiedTimeZone := '';
  Result.Format := '';
  Result.Locale := '';
  Result.MaxInputLength := MAX_INPUT_LENGTH;
  Result.AllowLeadingZeros := True;
  Result.AllowTrailingText := False;
  Result.CaseSensitive := False;
end;

class function TParseOptions.Strict: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmStrict;
  Result.AllowTrailingText := False;
end;

class function TParseOptions.Lenient: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmLenient;
  Result.AllowLeadingZeros := True;
  Result.AllowTrailingText := True;
end;

class function TParseOptions.Smart: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmSmart;
  Result.AllowLeadingZeros := True;
  Result.AllowTrailingText := True;
end;

function TParseOptions.WithFormat(const AFormat: string): TParseOptions;
begin
  Result := Self;
  Result.Format := AFormat;
end;

function TParseOptions.WithLocale(const ALocale: string): TParseOptions;
begin
  Result := Self;
  Result.Locale := ALocale;
end;

function TParseOptions.WithTimeZone(const ATimeZone: string): TParseOptions;
begin
  Result := Self;
  Result.TimeZoneMode := tzmSpecified;
  Result.SpecifiedTimeZone := ATimeZone;
end;

function TParseOptions.WithMode(AMode: TParseMode): TParseOptions;
begin
  Result := Self;
  Result.Mode := AMode;
end;

{ TParseResult }

class function TParseResult.Ok: TParseResult;
begin
  Result.Success := True;
  Result.ErrorCode := pecNone;
  Result.ErrorMessage := '';
  Result.MatchedFormat := '';
  Result.ConsumedLength := 0;
  Result.RemainingText := '';
end;

class function TParseResult.Ok(const AMatchedFormat: string; AConsumedLength: Integer): TParseResult;
begin
  Result.Success := True;
  Result.ErrorCode := pecNone;
  Result.ErrorMessage := '';
  Result.MatchedFormat := AMatchedFormat;
  Result.ConsumedLength := AConsumedLength;
  Result.RemainingText := '';
end;

class function TParseResult.Fail(ACode: TParseErrorCode; const AMessage: string): TParseResult;
begin
  Result.Success := False;
  Result.ErrorCode := ACode;
  if AMessage <> '' then
    Result.ErrorMessage := AMessage
  else
    Result.ErrorMessage := GetErrorCodeMessage(ACode);
  Result.MatchedFormat := '';
  Result.ConsumedLength := 0;
  Result.RemainingText := '';
end;

function TParseResult.GetDefaultErrorMessage: string;
begin
  if ErrorMessage <> '' then
    Result := ErrorMessage
  else
    Result := GetErrorCodeMessage(ErrorCode);
end;

function TParseResult.GetLocalizedErrorMessage(const ALocale: string): string;
begin
  Result := GetErrorCodeMessageLocalized(ErrorCode, ALocale);
end;

{ TFormatValidationResult }

class function TFormatValidationResult.Valid: TFormatValidationResult;
begin
  Result.IsValid := True;
  Result.ErrorCode := pecNone;
  Result.ErrorMessage := '';
  Result.InvalidPosition := -1;
end;

class function TFormatValidationResult.Invalid(ACode: TParseErrorCode; const AMessage: string; APosition: Integer): TFormatValidationResult;
begin
  Result.IsValid := False;
  Result.ErrorCode := ACode;
  Result.ErrorMessage := AMessage;
  Result.InvalidPosition := APosition;
end;

{ Error Messages }

function GetErrorCodeMessage(ACode: TParseErrorCode): string;
begin
  case ACode of
    pecNone: Result := '';
    pecEmptyInput: Result := 'Input is empty';
    pecInvalidFormat: Result := 'Invalid format';
    pecInvalidDateTime: Result := 'Invalid date/time value';
    pecInvalidDate: Result := 'Invalid date value';
    pecInvalidTime: Result := 'Invalid time value';
    pecInvalidDuration: Result := 'Invalid duration value';
    pecFormatMismatch: Result := 'Input does not match the specified format';
    pecOutOfRange: Result := 'Value out of range';
    pecAmbiguousInput: Result := 'Ambiguous input';
    pecPartialMatch: Result := 'Partial match only';
    pecUnsafeFormat: Result := 'Unsafe format string';
    pecFormatTooLong: Result := 'Format string too long';
    pecFormatEmpty: Result := 'Format string is empty';
    pecRegexTooComplex: Result := 'Regex pattern too complex';
    pecInputTooLong: Result := 'Input string too long';
    pecCannotDetectFormat: Result := 'Cannot detect format';
    pecLocaleNotSupported: Result := 'Locale not supported';
    pecTimeZoneNotSupported: Result := 'Timezone not supported';
    pecInternalError: Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

function GetErrorCodeMessageLocalized(ACode: TParseErrorCode; const ALocale: string): string;
begin
  // 简化实现：暂时只支持中文和英文
  if (ALocale = 'zh') or (ALocale = 'zh-CN') or (ALocale = 'zh_CN') then
  begin
    case ACode of
      pecNone: Result := '';
      pecEmptyInput: Result := '输入为空';
      pecInvalidFormat: Result := '格式无效';
      pecInvalidDateTime: Result := '日期时间值无效';
      pecInvalidDate: Result := '日期值无效';
      pecInvalidTime: Result := '时间值无效';
      pecInvalidDuration: Result := '持续时间值无效';
      pecFormatMismatch: Result := '输入与指定格式不匹配';
      pecOutOfRange: Result := '值超出范围';
      pecAmbiguousInput: Result := '输入存在歧义';
      pecPartialMatch: Result := '仅部分匹配';
      pecUnsafeFormat: Result := '格式字符串不安全';
      pecFormatTooLong: Result := '格式字符串过长';
      pecFormatEmpty: Result := '格式字符串为空';
      pecRegexTooComplex: Result := '正则表达式太复杂';
      pecInputTooLong: Result := '输入字符串过长';
      pecCannotDetectFormat: Result := '无法检测格式';
      pecLocaleNotSupported: Result := '不支持的语言环境';
      pecTimeZoneNotSupported: Result := '不支持的时区';
      pecInternalError: Result := '内部错误';
    else
      Result := '未知错误';
    end;
  end
  else
    Result := GetErrorCodeMessage(ACode);
end;

end.
