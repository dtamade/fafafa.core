{$CODEPAGE UTF8}
unit fafafa.core.args.validation.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  fafafa.core.args.validation,
  fafafa.core.args.errors;

type
  TTestCase_ArgsValidation = class(TTestCase)
  published
    procedure Test_Required_Success;
    procedure Test_Required_Missing;
    procedure Test_Range_Success;
    procedure Test_Range_OutOfRange;
    procedure Test_MinLength_Success;
    procedure Test_MinLength_TooShort;
    procedure Test_MaxLength_Success;
    procedure Test_MaxLength_TooLong;
    procedure Test_Pattern_Success;
    procedure Test_Pattern_NoMatch;
    procedure Test_Enum_Success;
    procedure Test_Enum_InvalidValue;
    procedure Test_Email_Valid;
    procedure Test_Email_Invalid;
    procedure Test_Url_Valid;
    procedure Test_Url_Invalid;
    procedure Test_IPAddress_Valid;
    procedure Test_IPAddress_Invalid;
    procedure Test_Port_Valid;
    procedure Test_Port_Invalid;
    procedure Test_Custom_Success;
    procedure Test_Custom_Failure;
    procedure Test_MultipleRules_AllValid;
    procedure Test_MultipleRules_SomeInvalid;
    procedure Test_StopOnFirstError_True;
    procedure Test_StopOnFirstError_False;
    procedure Test_ValidationException;
  end;

  TTestCase_ValidationHelpers = class(TTestCase)
  published
    procedure Test_IsValidEmail_Valid;
    procedure Test_IsValidEmail_Invalid;
    procedure Test_IsValidUrl_Valid;
    procedure Test_IsValidUrl_Invalid;
    procedure Test_IsValidIPAddress_Valid;
    procedure Test_IsValidIPAddress_Invalid;
    procedure Test_IsValidPort_Valid;
    procedure Test_IsValidPort_Invalid;
  end;

implementation

// 测试用的自定义验证器
function TestCustomValidator(const Value: string; out ErrorMsg: string): Boolean;
begin
  Result := Value = 'valid';
  if not Result then
    ErrorMsg := 'Value must be "valid"';
end;

{ TTestCase_ArgsValidation }

procedure TTestCase_ArgsValidation.Test_Required_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=test'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Required('name').Validate;
  
  CheckTrue(Result.IsValid);
  CheckEquals(0, Result.ErrorCount);
end;

procedure TTestCase_ArgsValidation.Test_Required_Missing;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--other=value'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Required('name').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(1, Result.ErrorCount);
  CheckEquals(aekRequiredMissing, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Range_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=8080'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Range('port', 1024, 65535).Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Range_OutOfRange;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=80'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Range('port', 1024, 65535).Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_MinLength_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=testname'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).MinLength('name', 5).Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_MinLength_TooShort;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=ab'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).MinLength('name', 5).Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_MaxLength_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=test'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).MaxLength('name', 10).Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_MaxLength_TooLong;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--name=verylongname'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).MaxLength('name', 5).Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Pattern_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--version=1.2.3'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Pattern('version', '^\d+\.\d+\.\d+$').Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Pattern_NoMatch;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--version=invalid'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Pattern('version', '^\d+\.\d+\.\d+$').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Enum_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--format=json'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Enum('format', ['json', 'xml', 'yaml']).Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Enum_InvalidValue;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--format=csv'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Enum('format', ['json', 'xml', 'yaml']).Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Email_Valid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--email=test@example.com'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Email('email').Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Email_Invalid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--email=invalid-email'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Email('email').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Url_Valid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--url=https://example.com'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Url('url').Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Url_Invalid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--url=not-a-url'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Url('url').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_IPAddress_Valid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--ip=192.168.1.1'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).IPAddress('ip').Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_IPAddress_Invalid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--ip=999.999.999.999'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).IPAddress('ip').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Port_Valid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=8080'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Port('port').Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Port_Invalid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=99999'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Port('port').Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_Custom_Success;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--value=valid'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Custom('value', @TestCustomValidator).Validate;
  
  CheckTrue(Result.IsValid);
end;

procedure TTestCase_ArgsValidation.Test_Custom_Failure;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--value=invalid'], ArgsOptionsDefault);
  Result := ValidateArgs(Args).Custom('value', @TestCustomValidator).Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(aekValidationError, Result.GetFirstError.Kind);
end;

procedure TTestCase_ArgsValidation.Test_MultipleRules_AllValid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=8080', '--name=test', '--email=user@example.com'], ArgsOptionsDefault);
  Result := ValidateArgs(Args)
    .Required('port')
    .Range('port', 1024, 65535)
    .Required('name')
    .MinLength('name', 3)
    .Required('email')
    .Email('email')
    .Validate;
  
  CheckTrue(Result.IsValid);
  CheckEquals(0, Result.ErrorCount);
end;

procedure TTestCase_ArgsValidation.Test_MultipleRules_SomeInvalid;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=80', '--name=ab'], ArgsOptionsDefault);
  Result := ValidateArgs(Args)
    .Required('port')
    .Range('port', 1024, 65535)  // 无效
    .Required('name')
    .MinLength('name', 3)        // 无效
    .Required('email')           // 缺失
    .Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(3, Result.ErrorCount);
end;

procedure TTestCase_ArgsValidation.Test_StopOnFirstError_True;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=80', '--name=ab'], ArgsOptionsDefault);
  Result := ValidateArgs(Args)
    .StopOnFirstError(True)
    .Required('port')
    .Range('port', 1024, 65535)  // 第一个错误
    .Required('name')
    .MinLength('name', 3)        // 不会检查
    .Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(1, Result.ErrorCount);  // 只有一个错误
end;

procedure TTestCase_ArgsValidation.Test_StopOnFirstError_False;
var
  Args: IArgs;
  Result: TValidationResult;
begin
  Args := TArgs.FromArray(['--port=80', '--name=ab'], ArgsOptionsDefault);
  Result := ValidateArgs(Args)
    .StopOnFirstError(False)
    .Required('port')
    .Range('port', 1024, 65535)  // 错误1
    .Required('name')
    .MinLength('name', 3)        // 错误2
    .Validate;
  
  CheckFalse(Result.IsValid);
  CheckEquals(2, Result.ErrorCount);  // 两个错误
end;

procedure TTestCase_ArgsValidation.Test_ValidationException;
var
  Args: IArgs;
  ExceptionRaised: Boolean;
begin
  Args := TArgs.FromArray(['--port=80'], ArgsOptionsDefault);
  ExceptionRaised := False;
  
  try
    ValidateArgs(Args)
      .Required('port')
      .Range('port', 1024, 65535)
      .ValidateAndThrow;
  except
    on E: EArgsValidationException do
      ExceptionRaised := True;
  end;
  
  CheckTrue(ExceptionRaised);
end;

{ TTestCase_ValidationHelpers }

procedure TTestCase_ValidationHelpers.Test_IsValidEmail_Valid;
begin
  CheckTrue(IsValidEmail('test@example.com'));
  CheckTrue(IsValidEmail('user.name@domain.co.uk'));
  CheckTrue(IsValidEmail('test+tag@example.org'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidEmail_Invalid;
begin
  CheckFalse(IsValidEmail('invalid-email'));
  CheckFalse(IsValidEmail('@example.com'));
  CheckFalse(IsValidEmail('test@'));
  CheckFalse(IsValidEmail('test.example.com'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidUrl_Valid;
begin
  CheckTrue(IsValidUrl('https://example.com'));
  CheckTrue(IsValidUrl('http://test.org/path'));
  CheckTrue(IsValidUrl('https://sub.domain.com/path/to/resource'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidUrl_Invalid;
begin
  CheckFalse(IsValidUrl('not-a-url'));
  CheckFalse(IsValidUrl('ftp://example.com'));
  CheckFalse(IsValidUrl('example.com'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidIPAddress_Valid;
begin
  CheckTrue(IsValidIPAddress('192.168.1.1'));
  CheckTrue(IsValidIPAddress('10.0.0.1'));
  CheckTrue(IsValidIPAddress('255.255.255.255'));
  CheckTrue(IsValidIPAddress('0.0.0.0'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidIPAddress_Invalid;
begin
  CheckFalse(IsValidIPAddress('999.999.999.999'));
  CheckFalse(IsValidIPAddress('192.168.1'));
  CheckFalse(IsValidIPAddress('192.168.1.1.1'));
  CheckFalse(IsValidIPAddress('not-an-ip'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidPort_Valid;
begin
  CheckTrue(IsValidPort('1'));
  CheckTrue(IsValidPort('80'));
  CheckTrue(IsValidPort('8080'));
  CheckTrue(IsValidPort('65535'));
end;

procedure TTestCase_ValidationHelpers.Test_IsValidPort_Invalid;
begin
  CheckFalse(IsValidPort('0'));
  CheckFalse(IsValidPort('65536'));
  CheckFalse(IsValidPort('99999'));
  CheckFalse(IsValidPort('not-a-port'));
  CheckFalse(IsValidPort('-1'));
end;

initialization
  RegisterTest(TTestCase_ArgsValidation);
  RegisterTest(TTestCase_ValidationHelpers);
end.
