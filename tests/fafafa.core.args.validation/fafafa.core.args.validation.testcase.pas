{$CODEPAGE UTF8}
unit fafafa.core.args.validation.testcase;
{**
 * fafafa.core.args.validation 单元测试
 * 覆盖验证器流式 API、预定义验证规则和异常处理
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.base,
  fafafa.core.args.errors,
  fafafa.core.args.validation;

type
  TTestCase_ArgsValidation = class(TTestCase)
  published
    // TValidationRule 工厂方法测试
    procedure Test_Rule_Required;
    procedure Test_Rule_Optional;
    procedure Test_Rule_Range;
    procedure Test_Rule_MinLength;
    procedure Test_Rule_MaxLength;
    procedure Test_Rule_Pattern;
    procedure Test_Rule_Enum;
    procedure Test_Rule_Email;
    procedure Test_Rule_Url;
    procedure Test_Rule_IPAddress;
    procedure Test_Rule_Port;
    procedure Test_Rule_FileExists;
    procedure Test_Rule_DirectoryExists;
    procedure Test_Rule_Custom;

    // TValidationResult 测试
    procedure Test_Result_Success;
    procedure Test_Result_Failure;
    procedure Test_Result_AddError;
    procedure Test_Result_GetFirstError;
    procedure Test_Result_HasErrors;
    procedure Test_Result_ErrorCount;

    // TArgsValidator 流式 API 测试
    procedure Test_Validator_Required_Present;
    procedure Test_Validator_Required_Missing;
    procedure Test_Validator_Range_Valid;
    procedure Test_Validator_Range_Invalid;
    procedure Test_Validator_MinLength_Valid;
    procedure Test_Validator_MinLength_Invalid;
    procedure Test_Validator_MaxLength_Valid;
    procedure Test_Validator_MaxLength_Invalid;
    procedure Test_Validator_Pattern_Valid;
    procedure Test_Validator_Pattern_Invalid;
    procedure Test_Validator_Enum_Valid;
    procedure Test_Validator_Enum_Invalid;
    procedure Test_Validator_Email_Valid;
    procedure Test_Validator_Email_Invalid;
    procedure Test_Validator_Url_Valid;
    procedure Test_Validator_Url_Invalid;
    procedure Test_Validator_IPAddress_Valid;
    procedure Test_Validator_IPAddress_Invalid;
    procedure Test_Validator_Port_Valid;
    procedure Test_Validator_Port_Invalid;
    procedure Test_Validator_Custom_Valid;
    procedure Test_Validator_Custom_Invalid;

    // 链式验证测试
    procedure Test_Validator_ChainedRules;
    procedure Test_Validator_StopOnFirstError;
    procedure Test_Validator_CollectAllErrors;

    // 异常测试
    procedure Test_ValidateAndThrow_Success;
    procedure Test_ValidateAndThrow_Failure;

    // 预定义验证函数测试
    procedure Test_IsValidEmail_Valid;
    procedure Test_IsValidEmail_Invalid;
    procedure Test_IsValidUrl_Valid;
    procedure Test_IsValidUrl_Invalid;
    procedure Test_IsValidIPAddress_Valid;
    procedure Test_IsValidIPAddress_Invalid;
    procedure Test_IsValidPort_Valid;
    procedure Test_IsValidPort_Invalid;

    // 边界测试
    procedure Test_Validator_OptionalKey_Skipped;
    procedure Test_Validator_EmptyArgs;
  end;

implementation

{ 辅助函数 }

function CustomValidatorPositive(const Value: string; out ErrorMsg: string): Boolean;
var
  N: Int64;
begin
  if not TryStrToInt64(Value, N) then
  begin
    ErrorMsg := 'Must be an integer';
    Exit(False);
  end;
  if N <= 0 then
  begin
    ErrorMsg := 'Must be positive';
    Exit(False);
  end;
  Result := True;
end;

{ TValidationRule 工厂方法测试 }

procedure TTestCase_ArgsValidation.Test_Rule_Required;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Required('config');

  CheckEquals(Ord(vtRequired), Ord(Rule.ValidatorType));
  CheckEquals('config', Rule.Key);
  CheckTrue(Pos('Required', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Optional;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Optional('debug');

  CheckEquals(Ord(vtOptional), Ord(Rule.ValidatorType));
  CheckEquals('debug', Rule.Key);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Range;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Range('port', 1, 65535);

  CheckEquals(Ord(vtRange), Ord(Rule.ValidatorType));
  CheckEquals('port', Rule.Key);
  CheckEquals(1, Rule.MinValue);
  CheckEquals(65535, Rule.MaxValue);
  CheckTrue(Pos('between', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_MinLength;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.MinLength('password', 8);

  CheckEquals(Ord(vtMinLength), Ord(Rule.ValidatorType));
  CheckEquals('password', Rule.Key);
  CheckEquals(8, Rule.MinValue);
end;

procedure TTestCase_ArgsValidation.Test_Rule_MaxLength;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.MaxLength('name', 50);

  CheckEquals(Ord(vtMaxLength), Ord(Rule.ValidatorType));
  CheckEquals('name', Rule.Key);
  CheckEquals(50, Rule.MaxValue);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Pattern;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.MatchPattern('code', '^[A-Z]{3}$');

  CheckEquals(Ord(vtPattern), Ord(Rule.ValidatorType));
  CheckEquals('code', Rule.Key);
  CheckEquals('^[A-Z]{3}$', Rule.Pattern);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Enum;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Enum('level', ['debug', 'info', 'warn', 'error']);

  CheckEquals(Ord(vtEnum), Ord(Rule.ValidatorType));
  CheckEquals('level', Rule.Key);
  CheckEquals(4, Length(Rule.ValidValues));
  CheckEquals('debug', Rule.ValidValues[0]);
  CheckEquals('error', Rule.ValidValues[3]);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Email;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Email('contact');

  CheckEquals(Ord(vtEmail), Ord(Rule.ValidatorType));
  CheckEquals('contact', Rule.Key);
  CheckTrue(Pos('email', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Url;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Url('homepage');

  CheckEquals(Ord(vtUrl), Ord(Rule.ValidatorType));
  CheckEquals('homepage', Rule.Key);
  CheckTrue(Pos('URL', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_IPAddress;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.IPAddress('server');

  CheckEquals(Ord(vtIPAddress), Ord(Rule.ValidatorType));
  CheckEquals('server', Rule.Key);
  CheckTrue(Pos('IP', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Port;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Port('listen');

  CheckEquals(Ord(vtPort), Ord(Rule.ValidatorType));
  CheckEquals('listen', Rule.Key);
  CheckTrue(Pos('port', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_FileExists;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.FileExists('input');

  CheckEquals(Ord(vtFile), Ord(Rule.ValidatorType));
  CheckEquals('input', Rule.Key);
  CheckTrue(Pos('File', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_DirectoryExists;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.DirectoryExists('output');

  CheckEquals(Ord(vtDirectory), Ord(Rule.ValidatorType));
  CheckEquals('output', Rule.Key);
  CheckTrue(Pos('Directory', Rule.ErrorMessage) > 0);
end;

procedure TTestCase_ArgsValidation.Test_Rule_Custom;
var
  Rule: TValidationRule;
begin
  Rule := TValidationRule.Custom('count', @CustomValidatorPositive, 'Must be positive');

  CheckEquals(Ord(vtCustom), Ord(Rule.ValidatorType));
  CheckEquals('count', Rule.Key);
  CheckEquals('Must be positive', Rule.ErrorMessage);
  CheckTrue(Assigned(Rule.CustomValidator));
end;

{ TValidationResult 测试 }

procedure TTestCase_ArgsValidation.Test_Result_Success;
var
  R: TValidationResult;
begin
  R := TValidationResult.Success;

  CheckTrue(R.IsValid, 'Success result should be valid');
  CheckEquals(0, Length(R.Errors), 'Success result should have no errors');
end;

procedure TTestCase_ArgsValidation.Test_Result_Failure;
var
  R: TValidationResult;
  Err: TArgsError;
begin
  Err := TArgsError.RequiredMissing('config');
  R := TValidationResult.Failure([Err]);

  CheckFalse(R.IsValid, 'Failure result should not be valid');
  CheckEquals(1, Length(R.Errors), 'Should have 1 error');
end;

procedure TTestCase_ArgsValidation.Test_Result_AddError;
var
  R: TValidationResult;
begin
  R := TValidationResult.Success;
  R := R.AddError(TArgsError.RequiredMissing('a'));
  R := R.AddError(TArgsError.RequiredMissing('b'));

  CheckFalse(R.IsValid, 'Should be invalid after adding errors');
  CheckEquals(2, Length(R.Errors), 'Should have 2 errors');
end;

procedure TTestCase_ArgsValidation.Test_Result_GetFirstError;
var
  R: TValidationResult;
  Err: TArgsError;
begin
  R := TValidationResult.Success;
  R := R.AddError(TArgsError.RequiredMissing('first'));
  R := R.AddError(TArgsError.RequiredMissing('second'));

  Err := R.GetFirstError;
  CheckTrue(Pos('first', Err.Message) > 0, 'GetFirstError should return first added error');
end;

procedure TTestCase_ArgsValidation.Test_Result_HasErrors;
var
  R: TValidationResult;
begin
  R := TValidationResult.Success;
  CheckFalse(R.HasErrors, 'Success should not have errors');

  R := R.AddError(TArgsError.ParseError('test'));
  CheckTrue(R.HasErrors, 'Should have errors after adding');
end;

procedure TTestCase_ArgsValidation.Test_Result_ErrorCount;
var
  R: TValidationResult;
begin
  R := TValidationResult.Success;
  CheckEquals(0, R.ErrorCount);

  R := R.AddError(TArgsError.ParseError('1'));
  R := R.AddError(TArgsError.ParseError('2'));
  R := R.AddError(TArgsError.ParseError('3'));
  CheckEquals(3, R.ErrorCount);
end;

{ TArgsValidator 流式 API 测试 }

procedure TTestCase_ArgsValidation.Test_Validator_Required_Present;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--config=app.conf'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Required('config').Validate;
    CheckTrue(R.IsValid, 'Required present should pass');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Required_Missing;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--other=value'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Required('config').Validate;
    CheckFalse(R.IsValid, 'Required missing should fail');
    CheckEquals(1, R.ErrorCount);
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Range_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=8080'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Range('port', 1, 65535).Validate;
    CheckTrue(R.IsValid, 'Port 8080 should be in range');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Range_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=99999'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Range('port', 1, 65535).Validate;
    CheckFalse(R.IsValid, 'Port 99999 should be out of range');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_MinLength_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--password=secret123'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.MinLength('password', 8).Validate;
    CheckTrue(R.IsValid, 'Password length 9 should pass min 8');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_MinLength_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--password=short'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.MinLength('password', 8).Validate;
    CheckFalse(R.IsValid, 'Password "short" should fail min 8');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_MaxLength_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=John'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.MaxLength('name', 50).Validate;
    CheckTrue(R.IsValid, 'Name "John" should pass max 50');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_MaxLength_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=VeryLongNameThatExceedsLimit'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.MaxLength('name', 10).Validate;
    CheckFalse(R.IsValid, 'Long name should fail max 10');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Pattern_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--code=ABC'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Pattern('code', '^[A-Z]{3}$').Validate;
    CheckTrue(R.IsValid, 'ABC should match ^[A-Z]{3}$');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Pattern_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--code=abc123'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Pattern('code', '^[A-Z]{3}$').Validate;
    CheckFalse(R.IsValid, 'abc123 should not match ^[A-Z]{3}$');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Enum_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--level=info'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Enum('level', ['debug', 'info', 'warn', 'error']).Validate;
    CheckTrue(R.IsValid, 'info should be valid enum value');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Enum_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--level=trace'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Enum('level', ['debug', 'info', 'warn', 'error']).Validate;
    CheckFalse(R.IsValid, 'trace should be invalid enum value');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Email_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--email=user@example.com'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Email('email').Validate;
    CheckTrue(R.IsValid, 'user@example.com should be valid email');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Email_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--email=invalid-email'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Email('email').Validate;
    CheckFalse(R.IsValid, 'invalid-email should fail email validation');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Url_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--url=https://example.com'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Url('url').Validate;
    CheckTrue(R.IsValid, 'https://example.com should be valid URL');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Url_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--url=not-a-url'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Url('url').Validate;
    CheckFalse(R.IsValid, 'not-a-url should fail URL validation');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_IPAddress_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--ip=192.168.1.1'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.IPAddress('ip').Validate;
    CheckTrue(R.IsValid, '192.168.1.1 should be valid IP');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_IPAddress_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--ip=999.999.999.999'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.IPAddress('ip').Validate;
    CheckFalse(R.IsValid, '999.999.999.999 should fail IP validation');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Port_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=8080'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Port('port').Validate;
    CheckTrue(R.IsValid, '8080 should be valid port');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Port_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=99999'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Port('port').Validate;
    CheckFalse(R.IsValid, '99999 should fail port validation');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Custom_Valid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--count=42'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Custom('count', @CustomValidatorPositive, 'Must be positive').Validate;
    CheckTrue(R.IsValid, '42 should pass positive validator');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_Custom_Invalid;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--count=-5'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Custom('count', @CustomValidatorPositive, 'Must be positive').Validate;
    CheckFalse(R.IsValid, '-5 should fail positive validator');
  finally
    V.Free;
  end;
end;

{ 链式验证测试 }

procedure TTestCase_ArgsValidation.Test_Validator_ChainedRules;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--config=app.conf', '--port=8080', '--level=info'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V
      .Required('config')
      .Range('port', 1, 65535)
      .Enum('level', ['debug', 'info', 'warn', 'error'])
      .Validate;
    CheckTrue(R.IsValid, 'All chained rules should pass');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_StopOnFirstError;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=abc', '--count=-1'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V
      .StopOnFirstError(True)
      .Range('port', 1, 65535)      // Will fail first
      .Range('count', 1, 100)       // Won't be checked
      .Validate;
    CheckFalse(R.IsValid);
    CheckEquals(1, R.ErrorCount, 'Should stop at first error');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_CollectAllErrors;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray([], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V
      .StopOnFirstError(False)
      .Required('config')
      .Required('port')
      .Required('level')
      .Validate;
    CheckFalse(R.IsValid);
    CheckEquals(3, R.ErrorCount, 'Should collect all 3 errors');
  finally
    V.Free;
  end;
end;

{ 异常测试 }

procedure TTestCase_ArgsValidation.Test_ValidateAndThrow_Success;
var
  Args: IArgs;
  V: TArgsValidator;
  Passed: Boolean;
begin
  Args := TArgs.FromArray(['--config=app.conf'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    Passed := False;
    try
      V.Required('config').ValidateAndThrow;
      Passed := True;
    except
      on E: EArgsValidationException do
        Passed := False;
    end;
    CheckTrue(Passed, 'ValidateAndThrow should not raise on success');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_ValidateAndThrow_Failure;
var
  Args: IArgs;
  V: TArgsValidator;
  ExceptionRaised: Boolean;
begin
  Args := TArgs.FromArray([], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    ExceptionRaised := False;
    try
      V.Required('config').ValidateAndThrow;
    except
      on E: EArgsValidationException do
        ExceptionRaised := True;
    end;
    CheckTrue(ExceptionRaised, 'ValidateAndThrow should raise on failure');
  finally
    V.Free;
  end;
end;

{ 预定义验证函数测试 }

procedure TTestCase_ArgsValidation.Test_IsValidEmail_Valid;
begin
  CheckTrue(IsValidEmail('user@example.com'));
  CheckTrue(IsValidEmail('test.user+tag@sub.domain.org'));
  CheckTrue(IsValidEmail('a@b.co'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidEmail_Invalid;
begin
  CheckFalse(IsValidEmail('invalid'));
  CheckFalse(IsValidEmail('no@'));
  CheckFalse(IsValidEmail('@domain.com'));
  CheckFalse(IsValidEmail('spaces not@allowed.com'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidUrl_Valid;
begin
  CheckTrue(IsValidUrl('http://example.com'));
  CheckTrue(IsValidUrl('https://example.com'));
  CheckTrue(IsValidUrl('https://sub.domain.com/path'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidUrl_Invalid;
begin
  CheckFalse(IsValidUrl('not-a-url'));
  CheckFalse(IsValidUrl('ftp://wrong-protocol.com'));
  CheckFalse(IsValidUrl(''));
end;

procedure TTestCase_ArgsValidation.Test_IsValidIPAddress_Valid;
begin
  CheckTrue(IsValidIPAddress('192.168.1.1'));
  CheckTrue(IsValidIPAddress('0.0.0.0'));
  CheckTrue(IsValidIPAddress('255.255.255.255'));
  CheckTrue(IsValidIPAddress('10.0.0.1'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidIPAddress_Invalid;
begin
  CheckFalse(IsValidIPAddress('256.1.1.1'));
  CheckFalse(IsValidIPAddress('1.1.1'));
  CheckFalse(IsValidIPAddress('1.1.1.1.1'));
  CheckFalse(IsValidIPAddress('not.an.ip.addr'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidPort_Valid;
begin
  CheckTrue(IsValidPort('1'));
  CheckTrue(IsValidPort('80'));
  CheckTrue(IsValidPort('8080'));
  CheckTrue(IsValidPort('65535'));
end;

procedure TTestCase_ArgsValidation.Test_IsValidPort_Invalid;
begin
  CheckFalse(IsValidPort('0'));
  CheckFalse(IsValidPort('65536'));
  CheckFalse(IsValidPort('-1'));
  CheckFalse(IsValidPort('abc'));
  CheckFalse(IsValidPort(''));
end;

{ 边界测试 }

procedure TTestCase_ArgsValidation.Test_Validator_OptionalKey_Skipped;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  // Optional key not present should pass range validation (skipped)
  Args := TArgs.FromArray(['--other=value'], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    R := V.Range('missing', 1, 100).Validate;
    CheckTrue(R.IsValid, 'Missing optional key should be skipped');
  finally
    V.Free;
  end;
end;

procedure TTestCase_ArgsValidation.Test_Validator_EmptyArgs;
var
  Args: IArgs;
  V: TArgsValidator;
  R: TValidationResult;
begin
  Args := TArgs.FromArray([], ArgsOptionsDefault);
  V := ValidateArgs(Args);
  try
    // With no required rules, empty args should pass
    R := V.Validate;
    CheckTrue(R.IsValid, 'Empty args with no rules should pass');
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ArgsValidation);
end.
