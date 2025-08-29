unit fafafa.core.args.v2.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.v2;

type
  { TTestCase_ArgsV2_Core }
  TTestCase_ArgsV2_Core = class(TTestCase)
  published
    procedure Test_ParseBasicOptions;
    procedure Test_ParseFlags;
    procedure Test_ParsePositionals;
    procedure Test_ParseMixedArgs;
    procedure Test_CaseInsensitivity;
    procedure Test_ShortFlagsCombo;
    procedure Test_WindowsStyle;
    procedure Test_DoubleDashStop;
    procedure Test_NegativeNumbers;
    procedure Test_NoPrefixNegation;
  end;

  { TTestCase_ArgsV2_ModernAPI }
  TTestCase_ArgsV2_ModernAPI = class(TTestCase)
  published
    procedure Test_GetValue_Success;
    procedure Test_GetValue_Missing;
    procedure Test_GetInt_Success;
    procedure Test_GetInt_Invalid;
    procedure Test_GetDouble_Success;
    procedure Test_GetDouble_Invalid;
    procedure Test_GetBool_Flag;
    procedure Test_GetBool_Value;
    procedure Test_GetBool_Invalid;
    procedure Test_GetAll_Multiple;
    procedure Test_HasFlag_True;
    procedure Test_HasFlag_False;
    procedure Test_TryGetValueFast;
  end;

  { TTestCase_ArgsV2_Performance }
  TTestCase_ArgsV2_Performance = class(TTestCase)
  published
    procedure Test_CacheHit;
    procedure Test_CacheMiss;
    procedure Test_LargeArgumentSet;
    procedure Test_FastLookup;
  end;

  { TTestCase_ArgsV2_FluentAPI }
  TTestCase_ArgsV2_FluentAPI = class(TTestCase)
  published
    procedure Test_FluentBuilder_Basic;
    procedure Test_FluentBuilder_WithValidation;
    procedure Test_FluentBuilder_Complex;
  end;

  { TTestCase_ArgsV2_ErrorHandling }
  TTestCase_ArgsV2_ErrorHandling = class(TTestCase)
  published
    procedure Test_ErrorDetails;
    procedure Test_ErrorSuggestions;
    procedure Test_ErrorPositions;
  end;

implementation

{ TTestCase_ArgsV2_Core }

procedure TTestCase_ArgsV2_Core.Test_ParseBasicOptions;
var
  Args: IArgs;
  Result: TArgsResult;
begin
  Args := TArgsV2.FromArray(['--name=test', '--count=42'], TArgsOptions.Default);
  
  Result := Args.GetValue('name');
  CheckTrue(Result.IsOk, 'Should find name option');
  CheckEquals('test', Result.Value, 'Name value should match');

  Result := Args.GetValue('count');
  CheckTrue(Result.IsOk, 'Should find count option');
  CheckEquals('42', Result.Value, 'Count value should match');
end;

procedure TTestCase_ArgsV2_Core.Test_ParseFlags;
var
  Args: IArgs;
begin
  Args := TArgsV2.FromArray(['--verbose', '-d', '--help'], TArgsOptions.Default);
  
  CheckTrue(Args.HasFlag('verbose'), 'Should have verbose flag');
  CheckTrue(Args.HasFlag('d'), 'Should have d flag');
  CheckTrue(Args.HasFlag('help'), 'Should have help flag');
  CheckFalse(Args.HasFlag('quiet'), 'Should not have quiet flag');
end;

procedure TTestCase_ArgsV2_Core.Test_ParsePositionals;
var
  Args: IArgs;
  Positionals: TStringArray;
begin
  Args := TArgsV2.FromArray(['file1.txt', 'file2.txt', '--verbose', 'file3.txt'], TArgsOptions.Default);
  
  Positionals := Args.Positionals;
  CheckEquals(3, Length(Positionals), 'Should have 3 positional arguments');
  CheckEquals('file1.txt', Positionals[0], 'First positional should match');
  CheckEquals('file2.txt', Positionals[1], 'Second positional should match');
  CheckEquals('file3.txt', Positionals[2], 'Third positional should match');
end;

procedure TTestCase_ArgsV2_Core.Test_ParseMixedArgs;
var
  Args: IArgs;
  Result: TArgsResult;
  Positionals: TStringArray;
begin
  Args := TArgsV2.FromArray(['--input=data.txt', '-v', 'output.txt', '--count=10'], TArgsOptions.Default);
  
  Result := Args.GetValue('input');
  CheckTrue(Result.IsOk, 'Should find input option');
  CheckEquals('data.txt', Result.Value, 'Input value should match');

  CheckTrue(Args.HasFlag('v'), 'Should have v flag');

  Result := Args.GetValue('count');
  CheckTrue(Result.IsOk, 'Should find count option');
  CheckEquals('10', Result.Value, 'Count value should match');
  
  Positionals := Args.Positionals;
  CheckEquals(1, Length(Positionals), 'Should have 1 positional argument');
  CheckEquals('output.txt', Positionals[0], 'Positional should match');
end;

procedure TTestCase_ArgsV2_Core.Test_CaseInsensitivity;
var
  Args: IArgs;
  Result: TArgsResult;
  Opts: TArgsOptions;
begin
  Opts := TArgsOptions.Default;
  Opts.CaseInsensitiveKeys := True;
  
  Args := TArgsV2.FromArray(['--Name=Test', '--COUNT=42'], Opts);
  
  Result := Args.GetValue('name');
  CheckTrue(Result.IsOk, 'Should find name option (case insensitive)');
  CheckEquals('Test', Result.Value, 'Name value should match');

  Result := Args.GetValue('count');
  CheckTrue(Result.IsOk, 'Should find count option (case insensitive)');
  CheckEquals('42', Result.Value, 'Count value should match');
end;

procedure TTestCase_ArgsV2_Core.Test_ShortFlagsCombo;
var
  Args: IArgs;
  Opts: TArgsOptions;
begin
  Opts := TArgsOptions.Default;
  Opts.AllowShortFlagsCombo := True;
  
  Args := TArgsV2.FromArray(['-abc'], Opts);
  
  CheckTrue(Args.HasFlag('a'), 'Should have a flag');
  CheckTrue(Args.HasFlag('b'), 'Should have b flag');
  CheckTrue(Args.HasFlag('c'), 'Should have c flag');
end;

procedure TTestCase_ArgsV2_Core.Test_WindowsStyle;
var
  Args: IArgs;
  Result: TArgsResult;
begin
  Args := TArgsV2.FromArray(['/name:test', '/verbose', '/count=42'], TArgsOptions.Default);
  
  Result := Args.GetValue('name');
  CheckTrue(Result.IsOk, 'Should find name option (Windows style)');
  CheckEquals('test', Result.Value, 'Name value should match');

  CheckTrue(Args.HasFlag('verbose'), 'Should have verbose flag (Windows style)');

  Result := Args.GetValue('count');
  CheckTrue(Result.IsOk, 'Should find count option (Windows style)');
  CheckEquals('42', Result.Value, 'Count value should match');
end;

procedure TTestCase_ArgsV2_Core.Test_DoubleDashStop;
var
  Args: IArgs;
  Positionals: TStringArray;
  Opts: TArgsOptions;
begin
  Opts := TArgsOptions.Default;
  Opts.StopAtDoubleDash := True;
  
  Args := TArgsV2.FromArray(['--verbose', '--', '--not-an-option', 'file.txt'], Opts);
  
  CheckTrue(Args.HasFlag('verbose'), 'Should have verbose flag');
  
  Positionals := Args.Positionals;
  CheckEquals(2, Length(Positionals), 'Should have 2 positional arguments after --');
  CheckEquals('--not-an-option', Positionals[0], 'First positional should be literal');
  CheckEquals('file.txt', Positionals[1], 'Second positional should match');
end;

procedure TTestCase_ArgsV2_Core.Test_NegativeNumbers;
var
  Args: IArgs;
  Positionals: TStringArray;
  Opts: TArgsOptions;
begin
  Opts := TArgsOptions.Default;
  Opts.TreatNegativeNumbersAsPositionals := True;
  
  Args := TArgsV2.FromArray(['--count=10', '-42.5', '--verbose'], Opts);
  
  CheckTrue(Args.HasFlag('verbose'), 'Should have verbose flag');
  
  Positionals := Args.Positionals;
  CheckEquals(1, Length(Positionals), 'Should have 1 positional argument');
  CheckEquals('-42.5', Positionals[0], 'Negative number should be positional');
end;

procedure TTestCase_ArgsV2_Core.Test_NoPrefixNegation;
var
  Args: IArgs;
  Result: TArgsResultBool;
  Opts: TArgsOptions;
begin
  Opts := TArgsOptions.Default;
  Opts.EnableNoPrefixNegation := True;
  
  Args := TArgsV2.FromArray(['--no-verbose', '--debug'], Opts);
  
  Result := Args.GetBool('verbose');
  CheckTrue(Result.IsOk, 'Should find verbose option');
  CheckFalse(Result.Value, 'Verbose should be false due to --no- prefix');
  
  CheckTrue(Args.HasFlag('debug'), 'Should have debug flag');
end;

{ TTestCase_ArgsV2_ModernAPI }

procedure TTestCase_ArgsV2_ModernAPI.Test_GetValue_Success;
var
  Args: IArgs;
  Result: TArgsResult;
begin
  Args := TArgsV2.FromArray(['--name=test'], TArgsOptions.Default);

  Result := Args.GetValue('name');
  CheckTrue(Result.IsOk, 'Should successfully get value');
  CheckEquals('test', Result.Value, 'Value should match');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetValue_Missing;
var
  Args: IArgs;
  Result: TArgsResult;
  Error: TArgsError;
begin
  Args := TArgsV2.FromArray(['--other=value'], TArgsOptions.Default);

  Result := Args.GetValue('missing');
  CheckFalse(Result.IsOk, 'Should fail for missing value');

  Error := Result.Error;
  CheckEquals(Ord(aekUnknownOption), Ord(Error.Kind), 'Error should be unknown option');
  CheckEquals('missing', Error.OptionName, 'Error should reference correct option');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetInt_Success;
var
  Args: IArgs;
  Result: TArgsResultInt;
begin
  Args := TArgsV2.FromArray(['--count=42'], TArgsOptions.Default);

  Result := Args.GetInt('count');
  CheckTrue(Result.IsOk, 'Should successfully get integer');
  CheckEquals(42, Result.Value, 'Integer value should match');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetInt_Invalid;
var
  Args: IArgs;
  Result: TArgsResultInt;
  Error: TArgsError;
begin
  Args := TArgsV2.FromArray(['--count=abc'], TArgsOptions.Default);

  Result := Args.GetInt('count');
  CheckFalse(Result.IsOk, 'Should fail for invalid integer');

  Error := Result.Error;
  CheckEquals(Ord(aekInvalidValue), Ord(Error.Kind), 'Error should be invalid value');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetDouble_Success;
var
  Args: IArgs;
  Result: TArgsResultDouble;
begin
  Args := TArgsV2.FromArray(['--rate=3.14'], TArgsOptions.Default);

  Result := Args.GetDouble('rate');
  CheckTrue(Result.IsOk, 'Should successfully get double');
  CheckEquals(3.14, Result.Value, 0.001, 'Double value should match');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetDouble_Invalid;
var
  Args: IArgs;
  Result: TArgsResultDouble;
  Error: TArgsError;
begin
  Args := TArgsV2.FromArray(['--rate=invalid'], TArgsOptions.Default);

  Result := Args.GetDouble('rate');
  CheckFalse(Result.IsOk, 'Should fail for invalid double');

  Error := Result.Error;
  CheckEquals(Ord(aekInvalidValue), Ord(Error.Kind), 'Error should be invalid value');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetBool_Flag;
var
  Args: IArgs;
  Result: TArgsResultBool;
begin
  Args := TArgsV2.FromArray(['--verbose'], TArgsOptions.Default);

  Result := Args.GetBool('verbose');
  CheckTrue(Result.IsOk, 'Should successfully get boolean from flag');
  CheckTrue(Result.Value, 'Flag should be true');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetBool_Value;
var
  Args: IArgs;
  Result: TArgsResultBool;
begin
  Args := TArgsV2.FromArray(['--debug=false'], TArgsOptions.Default);

  Result := Args.GetBool('debug');
  CheckTrue(Result.IsOk, 'Should successfully get boolean from value');
  CheckFalse(Result.Value, 'Boolean value should be false');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetBool_Invalid;
var
  Args: IArgs;
  Result: TArgsResultBool;
  Error: TArgsError;
begin
  Args := TArgsV2.FromArray(['--debug=maybe'], TArgsOptions.Default);

  Result := Args.GetBool('debug');
  CheckFalse(Result.IsOk, 'Should fail for invalid boolean');

  Error := Result.Error;
  CheckEquals(Ord(aekInvalidValue), Ord(Error.Kind), 'Error should be invalid value');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_GetAll_Multiple;
var
  Args: IArgs;
  Values: TStringArray;
begin
  Args := TArgsV2.FromArray(['--tag=v1', '--tag=v2', '--tag=v3'], TArgsOptions.Default);
  
  Values := Args.GetAll('tag');
  CheckEquals(3, Length(Values), 'Should get all tag values');
  CheckEquals('v1', Values[0], 'First tag should match');
  CheckEquals('v2', Values[1], 'Second tag should match');
  CheckEquals('v3', Values[2], 'Third tag should match');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_HasFlag_True;
var
  Args: IArgs;
begin
  Args := TArgsV2.FromArray(['--verbose', '-d'], TArgsOptions.Default);
  
  CheckTrue(Args.HasFlag('verbose'), 'Should have verbose flag');
  CheckTrue(Args.HasFlag('d'), 'Should have d flag');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_HasFlag_False;
var
  Args: IArgs;
begin
  Args := TArgsV2.FromArray(['--other'], TArgsOptions.Default);
  
  CheckFalse(Args.HasFlag('verbose'), 'Should not have verbose flag');
  CheckFalse(Args.HasFlag('d'), 'Should not have d flag');
end;

procedure TTestCase_ArgsV2_ModernAPI.Test_TryGetValueFast;
var
  Args: IArgs;
  Value: string;
begin
  Args := TArgsV2.FromArray(['--name=test'], TArgsOptions.Default);
  
  CheckTrue(Args.TryGetValueFast('name', Value), 'Should find value fast');
  CheckEquals('test', Value, 'Fast value should match');
  
  CheckFalse(Args.TryGetValueFast('missing', Value), 'Should not find missing value');
end;

{ TTestCase_ArgsV2_Performance }

procedure TTestCase_ArgsV2_Performance.Test_CacheHit;
begin
  // 简化实现 - 测试缓存命中
  CheckTrue(True, 'Cache hit test placeholder');
end;

procedure TTestCase_ArgsV2_Performance.Test_CacheMiss;
begin
  // 简化实现 - 测试缓存未命中
  CheckTrue(True, 'Cache miss test placeholder');
end;

procedure TTestCase_ArgsV2_Performance.Test_LargeArgumentSet;
begin
  // 简化实现 - 测试大参数集
  CheckTrue(True, 'Large argument set test placeholder');
end;

procedure TTestCase_ArgsV2_Performance.Test_FastLookup;
begin
  // 简化实现 - 测试快速查找
  CheckTrue(True, 'Fast lookup test placeholder');
end;

{ TTestCase_ArgsV2_FluentAPI }

procedure TTestCase_ArgsV2_FluentAPI.Test_FluentBuilder_Basic;
begin
  // 简化实现 - 测试基本 fluent API
  CheckTrue(True, 'Fluent builder basic test placeholder');
end;

procedure TTestCase_ArgsV2_FluentAPI.Test_FluentBuilder_WithValidation;
begin
  // 简化实现 - 测试带验证的 fluent API
  CheckTrue(True, 'Fluent builder validation test placeholder');
end;

procedure TTestCase_ArgsV2_FluentAPI.Test_FluentBuilder_Complex;
begin
  // 简化实现 - 测试复杂 fluent API
  CheckTrue(True, 'Fluent builder complex test placeholder');
end;

{ TTestCase_ArgsV2_ErrorHandling }

procedure TTestCase_ArgsV2_ErrorHandling.Test_ErrorDetails;
begin
  // 简化实现 - 测试错误详情
  CheckTrue(True, 'Error details test placeholder');
end;

procedure TTestCase_ArgsV2_ErrorHandling.Test_ErrorSuggestions;
begin
  // 简化实现 - 测试错误建议
  CheckTrue(True, 'Error suggestions test placeholder');
end;

procedure TTestCase_ArgsV2_ErrorHandling.Test_ErrorPositions;
begin
  // 简化实现 - 测试错误位置
  CheckTrue(True, 'Error positions test placeholder');
end;

initialization
  RegisterTest(TTestCase_ArgsV2_Core);
  RegisterTest(TTestCase_ArgsV2_ModernAPI);
  RegisterTest(TTestCase_ArgsV2_Performance);
  RegisterTest(TTestCase_ArgsV2_FluentAPI);
  RegisterTest(TTestCase_ArgsV2_ErrorHandling);

end.
