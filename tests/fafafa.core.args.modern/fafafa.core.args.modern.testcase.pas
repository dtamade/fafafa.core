{$CODEPAGE UTF8}
unit fafafa.core.args.modern.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  fafafa.core.args.modern,
  fafafa.core.args.errors,
  fafafa.core.result,
  fafafa.core.option;

type
  TTestCase_ArgsModern = class(TTestCase)
  published
    procedure Test_GetValue_Success;
    procedure Test_GetValue_NotFound;
    procedure Test_GetInt_Success;
    procedure Test_GetInt_InvalidValue;
    procedure Test_GetDouble_Success;
    procedure Test_GetBool_Flag;
    procedure Test_GetBool_Value;
    procedure Test_GetValueOpt_Some;
    procedure Test_GetValueOpt_None;
    procedure Test_GetIntOpt_Some;
    procedure Test_GetIntOpt_None_InvalidValue;
    procedure Test_GetIntRange_Success;
    procedure Test_GetIntRange_OutOfRange;
    procedure Test_GetPattern_Success;
    procedure Test_GetPattern_NoMatch;
    procedure Test_GetEnum_Success;
    procedure Test_GetEnum_InvalidValue;
    procedure Test_Validation_Required_Success;
    procedure Test_Validation_Required_Missing;
    procedure Test_Validation_Range_Success;
    procedure Test_Validation_Range_OutOfRange;
    procedure Test_Validation_MutuallyExclusive_Success;
    procedure Test_Validation_MutuallyExclusive_Conflict;
    procedure Test_Validation_AtLeastOne_Success;
    procedure Test_Validation_AtLeastOne_Missing;
    procedure Test_Validation_PositionalCount_Success;
    procedure Test_Validation_PositionalCount_TooMany;
    procedure Test_LegacyCompatibility;
  end;

implementation

procedure TTestCase_ArgsModern.Test_GetValue_Success;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--name=test'], ArgsOptionsDefault);
  Result := Args.GetValue('name');
  
  CheckTrue(Result.IsOk);
  CheckEquals('test', Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetValue_NotFound;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--other=value'], ArgsOptionsDefault);
  Result := Args.GetValue('name');
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekUnknownOption, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_GetInt_Success;
var
  Args: IArgsModern;
  Result: TArgsResultInt;
begin
  Args := ModernArgsFromArray(['--count=42'], ArgsOptionsDefault);
  Result := Args.GetInt('count');
  
  CheckTrue(Result.IsOk);
  CheckEquals(42, Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetInt_InvalidValue;
var
  Args: IArgsModern;
  Result: TArgsResultInt;
begin
  Args := ModernArgsFromArray(['--count=abc'], ArgsOptionsDefault);
  Result := Args.GetInt('count');
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekInvalidValue, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_GetDouble_Success;
var
  Args: IArgsModern;
  Result: TArgsResultDouble;
begin
  Args := ModernArgsFromArray(['--rate=3.14'], ArgsOptionsDefault);
  Result := Args.GetDouble('rate');
  
  CheckTrue(Result.IsOk);
  CheckEquals(3.14, Result.Unwrap, 0.001);
end;

procedure TTestCase_ArgsModern.Test_GetBool_Flag;
var
  Args: IArgsModern;
  Result: TArgsResultBool;
begin
  Args := ModernArgsFromArray(['--verbose'], ArgsOptionsDefault);
  Result := Args.GetBool('verbose');
  
  CheckTrue(Result.IsOk);
  CheckTrue(Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetBool_Value;
var
  Args: IArgsModern;
  Result: TArgsResultBool;
begin
  Args := ModernArgsFromArray(['--debug=false'], ArgsOptionsDefault);
  Result := Args.GetBool('debug');
  
  CheckTrue(Result.IsOk);
  CheckFalse(Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetValueOpt_Some;
var
  Args: IArgsModern;
  Result: TArgsOptionStr;
begin
  Args := ModernArgsFromArray(['--name=test'], ArgsOptionsDefault);
  Result := Args.GetValueOpt('name');
  
  CheckTrue(Result.IsSome);
  CheckEquals('test', Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetValueOpt_None;
var
  Args: IArgsModern;
  Result: TArgsOptionStr;
begin
  Args := ModernArgsFromArray(['--other=value'], ArgsOptionsDefault);
  Result := Args.GetValueOpt('name');
  
  CheckTrue(Result.IsNone);
end;

procedure TTestCase_ArgsModern.Test_GetIntOpt_Some;
var
  Args: IArgsModern;
  Result: specialize TOption<Int64>;
begin
  Args := ModernArgsFromArray(['--count=42'], ArgsOptionsDefault);
  Result := Args.GetIntOpt('count');
  
  CheckTrue(Result.IsSome);
  CheckEquals(42, Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetIntOpt_None_InvalidValue;
var
  Args: IArgsModern;
  Result: specialize TOption<Int64>;
begin
  Args := ModernArgsFromArray(['--count=abc'], ArgsOptionsDefault);
  Result := Args.GetIntOpt('count');
  
  CheckTrue(Result.IsNone);
end;

procedure TTestCase_ArgsModern.Test_GetIntRange_Success;
var
  Args: IArgsModern;
  Result: TArgsResultInt;
begin
  Args := ModernArgsFromArray(['--port=8080'], ArgsOptionsDefault);
  Result := Args.GetIntRange('port', 1024, 65535);
  
  CheckTrue(Result.IsOk);
  CheckEquals(8080, Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetIntRange_OutOfRange;
var
  Args: IArgsModern;
  Result: TArgsResultInt;
begin
  Args := ModernArgsFromArray(['--port=80'], ArgsOptionsDefault);
  Result := Args.GetIntRange('port', 1024, 65535);
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekValidationError, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_GetPattern_Success;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--email=test@example.com'], ArgsOptionsDefault);
  Result := Args.GetPattern('email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  CheckTrue(Result.IsOk);
  CheckEquals('test@example.com', Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetPattern_NoMatch;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--email=invalid-email'], ArgsOptionsDefault);
  Result := Args.GetPattern('email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekValidationError, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_GetEnum_Success;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--format=json'], ArgsOptionsDefault);
  Result := Args.GetEnum('format', ['json', 'xml', 'yaml']);
  
  CheckTrue(Result.IsOk);
  CheckEquals('json', Result.Unwrap);
end;

procedure TTestCase_ArgsModern.Test_GetEnum_InvalidValue;
var
  Args: IArgsModern;
  Result: TArgsResult;
begin
  Args := ModernArgsFromArray(['--format=csv'], ArgsOptionsDefault);
  Result := Args.GetEnum('format', ['json', 'xml', 'yaml']);
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekValidationError, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_Validation_Required_Success;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--name=test'], ArgsOptionsDefault);
  Result := Args.Validate.Required('name').Check;
  
  CheckTrue(Result.IsOk);
end;

procedure TTestCase_ArgsModern.Test_Validation_Required_Missing;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--other=value'], ArgsOptionsDefault);
  Result := Args.Validate.Required('name').Check;
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekRequiredMissing, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_Validation_Range_Success;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--port=8080'], ArgsOptionsDefault);
  Result := Args.Validate.Range('port', 1024, 65535).Check;
  
  CheckTrue(Result.IsOk);
end;

procedure TTestCase_ArgsModern.Test_Validation_Range_OutOfRange;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--port=80'], ArgsOptionsDefault);
  Result := Args.Validate.Range('port', 1024, 65535).Check;
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekValidationError, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_Validation_MutuallyExclusive_Success;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--quiet'], ArgsOptionsDefault);
  Result := Args.Validate.MutuallyExclusive('quiet', 'verbose').Check;
  
  CheckTrue(Result.IsOk);
end;

procedure TTestCase_ArgsModern.Test_Validation_MutuallyExclusive_Conflict;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--quiet', '--verbose'], ArgsOptionsDefault);
  Result := Args.Validate.MutuallyExclusive('quiet', 'verbose').Check;
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekMutuallyExclusive, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_Validation_AtLeastOne_Success;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--input=file.txt'], ArgsOptionsDefault);
  Result := Args.Validate.AtLeastOne(['input', 'stdin']).Check;
  
  CheckTrue(Result.IsOk);
end;

procedure TTestCase_ArgsModern.Test_Validation_AtLeastOne_Missing;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['--output=file.txt'], ArgsOptionsDefault);
  Result := Args.Validate.AtLeastOne(['input', 'stdin']).Check;
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekRequiredMissing, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_Validation_PositionalCount_Success;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['file1.txt', 'file2.txt'], ArgsOptionsDefault);
  Result := Args.Validate.PositionalCount(1, 3).Check;
  
  CheckTrue(Result.IsOk);
end;

procedure TTestCase_ArgsModern.Test_Validation_PositionalCount_TooMany;
var
  Args: IArgsModern;
  Result: specialize TResult<Boolean, TArgsError>;
begin
  Args := ModernArgsFromArray(['file1.txt', 'file2.txt', 'file3.txt', 'file4.txt'], ArgsOptionsDefault);
  Result := Args.Validate.PositionalCount(1, 3).Check;
  
  CheckTrue(Result.IsErr);
  CheckEquals(aekTooManyPositionals, Result.UnwrapErr.Kind);
end;

procedure TTestCase_ArgsModern.Test_LegacyCompatibility;
var
  ModernArgs: IArgsModern;
  LegacyArgs: IArgs;
  Value: string;
begin
  ModernArgs := ModernArgsFromArray(['--config=app.conf', '--debug'], ArgsOptionsDefault);
  LegacyArgs := ModernArgs.AsLegacy;
  
  CheckTrue(LegacyArgs.TryGetValue('config', Value));
  CheckEquals('app.conf', Value);
  CheckTrue(LegacyArgs.HasFlag('debug'));
end;

initialization
  RegisterTest(TTestCase_ArgsModern);
end.
