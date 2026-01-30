{$CODEPAGE UTF8}
unit fafafa.core.args.errors.testcase;
{**
 * fafafa.core.args.errors 单元测试
 * 覆盖错误类型、Result API 和验证辅助函数
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.errors,
  fafafa.core.args.base,
  fafafa.core.result;

type
  TTestCase_ArgsErrors = class(TTestCase)
  published
    // TArgsError 工厂方法测试
    procedure Test_Success_Factory;
    procedure Test_UnknownOption_Factory;
    procedure Test_UnknownOption_WithPosition;
    procedure Test_MissingValue_Factory;
    procedure Test_InvalidValue_Factory;
    procedure Test_DuplicateOption_Factory;
    procedure Test_MutuallyExclusive_Factory;
    procedure Test_RequiredMissing_Factory;
    procedure Test_TooManyPositionals_Factory;
    procedure Test_TooFewPositionals_Factory;
    procedure Test_ParseError_Factory;
    procedure Test_ValidationError_Factory;

    // IsSuccess 测试
    procedure Test_IsSuccess_True;
    procedure Test_IsSuccess_False;

    // ToString 测试
    procedure Test_ToString_Simple;
    procedure Test_ToString_EmptyMessage;

    // ToDetailedString 测试
    procedure Test_ToDetailedString_WithPosition;
    procedure Test_ToDetailedString_WithSuggestion;
    procedure Test_ToDetailedString_AllKinds;

    // Result-style safe getters (IArgs overloads)
    procedure Test_ArgsGetValueSafe_IArgs_UnknownOption_ReturnsErr;
    procedure Test_ArgsGetBoolSafe_IArgs_FlagOnly_OkTrue;
    procedure Test_ArgsGetBoolSafe_IArgs_ValueOverridesFlag_OkFalse;
    procedure Test_ArgsGetBoolSafe_IArgs_Invalid_ReturnsErr;
    procedure Test_ArgsGetDoubleSafe_IArgs_Valid_Ok;
    procedure Test_ArgsGetDoubleSafe_IArgs_Invalid_ReturnsErr;

    // ValidateRange 测试
    procedure Test_ValidateRange_InRange;
    procedure Test_ValidateRange_AtMin;
    procedure Test_ValidateRange_AtMax;
    procedure Test_ValidateRange_BelowMin;
    procedure Test_ValidateRange_AboveMax;
    procedure Test_ValidateRange_NegativeRange;

    // ValidatePattern 测试
    procedure Test_ValidatePattern_Match;
    procedure Test_ValidatePattern_NoMatch;
    procedure Test_ValidatePattern_EmptyString;
    procedure Test_ValidatePattern_ComplexRegex;

    // ValidateEnum 测试
    procedure Test_ValidateEnum_ValidValue;
    procedure Test_ValidateEnum_CaseInsensitive;
    procedure Test_ValidateEnum_InvalidValue;
    procedure Test_ValidateEnum_EmptyValue;
    procedure Test_ValidateEnum_SingleOption;

    // TArgsErrorKind 枚举完整性测试
    procedure Test_ErrorKind_AllValues;
  end;

implementation

{ TArgsError 工厂方法测试 }

procedure TTestCase_ArgsErrors.Test_Success_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.Success;

  CheckEquals(Ord(aekSuccess), Ord(Err.Kind), 'Kind should be aekSuccess');
  CheckEquals('', Err.Message, 'Message should be empty');
  CheckEquals('', Err.OptionName, 'OptionName should be empty');
  CheckEquals(-1, Err.Position, 'Position should be -1');
  CheckTrue(Err.IsSuccess, 'IsSuccess should return True');
end;

procedure TTestCase_ArgsErrors.Test_UnknownOption_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.UnknownOption('--verbose');

  CheckEquals(Ord(aekUnknownOption), Ord(Err.Kind));
  CheckEquals('--verbose', Err.OptionName);
  CheckTrue(Pos('Unknown option', Err.Message) > 0, 'Message should contain "Unknown option"');
  CheckTrue(Pos('--verbose', Err.Message) > 0, 'Message should contain option name');
  CheckEquals(-1, Err.Position, 'Default position should be -1');
  CheckTrue(Err.Suggestion <> '', 'Should have a suggestion');
end;

procedure TTestCase_ArgsErrors.Test_UnknownOption_WithPosition;
var
  Err: TArgsError;
begin
  Err := TArgsError.UnknownOption('--foo', 5);

  CheckEquals(5, Err.Position, 'Position should be 5');
  CheckEquals('--foo', Err.OptionName);
end;

procedure TTestCase_ArgsErrors.Test_MissingValue_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.MissingValue('--output');

  CheckEquals(Ord(aekMissingValue), Ord(Err.Kind));
  CheckEquals('--output', Err.OptionName);
  CheckTrue(Pos('requires a value', Err.Message) > 0, 'Message should indicate value required');
  CheckTrue(Err.Suggestion <> '', 'Should have usage suggestion');
end;

procedure TTestCase_ArgsErrors.Test_InvalidValue_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.InvalidValue('--port', 'integer', 'abc', 3);

  CheckEquals(Ord(aekInvalidValue), Ord(Err.Kind));
  CheckEquals('--port', Err.OptionName);
  CheckEquals('integer', Err.ExpectedType);
  CheckEquals('abc', Err.ActualValue);
  CheckEquals(3, Err.Position);
  CheckTrue(Pos('Invalid value', Err.Message) > 0);
  CheckTrue(Pos('integer', Err.Message) > 0);
  CheckTrue(Pos('abc', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_DuplicateOption_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.DuplicateOption('--config', 7);

  CheckEquals(Ord(aekDuplicateOption), Ord(Err.Kind));
  CheckEquals('--config', Err.OptionName);
  CheckEquals(7, Err.Position);
  CheckTrue(Pos('Duplicate', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_MutuallyExclusive_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.MutuallyExclusive('--verbose', '--quiet');

  CheckEquals(Ord(aekMutuallyExclusive), Ord(Err.Kind));
  CheckEquals('--verbose', Err.OptionName);
  CheckEquals('--quiet', Err.ActualValue, 'ActualValue stores second option');
  CheckTrue(Pos('mutually exclusive', Err.Message) > 0);
  CheckTrue(Pos('--verbose', Err.Message) > 0);
  CheckTrue(Pos('--quiet', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_RequiredMissing_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.RequiredMissing('--config');

  CheckEquals(Ord(aekRequiredMissing), Ord(Err.Kind));
  CheckEquals('--config', Err.OptionName);
  CheckTrue(Pos('Required', Err.Message) > 0);
  CheckTrue(Pos('missing', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_TooManyPositionals_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.TooManyPositionals(2, 5);

  CheckEquals(Ord(aekTooManyPositionals), Ord(Err.Kind));
  CheckEquals('2', Err.ExpectedType, 'ExpectedType stores expected count');
  CheckEquals('5', Err.ActualValue, 'ActualValue stores actual count');
  CheckTrue(Pos('Too many positional', Err.Message) > 0);
  CheckTrue(Pos('2', Err.Message) > 0);
  CheckTrue(Pos('5', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_TooFewPositionals_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.TooFewPositionals(3, 1);

  CheckEquals(Ord(aekTooFewPositionals), Ord(Err.Kind));
  CheckEquals('3', Err.ExpectedType);
  CheckEquals('1', Err.ActualValue);
  CheckTrue(Pos('Too few positional', Err.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_ParseError_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.ParseError('Unexpected token', 10);

  CheckEquals(Ord(aekParseError), Ord(Err.Kind));
  CheckEquals('Unexpected token', Err.Message);
  CheckEquals(10, Err.Position);
  CheckEquals('', Err.OptionName, 'OptionName should be empty for ParseError');
end;

procedure TTestCase_ArgsErrors.Test_ValidationError_Factory;
var
  Err: TArgsError;
begin
  Err := TArgsError.ValidationError('--port', 'Port must be between 1 and 65535');

  CheckEquals(Ord(aekValidationError), Ord(Err.Kind));
  CheckEquals('--port', Err.OptionName);
  CheckTrue(Pos('Validation error', Err.Message) > 0);
  CheckTrue(Pos('Port must be between', Err.Message) > 0);
end;

{ IsSuccess 测试 }

procedure TTestCase_ArgsErrors.Test_IsSuccess_True;
var
  Err: TArgsError;
begin
  Err := TArgsError.Success;
  CheckTrue(Err.IsSuccess, 'Success should return IsSuccess=True');
end;

procedure TTestCase_ArgsErrors.Test_IsSuccess_False;
var
  Err: TArgsError;
begin
  Err := TArgsError.UnknownOption('--test');
  CheckFalse(Err.IsSuccess, 'Error should return IsSuccess=False');

  Err := TArgsError.ParseError('test error');
  CheckFalse(Err.IsSuccess, 'ParseError should return IsSuccess=False');
end;

{ ToString 测试 }

procedure TTestCase_ArgsErrors.Test_ToString_Simple;
var
  Err: TArgsError;
begin
  Err := TArgsError.UnknownOption('--foo');
  CheckEquals(Err.Message, Err.ToString, 'ToString should return Message');
end;

procedure TTestCase_ArgsErrors.Test_ToString_EmptyMessage;
var
  Err: TArgsError;
begin
  Err := TArgsError.Success;
  CheckEquals('', Err.ToString, 'Success.ToString should be empty');
end;

{ ToDetailedString 测试 }

procedure TTestCase_ArgsErrors.Test_ToDetailedString_WithPosition;
var
  Err: TArgsError;
  Detail: string;
begin
  Err := TArgsError.UnknownOption('--test', 5);
  Detail := Err.ToDetailedString;

  CheckTrue(Pos('[UNKNOWN_OPTION]', Detail) > 0, 'Should contain error kind');
  CheckTrue(Pos('position: 5', Detail) > 0, 'Should contain position');
end;

procedure TTestCase_ArgsErrors.Test_ToDetailedString_WithSuggestion;
var
  Err: TArgsError;
  Detail: string;
begin
  Err := TArgsError.MissingValue('--output');
  Detail := Err.ToDetailedString;

  CheckTrue(Pos('[MISSING_VALUE]', Detail) > 0, 'Should contain error kind');
  CheckTrue(Pos('Suggestion:', Detail) > 0, 'Should contain suggestion');
end;

procedure TTestCase_ArgsErrors.Test_ToDetailedString_AllKinds;
var
  Err: TArgsError;
  Detail: string;
begin
  // Test each error kind has correct string representation
  Err := TArgsError.Success;
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[SUCCESS]', Detail) > 0, 'Success should show [SUCCESS]');

  Err := TArgsError.InvalidValue('--x', 'int', 'abc');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[INVALID_VALUE]', Detail) > 0, 'InvalidValue should show [INVALID_VALUE]');

  Err := TArgsError.DuplicateOption('--x');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[DUPLICATE_OPTION]', Detail) > 0, 'DuplicateOption should show [DUPLICATE_OPTION]');

  Err := TArgsError.MutuallyExclusive('--a', '--b');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[MUTUALLY_EXCLUSIVE]', Detail) > 0, 'MutuallyExclusive should show [MUTUALLY_EXCLUSIVE]');

  Err := TArgsError.RequiredMissing('--req');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[REQUIRED_MISSING]', Detail) > 0, 'RequiredMissing should show [REQUIRED_MISSING]');

  Err := TArgsError.TooManyPositionals(1, 2);
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[TOO_MANY_POSITIONALS]', Detail) > 0, 'TooManyPositionals should show [TOO_MANY_POSITIONALS]');

  Err := TArgsError.TooFewPositionals(2, 1);
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[TOO_FEW_POSITIONALS]', Detail) > 0, 'TooFewPositionals should show [TOO_FEW_POSITIONALS]');

  Err := TArgsError.ParseError('test');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[PARSE_ERROR]', Detail) > 0, 'ParseError should show [PARSE_ERROR]');

  Err := TArgsError.ValidationError('--x', 'failed');
  Detail := Err.ToDetailedString;
  CheckTrue(Pos('[VALIDATION_ERROR]', Detail) > 0, 'ValidationError should show [VALIDATION_ERROR]');
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetValueSafe_IArgs_UnknownOption_ReturnsErr;
var
  A: IArgs;
  R: TArgsResult;
begin
  A := TArgs.FromArray([], ArgsOptionsDefault);
  R := ArgsGetValueSafe(A, 'missing');
  CheckTrue(R.IsErr);
  CheckEquals(Ord(aekUnknownOption), Ord(R.UnwrapErr.Kind));
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetBoolSafe_IArgs_FlagOnly_OkTrue;
var
  A: IArgs;
  R: TArgsResultBool;
begin
  A := TArgs.FromArray(['--enabled'], ArgsOptionsDefault);
  R := ArgsGetBoolSafe(A, 'enabled');
  CheckTrue(R.IsOk);
  CheckTrue(R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetBoolSafe_IArgs_ValueOverridesFlag_OkFalse;
var
  A: IArgs;
  R: TArgsResultBool;
begin
  A := TArgs.FromArray(['--enabled', '--enabled=false'], ArgsOptionsDefault);
  R := ArgsGetBoolSafe(A, 'enabled');
  CheckTrue(R.IsOk);
  CheckFalse(R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetBoolSafe_IArgs_Invalid_ReturnsErr;
var
  A: IArgs;
  R: TArgsResultBool;
begin
  A := TArgs.FromArray(['--enabled=maybe'], ArgsOptionsDefault);
  R := ArgsGetBoolSafe(A, 'enabled');
  CheckTrue(R.IsErr);
  CheckEquals(Ord(aekInvalidValue), Ord(R.UnwrapErr.Kind));
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetDoubleSafe_IArgs_Valid_Ok;
var
  A: IArgs;
  R: TArgsResultDouble;
begin
  A := TArgs.FromArray(['--pi=3.14'], ArgsOptionsDefault);
  R := ArgsGetDoubleSafe(A, 'pi');
  CheckTrue(R.IsOk);
  CheckEquals(3.14, R.Unwrap, 0.00001);
end;

procedure TTestCase_ArgsErrors.Test_ArgsGetDoubleSafe_IArgs_Invalid_ReturnsErr;
var
  A: IArgs;
  R: TArgsResultDouble;
begin
  A := TArgs.FromArray(['--pi=3,14'], ArgsOptionsDefault);
  R := ArgsGetDoubleSafe(A, 'pi');
  CheckTrue(R.IsErr);
  CheckEquals(Ord(aekInvalidValue), Ord(R.UnwrapErr.Kind));
end;

{ ValidateRange 测试 }

procedure TTestCase_ArgsErrors.Test_ValidateRange_InRange;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(50, 1, 100);
  CheckTrue(R.IsOk, 'Value 50 should be in range [1, 100]');
  CheckEquals(50, R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ValidateRange_AtMin;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(1, 1, 100);
  CheckTrue(R.IsOk, 'Value at min boundary should be valid');
  CheckEquals(1, R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ValidateRange_AtMax;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(100, 1, 100);
  CheckTrue(R.IsOk, 'Value at max boundary should be valid');
  CheckEquals(100, R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ValidateRange_BelowMin;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(0, 1, 100);
  CheckTrue(R.IsErr, 'Value below min should fail');
  CheckTrue(Pos('out of range', R.UnwrapErr.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_ValidateRange_AboveMax;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(101, 1, 100);
  CheckTrue(R.IsErr, 'Value above max should fail');
  CheckTrue(Pos('out of range', R.UnwrapErr.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_ValidateRange_NegativeRange;
var
  R: specialize TResult<Int64, TArgsError>;
begin
  R := ValidateRange(-50, -100, -1);
  CheckTrue(R.IsOk, 'Negative range should work');
  CheckEquals(-50, R.Unwrap);

  R := ValidateRange(0, -100, -1);
  CheckTrue(R.IsErr, '0 should be out of negative range');
end;

{ ValidatePattern 测试 }

procedure TTestCase_ArgsErrors.Test_ValidatePattern_Match;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidatePattern('abc123', '^[a-z]+[0-9]+$');
  CheckTrue(R.IsOk, 'Pattern should match');
  CheckEquals('abc123', R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ValidatePattern_NoMatch;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidatePattern('123abc', '^[a-z]+[0-9]+$');
  CheckTrue(R.IsErr, 'Pattern should not match');
  CheckTrue(Pos('does not match pattern', R.UnwrapErr.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_ValidatePattern_EmptyString;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidatePattern('', '^$'); // Pattern for empty string
  CheckTrue(R.IsOk, 'Empty string should match ^$ pattern');

  R := ValidatePattern('', '.+'); // Pattern requiring at least one char
  CheckTrue(R.IsErr, 'Empty string should not match .+ pattern');
end;

procedure TTestCase_ArgsErrors.Test_ValidatePattern_ComplexRegex;
var
  R: specialize TResult<string, TArgsError>;
begin
  // Email-like pattern
  R := ValidatePattern('user@example.com', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  CheckTrue(R.IsOk, 'Valid email should match');

  R := ValidatePattern('invalid-email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  CheckTrue(R.IsErr, 'Invalid email should not match');
end;

{ ValidateEnum 测试 }

procedure TTestCase_ArgsErrors.Test_ValidateEnum_ValidValue;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidateEnum('debug', ['debug', 'info', 'warn', 'error']);
  CheckTrue(R.IsOk, 'debug should be valid');
  CheckEquals('debug', R.Unwrap);
end;

procedure TTestCase_ArgsErrors.Test_ValidateEnum_CaseInsensitive;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidateEnum('DEBUG', ['debug', 'info', 'warn', 'error']);
  CheckTrue(R.IsOk, 'DEBUG (uppercase) should match debug (case-insensitive)');

  R := ValidateEnum('Info', ['debug', 'info', 'warn', 'error']);
  CheckTrue(R.IsOk, 'Info (mixed case) should match');
end;

procedure TTestCase_ArgsErrors.Test_ValidateEnum_InvalidValue;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidateEnum('trace', ['debug', 'info', 'warn', 'error']);
  CheckTrue(R.IsErr, 'trace should be invalid');
  CheckTrue(Pos('Invalid value', R.UnwrapErr.Message) > 0);
  CheckTrue(Pos('Valid values:', R.UnwrapErr.Message) > 0);
end;

procedure TTestCase_ArgsErrors.Test_ValidateEnum_EmptyValue;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidateEnum('', ['debug', 'info', 'warn', 'error']);
  CheckTrue(R.IsErr, 'Empty string should be invalid');
end;

procedure TTestCase_ArgsErrors.Test_ValidateEnum_SingleOption;
var
  R: specialize TResult<string, TArgsError>;
begin
  R := ValidateEnum('only', ['only']);
  CheckTrue(R.IsOk, 'Single option enum should work');

  R := ValidateEnum('other', ['only']);
  CheckTrue(R.IsErr, 'Non-matching value should fail');
end;

{ TArgsErrorKind 枚举完整性测试 }

procedure TTestCase_ArgsErrors.Test_ErrorKind_AllValues;
begin
  // Verify all enum values are defined and have expected ordinal values
  CheckEquals(0, Ord(aekSuccess), 'aekSuccess should be 0');
  CheckEquals(1, Ord(aekUnknownOption), 'aekUnknownOption should be 1');
  CheckEquals(2, Ord(aekMissingValue), 'aekMissingValue should be 2');
  CheckEquals(3, Ord(aekInvalidValue), 'aekInvalidValue should be 3');
  CheckEquals(4, Ord(aekDuplicateOption), 'aekDuplicateOption should be 4');
  CheckEquals(5, Ord(aekMutuallyExclusive), 'aekMutuallyExclusive should be 5');
  CheckEquals(6, Ord(aekRequiredMissing), 'aekRequiredMissing should be 6');
  CheckEquals(7, Ord(aekTooManyPositionals), 'aekTooManyPositionals should be 7');
  CheckEquals(8, Ord(aekTooFewPositionals), 'aekTooFewPositionals should be 8');
  CheckEquals(9, Ord(aekParseError), 'aekParseError should be 9');
  CheckEquals(10, Ord(aekValidationError), 'aekValidationError should be 10');
end;

initialization
  RegisterTest(TTestCase_ArgsErrors);
end.
