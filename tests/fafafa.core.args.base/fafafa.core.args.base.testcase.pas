{$CODEPAGE UTF8}
unit fafafa.core.args.base.testcase;
{**
 * fafafa.core.args.base 单元测试
 * 覆盖核心解析功能
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.base,
  fafafa.core.option.base,
  fafafa.core.option;

type
  TTestCase_ArgsBase = class(TTestCase)
  published
    // 长选项测试
    procedure Test_LongOption_EqualsSeparator;
    procedure Test_LongOption_ColonSeparator;
    procedure Test_LongOption_SpaceSeparator;
    procedure Test_LongOption_FlagOnly;

    // 短选项测试
    procedure Test_ShortOption_EqualsSeparator;
    procedure Test_ShortOption_SpaceSeparator;
    procedure Test_ShortOption_ComboFlags;
    procedure Test_ShortOption_SingleFlag;

    // 斜杠选项测试 (Windows 风格)
    procedure Test_SlashOption_EqualsSeparator;
    procedure Test_SlashOption_ColonSeparator;
    procedure Test_SlashOption_FlagOnly;

    // 双破折号停止解析
    procedure Test_DoubleDash_StopsParsing;

    // 负数作为位置参数
    procedure Test_NegativeNumber_AsPositional;

    // --no- 否定前缀
    procedure Test_NoPrefixNegation;

    // 大小写不敏感
    procedure Test_CaseInsensitive;

    // 位置参数
    procedure Test_Positionals;

    // 边界测试
    procedure Test_EmptyArgs;
    procedure Test_OnlyDoubleDash;
    procedure Test_SpecialCharacters;

    // TArgs 类测试
    procedure Test_TArgs_FromArray;
    procedure Test_TArgs_HasFlag;
    procedure Test_TArgs_TryGetValue;
    procedure Test_TArgs_GetOpt;
    procedure Test_TArgs_GetIntOpt;
    procedure Test_TArgs_GetBoolOpt;
    procedure Test_TArgs_GetDoubleOpt;

    // Try 风格 API
    procedure Test_TArgs_TryGetInt64;
    procedure Test_TArgs_TryGetDouble;
    procedure Test_TArgs_TryGetBool;

    // Default 风格 API
    procedure Test_TArgs_GetStringDefault;
    procedure Test_TArgs_GetInt64Default;
    procedure Test_TArgs_GetDoubleDefault;
    procedure Test_TArgs_GetBoolDefault;

    // GetAll 多值测试
    procedure Test_TArgs_GetAll;
    procedure Test_TArgs_GetAll_Empty;

    // Items 迭代测试
    procedure Test_TArgsContext_ItemsCount;
    procedure Test_TArgsContext_ItemAt;

    // 迭代器测试
    procedure Test_TArgs_Enumerator;

    // 浮点数区域设置无关性
    procedure Test_Float_LocaleInvariant;

    // 键规范化测试
    procedure Test_KeyNormalization_Underscore;
    procedure Test_KeyNormalization_Hyphen;
  end;

implementation

{ 长选项测试 }

procedure TTestCase_ArgsBase.Test_LongOption_EqualsSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--key=value', '--name=test'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Keys), 'Should have 2 keys');
  CheckEquals('key', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
  CheckEquals('name', Ctx.Keys[1]);
  CheckEquals('test', Ctx.Values[1]);
end;

procedure TTestCase_ArgsBase.Test_LongOption_ColonSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--key:value'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('key', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_LongOption_SpaceSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--key', 'value'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('key', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_LongOption_FlagOnly;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--verbose', '--debug'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Flags));
  CheckEquals('verbose', Ctx.Flags[0]);
  CheckEquals('debug', Ctx.Flags[1]);
  CheckEquals(0, Length(Ctx.Keys));
end;

{ 短选项测试 }

procedure TTestCase_ArgsBase.Test_ShortOption_EqualsSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['-k=value'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('k', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_ShortOption_SpaceSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['-o', 'output.txt'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('o', Ctx.Keys[0]);
  CheckEquals('output.txt', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_ShortOption_ComboFlags;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  Opts.AllowShortFlagsCombo := True;
  ParseArgs(['-abc'], Opts, Ctx);

  CheckEquals(3, Length(Ctx.Flags), 'Should expand -abc to 3 flags');
  CheckEquals('a', Ctx.Flags[0]);
  CheckEquals('b', Ctx.Flags[1]);
  CheckEquals('c', Ctx.Flags[2]);
end;

procedure TTestCase_ArgsBase.Test_ShortOption_SingleFlag;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['-v', '-h'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Flags));
  CheckEquals('v', Ctx.Flags[0]);
  CheckEquals('h', Ctx.Flags[1]);
end;

{ 斜杠选项测试 }

procedure TTestCase_ArgsBase.Test_SlashOption_EqualsSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['/key=value'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('key', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_SlashOption_ColonSeparator;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['/key:value'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys));
  CheckEquals('key', Ctx.Keys[0]);
  CheckEquals('value', Ctx.Values[0]);
end;

procedure TTestCase_ArgsBase.Test_SlashOption_FlagOnly;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['/help', '/verbose'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Flags));
  CheckEquals('help', Ctx.Flags[0]);
  CheckEquals('verbose', Ctx.Flags[1]);
end;

{ 双破折号测试 }

procedure TTestCase_ArgsBase.Test_DoubleDash_StopsParsing;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  Opts.StopAtDoubleDash := True;
  ParseArgs(['--verbose', '--', '--not-an-option', 'positional'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Flags), 'Should have 1 flag before --');
  CheckEquals('verbose', Ctx.Flags[0]);
  CheckEquals(2, Length(Ctx.Positionals), 'Should have 2 positionals after --');
  CheckEquals('--not-an-option', Ctx.Positionals[0]);
  CheckEquals('positional', Ctx.Positionals[1]);
end;

{ 负数测试 }

procedure TTestCase_ArgsBase.Test_NegativeNumber_AsPositional;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  // TreatNegativeNumbersAsPositionals 使 -1.5 被识别为值而非短选项
  // 但独立的 -2 仍会被解析为短选项
  Opts := ArgsOptionsDefault;
  Opts.TreatNegativeNumbersAsPositionals := True;
  ParseArgs(['--value', '-1.5', '--', '-2', 'arg'], Opts, Ctx);

  CheckEquals(1, Length(Ctx.Keys), 'Should have 1 key (value=-1.5)');
  CheckEquals('value', Ctx.Keys[0]);
  CheckEquals('-1.5', Ctx.Values[0], 'Negative number should be value');
  CheckEquals(2, Length(Ctx.Positionals), '-2 and arg after -- as positionals');
  CheckEquals('-2', Ctx.Positionals[0]);
  CheckEquals('arg', Ctx.Positionals[1]);
end;

{ --no- 否定前缀测试 }

procedure TTestCase_ArgsBase.Test_NoPrefixNegation;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  Opts.EnableNoPrefixNegation := True;
  ParseArgs(['--no-cache', '--no-verify'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Keys), 'Should have 2 keys from negation');
  CheckEquals('cache', Ctx.Keys[0]);
  CheckEquals('false', Ctx.Values[0]);
  CheckEquals('verify', Ctx.Keys[1]);
  CheckEquals('false', Ctx.Values[1]);
end;

{ 大小写不敏感测试 }

procedure TTestCase_ArgsBase.Test_CaseInsensitive;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
  Args: TArgs;
begin
  Opts := ArgsOptionsDefault;
  Opts.CaseInsensitiveKeys := True;
  Args := TArgs.FromArray(['--Verbose', '--OUTPUT=Test'], Opts);
  try
    CheckTrue(Args.HasFlag('verbose'), 'Should match verbose (lowercase)');
    CheckTrue(Args.HasFlag('VERBOSE'), 'Should match VERBOSE (uppercase)');
    CheckEquals('Test', Args.GetStringDefault('output', ''));
    CheckEquals('Test', Args.GetStringDefault('OUTPUT', ''));
  finally
    Args.Free;
  end;
end;

{ 位置参数测试 }

procedure TTestCase_ArgsBase.Test_Positionals;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  // 注意：--verbose 后的 file2.txt 会被解析为 verbose 的值
  // 若要保持位置参数，需使用 -- 或确保选项后无非选项参数
  Opts := ArgsOptionsDefault;
  ParseArgs(['file1.txt', '--verbose', '--', 'file2.txt'], Opts, Ctx);

  CheckEquals(2, Length(Ctx.Positionals));
  CheckEquals('file1.txt', Ctx.Positionals[0]);
  CheckEquals('file2.txt', Ctx.Positionals[1]);
  CheckEquals(1, Length(Ctx.Flags), 'verbose should be a flag');
  CheckEquals('verbose', Ctx.Flags[0]);
end;

{ 边界测试 }

procedure TTestCase_ArgsBase.Test_EmptyArgs;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs([], Opts, Ctx);

  CheckEquals(0, Length(Ctx.Flags));
  CheckEquals(0, Length(Ctx.Keys));
  CheckEquals(0, Length(Ctx.Positionals));
end;

procedure TTestCase_ArgsBase.Test_OnlyDoubleDash;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--'], Opts, Ctx);

  CheckEquals(0, Length(Ctx.Flags));
  CheckEquals(0, Length(Ctx.Keys));
  CheckEquals(0, Length(Ctx.Positionals));
end;

procedure TTestCase_ArgsBase.Test_SpecialCharacters;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--path=/usr/local/bin', '--message=Hello World!', '--empty='], Opts, Ctx);

  CheckEquals(3, Length(Ctx.Keys));
  CheckEquals('/usr/local/bin', Ctx.Values[0]);
  CheckEquals('Hello World!', Ctx.Values[1]);
  CheckEquals('', Ctx.Values[2], 'Empty value should be preserved');
end;

{ TArgs 类测试 }

procedure TTestCase_ArgsBase.Test_TArgs_FromArray;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--verbose', '-o', 'out.txt', 'input.txt'], ArgsOptionsDefault);
  try
    CheckEquals(3, Args.Count);
    CheckEquals(1, Length(Args.Positionals));
    CheckEquals('input.txt', Args.Positionals[0]);
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_HasFlag;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--verbose', '-v', '--debug'], ArgsOptionsDefault);
  try
    CheckTrue(Args.HasFlag('verbose'));
    CheckTrue(Args.HasFlag('v'));
    CheckTrue(Args.HasFlag('debug'));
    CheckFalse(Args.HasFlag('quiet'));
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_TryGetValue;
var
  Args: TArgs;
  Value: string;
begin
  Args := TArgs.FromArray(['--name=test', '--count=42'], ArgsOptionsDefault);
  try
    CheckTrue(Args.TryGetValue('name', Value));
    CheckEquals('test', Value);
    CheckTrue(Args.TryGetValue('count', Value));
    CheckEquals('42', Value);
    CheckFalse(Args.TryGetValue('missing', Value));
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetOpt;
var
  Args: TArgs;
  Opt: specialize TOption<string>;
begin
  Args := TArgs.FromArray(['--name=test'], ArgsOptionsDefault);
  try
    Opt := Args.GetOpt('name');
    CheckTrue(Opt.IsSome);
    CheckEquals('test', Opt.Unwrap);

    Opt := Args.GetOpt('missing');
    CheckTrue(Opt.IsNone);
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetIntOpt;
var
  Args: TArgs;
  Opt: specialize TOption<Int64>;
begin
  Args := TArgs.FromArray(['--count=42', '--invalid=abc'], ArgsOptionsDefault);
  try
    Opt := Args.GetInt64Opt('count');
    CheckTrue(Opt.IsSome);
    CheckEquals(42, Opt.Unwrap);

    Opt := Args.GetInt64Opt('invalid');
    CheckTrue(Opt.IsNone, 'Invalid int should return None');

    Opt := Args.GetInt64Opt('missing');
    CheckTrue(Opt.IsNone);
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetBoolOpt;
var
  Args: TArgs;
  Opt: specialize TOption<Boolean>;
begin
  Args := TArgs.FromArray(['--enabled=true', '--disabled=false', '--yes=1', '--no=0'], ArgsOptionsDefault);
  try
    Opt := Args.GetBoolOpt('enabled');
    CheckTrue(Opt.IsSome);
    CheckTrue(Opt.Unwrap);

    Opt := Args.GetBoolOpt('disabled');
    CheckTrue(Opt.IsSome);
    CheckFalse(Opt.Unwrap);

    Opt := Args.GetBoolOpt('yes');
    CheckTrue(Opt.IsSome);
    CheckTrue(Opt.Unwrap);

    Opt := Args.GetBoolOpt('no');
    CheckTrue(Opt.IsSome);
    CheckFalse(Opt.Unwrap);
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetDoubleOpt;
var
  Args: TArgs;
  Opt: specialize TOption<Double>;
begin
  Args := TArgs.FromArray(['--pi=3.14159', '--rate=0.5', '--invalid=abc'], ArgsOptionsDefault);
  try
    Opt := Args.GetDoubleOpt('pi');
    CheckTrue(Opt.IsSome);
    CheckEquals(3.14159, Opt.Unwrap, 0.00001);

    Opt := Args.GetDoubleOpt('rate');
    CheckTrue(Opt.IsSome);
    CheckEquals(0.5, Opt.Unwrap, 0.00001);

    Opt := Args.GetDoubleOpt('invalid');
    CheckTrue(Opt.IsNone, 'Invalid double should return None');

    Opt := Args.GetDoubleOpt('missing');
    CheckTrue(Opt.IsNone);
  finally
    Args.Free;
  end;
end;

{ Try 风格 API 测试 }

procedure TTestCase_ArgsBase.Test_TArgs_TryGetInt64;
var
  Args: TArgs;
  V: Int64;
begin
  Args := TArgs.FromArray(['--count=123', '--large=9223372036854775807', '--invalid=abc'], ArgsOptionsDefault);
  try
    CheckTrue(Args.TryGetInt64('count', V));
    CheckEquals(123, V);

    CheckTrue(Args.TryGetInt64('large', V));
    CheckEquals(High(Int64), V, 'Should handle Int64 max');

    CheckFalse(Args.TryGetInt64('invalid', V), 'Non-numeric should return False');
    CheckFalse(Args.TryGetInt64('missing', V), 'Missing key should return False');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_TryGetDouble;
var
  Args: TArgs;
  V: Double;
begin
  Args := TArgs.FromArray(['--pi=3.14159', '--neg=-1.5', '--invalid=abc'], ArgsOptionsDefault);
  try
    CheckTrue(Args.TryGetDouble('pi', V));
    CheckEquals(3.14159, V, 0.00001);

    CheckTrue(Args.TryGetDouble('neg', V));
    CheckEquals(-1.5, V, 0.00001);

    CheckFalse(Args.TryGetDouble('invalid', V), 'Non-numeric should return False');
    CheckFalse(Args.TryGetDouble('missing', V), 'Missing key should return False');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_TryGetBool;
var
  Args: TArgs;
  V: Boolean;
begin
  Args := TArgs.FromArray(['--t1=true', '--t2=yes', '--t3=1', '--f1=false', '--f2=no', '--f3=0', '--invalid=maybe'], ArgsOptionsDefault);
  try
    // True 值
    CheckTrue(Args.TryGetBool('t1', V));
    CheckTrue(V);
    CheckTrue(Args.TryGetBool('t2', V));
    CheckTrue(V);
    CheckTrue(Args.TryGetBool('t3', V));
    CheckTrue(V);

    // False 值
    CheckTrue(Args.TryGetBool('f1', V));
    CheckFalse(V);
    CheckTrue(Args.TryGetBool('f2', V));
    CheckFalse(V);
    CheckTrue(Args.TryGetBool('f3', V));
    CheckFalse(V);

    // 无效值
    CheckFalse(Args.TryGetBool('invalid', V), 'Invalid bool should return False');
    CheckFalse(Args.TryGetBool('missing', V), 'Missing key should return False');
  finally
    Args.Free;
  end;
end;

{ Default 风格 API 测试 }

procedure TTestCase_ArgsBase.Test_TArgs_GetStringDefault;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--name=test'], ArgsOptionsDefault);
  try
    CheckEquals('test', Args.GetStringDefault('name', 'default'));
    CheckEquals('default', Args.GetStringDefault('missing', 'default'));
    CheckEquals('', Args.GetStringDefault('missing', ''), 'Empty default should work');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetInt64Default;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--count=42', '--invalid=abc'], ArgsOptionsDefault);
  try
    CheckEquals(42, Args.GetInt64Default('count', 0));
    CheckEquals(100, Args.GetInt64Default('missing', 100));
    CheckEquals(0, Args.GetInt64Default('invalid', 0), 'Invalid should return default');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetDoubleDefault;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--rate=0.5', '--invalid=abc'], ArgsOptionsDefault);
  try
    CheckEquals(0.5, Args.GetDoubleDefault('rate', 0.0), 0.00001);
    CheckEquals(1.0, Args.GetDoubleDefault('missing', 1.0), 0.00001);
    CheckEquals(0.0, Args.GetDoubleDefault('invalid', 0.0), 0.00001, 'Invalid should return default');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetBoolDefault;
var
  Args: TArgs;
begin
  Args := TArgs.FromArray(['--enabled=true', '--disabled=false', '--invalid=maybe'], ArgsOptionsDefault);
  try
    CheckTrue(Args.GetBoolDefault('enabled', False));
    CheckFalse(Args.GetBoolDefault('disabled', True));
    CheckTrue(Args.GetBoolDefault('missing', True), 'Missing should return default True');
    CheckFalse(Args.GetBoolDefault('invalid', False), 'Invalid should return default False');
  finally
    Args.Free;
  end;
end;

{ GetAll 多值测试 }

procedure TTestCase_ArgsBase.Test_TArgs_GetAll;
var
  Args: TArgs;
  Values: TStringArray;
begin
  Args := TArgs.FromArray(['--include=a', '--include=b', '--include=c', '--other=x'], ArgsOptionsDefault);
  try
    Values := Args.GetAll('include');
    CheckEquals(3, Length(Values), 'Should have 3 include values');
    CheckEquals('a', Values[0]);
    CheckEquals('b', Values[1]);
    CheckEquals('c', Values[2]);

    Values := Args.GetAll('other');
    CheckEquals(1, Length(Values), 'Should have 1 other value');
    CheckEquals('x', Values[0]);
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_TArgs_GetAll_Empty;
var
  Args: TArgs;
  Values: TStringArray;
begin
  Args := TArgs.FromArray(['--name=test'], ArgsOptionsDefault);
  try
    Values := Args.GetAll('missing');
    CheckEquals(0, Length(Values), 'Missing key should return empty array');
  finally
    Args.Free;
  end;
end;

{ Items 迭代测试 }

procedure TTestCase_ArgsBase.Test_TArgsContext_ItemsCount;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--verbose', '--name=test', 'file.txt'], Opts, Ctx);

  CheckEquals(3, Ctx.ItemsCount, 'Should have 3 items total');
end;

procedure TTestCase_ArgsBase.Test_TArgsContext_ItemAt;
var
  Ctx: TArgsContext;
  Opts: TArgsOptions;
  Item: TArgItem;
begin
  Opts := ArgsOptionsDefault;
  ParseArgs(['--verbose', '--name=test', 'file.txt'], Opts, Ctx);

  Item := Ctx.ItemAt(0);
  CheckEquals('verbose', Item.Name);
  CheckFalse(Item.HasValue);
  CheckEquals(Ord(akOptionLong), Ord(Item.Kind));

  Item := Ctx.ItemAt(1);
  CheckEquals('name', Item.Name);
  CheckEquals('test', Item.Value);
  CheckTrue(Item.HasValue);
  CheckEquals(Ord(akOptionLong), Ord(Item.Kind));

  Item := Ctx.ItemAt(2);
  CheckEquals('', Item.Name, 'Positional has no name');
  CheckEquals('file.txt', Item.Value);
  CheckEquals(Ord(akArg), Ord(Item.Kind));
end;

{ 迭代器测试 }

procedure TTestCase_ArgsBase.Test_TArgs_Enumerator;
var
  Args: TArgs;
  Enum: TArgsEnumerator;
  Count: Integer;
begin
  Args := TArgs.FromArray(['--verbose', '--name=test', 'file.txt'], ArgsOptionsDefault);
  try
    Count := 0;
    Enum := TArgsEnumerator(Args.GetEnumerator);
    try
      while Enum.MoveNext do
        Inc(Count);
    finally
      Enum.Free;
    end;
    CheckEquals(3, Count, 'Enumerator should iterate 3 items');
  finally
    Args.Free;
  end;
end;

{ 浮点数区域设置无关性测试 }

procedure TTestCase_ArgsBase.Test_Float_LocaleInvariant;
var
  Args: TArgs;
  V: Double;
begin
  // 确保浮点数解析使用 '.' 作为小数分隔符，不受系统区域设置影响
  Args := TArgs.FromArray(['--value=3.14'], ArgsOptionsDefault);
  try
    CheckTrue(Args.TryGetDouble('value', V));
    CheckEquals(3.14, V, 0.001, 'Should parse 3.14 correctly regardless of locale');
  finally
    Args.Free;
  end;
end;

{ 键规范化测试 }

procedure TTestCase_ArgsBase.Test_KeyNormalization_Underscore;
var
  Args: TArgs;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  Args := TArgs.FromArray(['--foo_bar=test', '--baz_qux=value'], Opts);
  try
    // 下划线应被规范化为点
    CheckEquals('test', Args.GetStringDefault('foo.bar', ''), 'foo_bar should match foo.bar');
    CheckEquals('value', Args.GetStringDefault('baz.qux', ''), 'baz_qux should match baz.qux');
  finally
    Args.Free;
  end;
end;

procedure TTestCase_ArgsBase.Test_KeyNormalization_Hyphen;
var
  Args: TArgs;
  Opts: TArgsOptions;
begin
  Opts := ArgsOptionsDefault;
  Args := TArgs.FromArray(['--foo-bar=test', '--baz-qux=value'], Opts);
  try
    // 连字符应被规范化为点
    CheckEquals('test', Args.GetStringDefault('foo.bar', ''), 'foo-bar should match foo.bar');
    CheckEquals('value', Args.GetStringDefault('baz.qux', ''), 'baz-qux should match baz.qux');
  finally
    Args.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ArgsBase);
end.
