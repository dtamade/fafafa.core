{$mode objfpc}{$H+}{$J-}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_parse_security;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.parse,
  fafafa.core.time.date,
  fafafa.core.time.timeofday;

type
  { 
    测试 ISSUE-40 修复：正则注入风险防护
    
    验证以下安全机制：
    1. 格式字符串白名单验证
    2. 正则表达式复杂度限制  
    3. 输入长度限制
  }
  TTestParseSecurity = class(TTestCase)
  published
    // 格式字符串白名单验证测试
    procedure Test_ValidateFormatString_ValidFormats;
    procedure Test_ValidateFormatString_RejectDangerousChars;
    procedure Test_ValidateFormatString_RejectTooLong;
    procedure Test_ValidateFormatString_RejectEmpty;
    procedure Test_ValidateFormatString_RejectUnknownTokens;
    
    // 正则复杂度估算测试
    procedure Test_EstimateRegexComplexity_SimplePattern;
    procedure Test_EstimateRegexComplexity_NestedQuantifiers;
    procedure Test_EstimateRegexComplexity_CharClasses;
    procedure Test_EstimateRegexComplexity_Backreferences;
    
    // DoS 防护测试
    procedure Test_ParseDateTime_RejectTooLongInput;
    procedure Test_ParseDateTime_RejectMaliciousFormat;
    
    // ISSUE-47: 输入长度限制测试（扩展）
    procedure Test_ParseDate_RejectTooLongInput;
    procedure Test_ParseTime_RejectTooLongInput;
    procedure Test_SmartParse_RejectTooLongInput;
    procedure Test_DetectFormat_RejectTooLongInput;
    
    // 已知攻击模式测试
    procedure Test_RejectReDoSPatterns;
  end;

implementation

{ TTestParseSecurity }

procedure TTestParseSecurity.Test_ValidateFormatString_ValidFormats;
var
  result: TFormatValidationResult;
begin
  // ISO 8601 日期格式
  result := ValidateFormatString('yyyy-mm-dd');
  CheckTrue(result.IsValid, '应接受 yyyy-mm-dd');
  
  // ISO 8601 时间格式
  result := ValidateFormatString('hh:nn:ss');
  CheckTrue(result.IsValid, '应接受 hh:nn:ss');
  
  // ISO 8601 日期时间格式
  result := ValidateFormatString('yyyy-mm-dd"T"hh:nn:ss.zzz');
  CheckTrue(result.IsValid, '应接受 ISO 8601 完整格式');
  
  // 12小时制格式
  result := ValidateFormatString('hh:nn AM/PM');
  CheckTrue(result.IsValid, '应接受 12小时制格式');
  
  // 持续时间格式
  result := ValidateFormatString('PT#H#M#S');
  CheckTrue(result.IsValid, '应接受持续时间格式');
  
  // 自定义分隔符
  result := ValidateFormatString('yyyy/mm/dd hh:nn:ss');
  CheckTrue(result.IsValid, '应接受自定义分隔符');
end;

procedure TTestParseSecurity.Test_ValidateFormatString_RejectDangerousChars;
var
  result: TFormatValidationResult;
begin
  // 正则元字符 - 括号
  result := ValidateFormatString('yyyy-(mm)-dd');
  CheckFalse(result.IsValid, '应拒绝包含 ()');
  CheckEquals(Ord(pecUnsafeFormat), Ord(result.ErrorCode), '错误码应为 pecUnsafeFormat');
  
  // 方括号
  result := ValidateFormatString('yyyy[mm]dd');
  CheckFalse(result.IsValid, '应拒绝包含 []');
  
  // 大括号
  result := ValidateFormatString('yyyy{1,4}');
  CheckFalse(result.IsValid, '应拒绝包含 {}');
  
  // 量词
  result := ValidateFormatString('yyyy+');
  CheckFalse(result.IsValid, '应拒绝包含 +');
  
  result := ValidateFormatString('yyyy*');
  CheckFalse(result.IsValid, '应拒绝包含 *');
  
  result := ValidateFormatString('yyyy?');
  CheckFalse(result.IsValid, '应拒绝包含 ?');
  
  // 选择符和锚点
  result := ValidateFormatString('yyyy|mm|dd');
  CheckFalse(result.IsValid, '应拒绝包含 |');
  
  result := ValidateFormatString('^yyyy-mm-dd$');
  CheckFalse(result.IsValid, '应拒绝包含 ^ 和 $');
  
  // 转义字符
  result := ValidateFormatString('yyyy\mm\dd');
  CheckFalse(result.IsValid, '应拒绝包含反斜杠');
end;

procedure TTestParseSecurity.Test_ValidateFormatString_RejectTooLong;
var
  result: TFormatValidationResult;
  longFormat: string;
begin
  // 生成超长格式字符串 (257 字符)
  longFormat := StringOfChar('y', 257);
  result := ValidateFormatString(longFormat);
  CheckFalse(result.IsValid, '应拒绝超长格式字符串');
  CheckEquals(Ord(pecFormatTooLong), Ord(result.ErrorCode), '错误码应为 pecFormatTooLong');
end;

procedure TTestParseSecurity.Test_ValidateFormatString_RejectEmpty;
var
  result: TFormatValidationResult;
begin
  result := ValidateFormatString('');
  CheckFalse(result.IsValid, '应拒绝空字符串');
  CheckEquals(Ord(pecFormatEmpty), Ord(result.ErrorCode), '错误码应为 pecFormatEmpty');
end;

procedure TTestParseSecurity.Test_ValidateFormatString_RejectUnknownTokens;
var
  result: TFormatValidationResult;
begin
  // 未知标记
  result := ValidateFormatString('yyyy-XX-dd');
  CheckFalse(result.IsValid, '应拒绝未知标记 XX');
  CheckEquals(Ord(pecUnsafeFormat), Ord(result.ErrorCode), '错误码应为 pecUnsafeFormat');
  
  // SQL 注入尝试
  result := ValidateFormatString('yyyy-mm-dd''; DROP TABLE users; --');
  CheckFalse(result.IsValid, '应拒绝 SQL 注入模式');
end;

procedure TTestParseSecurity.Test_EstimateRegexComplexity_SimplePattern;
var
  complexity: Integer;
begin
  // 简单模式复杂度应该很低
  complexity := EstimateRegexComplexity('yyyy-mm-dd');
  CheckTrue(complexity < 20, Format('简单模式复杂度应 < 20，实际：%d', [complexity]));
  
  complexity := EstimateRegexComplexity('hh:nn:ss');
  CheckTrue(complexity < 20, Format('简单模式复杂度应 < 20，实际：%d', [complexity]));
end;

procedure TTestParseSecurity.Test_EstimateRegexComplexity_NestedQuantifiers;
var
  complexity: Integer;
begin
  // 嵌套量词 (回溯炸弹特征)
  complexity := EstimateRegexComplexity('(a+)+');
  CheckTrue(complexity > 50, Format('嵌套量词复杂度应 > 50，实际：%d', [complexity]));
  
  complexity := EstimateRegexComplexity('(a*)*b');
  CheckTrue(complexity > 50, Format('嵌套量词复杂度应 > 50，实际：%d', [complexity]));
  
  // 多级嵌套
  complexity := EstimateRegexComplexity('((a+)+)+');
  CheckTrue(complexity > 100, Format('多级嵌套量词复杂度应 > 100，实际：%d', [complexity]));
end;

procedure TTestParseSecurity.Test_EstimateRegexComplexity_CharClasses;
var
  complexity: Integer;
begin
  // 字符类
  complexity := EstimateRegexComplexity('[a-z]+');
  CheckTrue((complexity >= 0) and (complexity < 20), Format('字符类复杂度应在 0-20，实际：%d', [complexity]));
  
  // 多个字符类（每个带量词，3个量词 * 3 = 9）
  complexity := EstimateRegexComplexity('[a-z]+[0-9]+[A-Z]+');
  CheckTrue(complexity >= 9, Format('多字符类复杂度应 >= 9，实际：%d', [complexity]));
end;

procedure TTestParseSecurity.Test_EstimateRegexComplexity_Backreferences;
var
  complexity: Integer;
begin
  // 回溯引用
  complexity := EstimateRegexComplexity('(a)\1');
  CheckTrue(complexity > 10, Format('回溯引用复杂度应 > 10，实际：%d', [complexity]));
  
  // 多个回溯引用
  complexity := EstimateRegexComplexity('(a)(b)(c)\1\2\3');
  CheckTrue(complexity > 30, Format('多回溯引用复杂度应 > 30，实际：%d', [complexity]));
end;

procedure TTestParseSecurity.Test_ParseDateTime_RejectTooLongInput;
var
  dt: TDateTime;
  result: TParseResult;
  longInput: string;
begin
  // 生成超长输入 (4097 字符)
  longInput := StringOfChar('2', 4097) + '-01-01T00:00:00';
  
  result := DefaultTimeParser.ParseDateTime(longInput, dt);
  CheckFalse(result.Success, '应拒绝超长输入');
  CheckEquals(Ord(pecInputTooLong), Ord(result.ErrorCode), '错误码应为 pecInputTooLong');
end;

procedure TTestParseSecurity.Test_ParseDateTime_RejectMaliciousFormat;
var
  dt: TDateTime;
  result: TParseResult;
begin
  // 尝试注入恶意格式字符串
  result := DefaultTimeParser.ParseDateTime('2024-01-01', '(a+)+', dt);
  CheckFalse(result.Success, '应拒绝恶意格式字符串');
  CheckEquals(Ord(pecUnsafeFormat), Ord(result.ErrorCode), '错误码应为 pecUnsafeFormat');
end;

procedure TTestParseSecurity.Test_RejectReDoSPatterns;
var
  result: TFormatValidationResult;
  complexity: Integer;
begin
  // 已知的 ReDoS (Regular expression Denial of Service) 攻击模式
  
  // 模式 1: 嵌套量词
  result := ValidateFormatString('(a+)+b');
  CheckFalse(result.IsValid, '应拒绝 ReDoS 模式 (a+)+');
  
  // 模式 2: 重叠字符类（每个带量词，2个量词 * 3 = 6）
  complexity := EstimateRegexComplexity('[a-zA-Z]+[a-z0-9]+');
  CheckTrue(complexity >= 6, Format('重叠字符类应有一定复杂度，实际：%d', [complexity]));
  
  // 模式 3: 过度回溯
  complexity := EstimateRegexComplexity('(.*)(.*)(.*) $');
  CheckTrue(complexity > 20, '过度回溯模式应被标记为高复杂度');
  
  // 模式 4: 指数级量词
  complexity := EstimateRegexComplexity('(a|a)*');
  CheckTrue(complexity > 50, '指数级量词应被标记为极高复杂度');
end;

{ ISSUE-47: 输入长度限制测试（扩展）}

procedure TTestParseSecurity.Test_ParseDate_RejectTooLongInput;
var
  d: TDate;
  result: TParseResult;
  longInput: string;
begin
  // 生成超长输入 (4097 字符)
  longInput := StringOfChar('2', 4097) + '-01-01';
  
  result := DefaultTimeParser.ParseDate(longInput, d);
  CheckFalse(result.Success, '应拒绝超长日期输入');
  CheckEquals(Ord(pecInputTooLong), Ord(result.ErrorCode), '错误码应为 pecInputTooLong');
end;

procedure TTestParseSecurity.Test_ParseTime_RejectTooLongInput;
var
  t: TTimeOfDay;
  result: TParseResult;
  longInput: string;
begin
  // 生成超长输入 (4097 字符)
  longInput := StringOfChar('1', 4097) + ':23:45';
  
  result := DefaultTimeParser.ParseTime(longInput, t);
  CheckFalse(result.Success, '应拒绝超长时间输入');
  CheckEquals(Ord(pecInputTooLong), Ord(result.ErrorCode), '错误码应为 pecInputTooLong');
end;

procedure TTestParseSecurity.Test_SmartParse_RejectTooLongInput;
var
  dt: TDateTime;
  result: TParseResult;
  longInput: string;
begin
  // 生成超长输入 (4097 字符)
  longInput := StringOfChar('2', 4097) + '-01-01T00:00:00';
  
  result := DefaultTimeParser.SmartParse(longInput, dt);
  CheckFalse(result.Success, '应拒绝超长输入（智能解析）');
  CheckEquals(Ord(pecInputTooLong), Ord(result.ErrorCode), '错误码应为 pecInputTooLong');
end;

procedure TTestParseSecurity.Test_DetectFormat_RejectTooLongInput;
var
  fmt: string;
  longInput: string;
begin
  // 生成超长输入 (4097 字符)
  longInput := StringOfChar('2', 4097) + '-01-01';
  
  fmt := DefaultTimeParser.DetectFormat(longInput);
  CheckEquals('', fmt, '应返回空字符串表示无法检测');
end;

initialization
  RegisterTest(TTestParseSecurity);

end.
