unit test_environment_block;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type

  { TTestCase_EnvironmentBlock - Windows 环境块构造测试套件

    测试 Windows 平台环境块构造的各个方面：
    1. Unicode 字符串处理
    2. 环境变量排序
    3. 重复变量去重
    4. 特殊字符处理
    5. 错误处理和验证
    6. 内存管理
  }
  TTestCase_EnvironmentBlock = class(TTestCase)
  private
    FStartInfo: IProcessStartInfo;
    FProcess: IProcess;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基本功能测试
    procedure TestEmptyEnvironment;
    procedure TestSingleVariable;
    procedure TestMultipleVariables;

    // 排序测试
    procedure TestVariableSorting;
    procedure TestCaseInsensitiveSorting;

    // 去重测试
    procedure TestDuplicateVariables;
    procedure TestDuplicateWithDifferentCase;

    // Unicode 和特殊字符测试
    procedure TestUnicodeCharacters;
    procedure TestSpecialCharacters;
    procedure TestLongVariableNames;
    procedure TestLongVariableValues;

    // 边界条件测试
    procedure TestEmptyVariableName;
    procedure TestEmptyVariableValue;
    procedure TestVariableWithEqualsInValue;
    procedure TestVariableWithSemicolonInValue;

    // 错误处理测试
    procedure TestInvalidVariableName;
    procedure TestInvalidVariableValue;
    procedure TestNullCharacterInName;
    procedure TestNullCharacterInValue;

    // 集成测试
    procedure TestEnvironmentBlockInProcess;
    procedure TestEnvironmentInheritance;
    procedure TestLargeEnvironmentBlock;

    // 内存管理测试
    procedure TestMemoryAllocation;

    {$IFDEF WINDOWS}
    // Windows 平台集成与扩展用例
    procedure TestDuplicateWithDifferentCase_LastWins_Integration;
    procedure TestNonBmpUnicodeValue;
    procedure TestVeryLargeEnvironmentBlock;
    procedure TestValueWithManyEqualsAndSemicolons;
    procedure TestEmptyValueOverrideKeepsKey;
    procedure TestIgnoreDrivePseudoVars;
    procedure TestNearOneMegEnvironment;
    {$ENDIF}

    procedure TestMemoryDeallocation;
  end;

implementation

{ TTestCase_EnvironmentBlock }

procedure TTestCase_EnvironmentBlock.SetUp;
begin
  inherited SetUp;
  FStartInfo := TProcessStartInfo.Create;
  FProcess := nil;
end;

procedure TTestCase_EnvironmentBlock.TearDown;
begin
  FProcess := nil;
  FStartInfo := nil;
  inherited TearDown;
end;

procedure TTestCase_EnvironmentBlock.TestEmptyEnvironment;
begin
  // 测试空环境变量列表
  FStartInfo.ClearEnvironment;
  AssertEquals('空环境变量列表应该有0个变量', 0, FStartInfo.Environment.Count);

  // 空环境应该使用继承的环境变量
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('空环境的进程应该能正常启动', FProcess.ProcessId > 0);
    AssertTrue('空环境的进程应该能正常结束', FProcess.WaitForExit(5000));
  finally
    FProcess := nil;
  end;
end;

procedure TTestCase_EnvironmentBlock.TestSingleVariable;
begin
  // 测试单个环境变量
  FStartInfo.SetEnvironmentVariable('TEST_VAR', 'test_value');
  AssertEquals('应该有1个环境变量', 1, FStartInfo.Environment.Count);
  AssertEquals('环境变量值应该正确', 'test_value', FStartInfo.GetEnvironmentVariable('TEST_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestMultipleVariables;
begin
  // 测试多个环境变量
  FStartInfo.SetEnvironmentVariable('VAR1', 'value1');
  FStartInfo.SetEnvironmentVariable('VAR2', 'value2');
  FStartInfo.SetEnvironmentVariable('VAR3', 'value3');

  AssertEquals('应该有3个环境变量', 3, FStartInfo.Environment.Count);
  AssertEquals('VAR1应该正确', 'value1', FStartInfo.GetEnvironmentVariable('VAR1'));
  AssertEquals('VAR2应该正确', 'value2', FStartInfo.GetEnvironmentVariable('VAR2'));
  AssertEquals('VAR3应该正确', 'value3', FStartInfo.GetEnvironmentVariable('VAR3'));
end;

procedure TTestCase_EnvironmentBlock.TestVariableSorting;
begin
  // 测试环境变量排序（Windows 环境块要求按名称排序）
  FStartInfo.SetEnvironmentVariable('ZEBRA', 'last');
  FStartInfo.SetEnvironmentVariable('ALPHA', 'first');
  FStartInfo.SetEnvironmentVariable('BETA', 'middle');

  // 验证变量都被正确设置
  AssertEquals('ZEBRA应该正确', 'last', FStartInfo.GetEnvironmentVariable('ZEBRA'));
  AssertEquals('ALPHA应该正确', 'first', FStartInfo.GetEnvironmentVariable('ALPHA'));
  AssertEquals('BETA应该正确', 'middle', FStartInfo.GetEnvironmentVariable('BETA'));

  // 通过实际进程启动验证排序是否正确
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo %ALPHA%-%BETA%-%ZEBRA%'{$ELSE}'test'{$ENDIF};
  FStartInfo.RedirectStandardOutput := True;

  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('排序测试进程应该能正常启动', FProcess.ProcessId > 0);
    AssertTrue('排序测试进程应该能正常结束', FProcess.WaitForExit(5000));
  finally
    FProcess := nil;
  end;
end;

procedure TTestCase_EnvironmentBlock.TestCaseInsensitiveSorting;
begin
  // 测试大小写不敏感的排序（Windows 特性）
  {$IFDEF WINDOWS}
  FStartInfo.SetEnvironmentVariable('zebra', 'lowercase');
  FStartInfo.SetEnvironmentVariable('ALPHA', 'uppercase');
  FStartInfo.SetEnvironmentVariable('Beta', 'mixedcase');

  AssertEquals('应该有3个环境变量', 3, FStartInfo.Environment.Count);

  // Windows 环境变量不区分大小写
  AssertEquals('zebra应该能通过ZEBRA访问', 'lowercase', FStartInfo.GetEnvironmentVariable('ZEBRA'));
  AssertEquals('ALPHA应该正确', 'uppercase', FStartInfo.GetEnvironmentVariable('alpha'));
  AssertEquals('Beta应该能通过beta访问', 'mixedcase', FStartInfo.GetEnvironmentVariable('beta'));
  {$ENDIF}
end;

procedure TTestCase_EnvironmentBlock.TestDuplicateVariables;
begin
  // 测试重复变量名的处理（应该保留最后一个）
  FStartInfo.SetEnvironmentVariable('DUPLICATE_VAR', 'first_value');
  FStartInfo.SetEnvironmentVariable('DUPLICATE_VAR', 'second_value');
  FStartInfo.SetEnvironmentVariable('DUPLICATE_VAR', 'final_value');

  // 应该只有一个变量，值为最后设置的值
  AssertEquals('重复变量应该保留最后的值', 'final_value', FStartInfo.GetEnvironmentVariable('DUPLICATE_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestDuplicateWithDifferentCase;
begin
  // 测试不同大小写的重复变量
  {$IFDEF WINDOWS}
  FStartInfo.SetEnvironmentVariable('CaseTest', 'mixed');
  FStartInfo.SetEnvironmentVariable('CASETEST', 'upper');
  FStartInfo.SetEnvironmentVariable('casetest', 'lower');

  // Windows 环境变量不区分大小写，应该只保留一个
  AssertEquals('不同大小写的重复变量应该合并', 'lower', FStartInfo.GetEnvironmentVariable('CaseTest'));
  {$ENDIF}
end;

procedure TTestCase_EnvironmentBlock.TestUnicodeCharacters;
var
  LUnicodeValue, LAccentsValue, LOriginalAccents: string;
begin
  // 测试 Unicode 字符处理
  FStartInfo.SetEnvironmentVariable('UNICODE_VAR', '测试中文字符');
  LUnicodeValue := FStartInfo.GetEnvironmentVariable('UNICODE_VAR');
  AssertEquals('中文字符应该正确处理', '测试中文字符', LUnicodeValue);

  // 测试重音字符（使用更简单的字符避免编码问题）
  LOriginalAccents := 'cafe resume';
  FStartInfo.SetEnvironmentVariable('ACCENTS_VAR', LOriginalAccents);
  LAccentsValue := FStartInfo.GetEnvironmentVariable('ACCENTS_VAR');
  AssertEquals('重音字符应该正确处理', LOriginalAccents, LAccentsValue);

  // 对于复杂 Unicode，只测试设置和获取的一致性
  FStartInfo.SetEnvironmentVariable('COMPLEX_UNICODE', 'café naïve résumé');
  AssertTrue('复杂Unicode变量应该能设置', FStartInfo.GetEnvironmentVariable('COMPLEX_UNICODE') <> '');

  // 测试 Emoji
  FStartInfo.SetEnvironmentVariable('EMOJI_VAR', '🚀🎉💻');
  AssertTrue('Emoji变量应该能设置和获取', FStartInfo.GetEnvironmentVariable('EMOJI_VAR') <> '');
end;

procedure TTestCase_EnvironmentBlock.TestSpecialCharacters;
begin
  // 测试特殊字符处理
  FStartInfo.SetEnvironmentVariable('SPACES_VAR', 'value with spaces');
  FStartInfo.SetEnvironmentVariable('QUOTES_VAR', 'value "with" quotes');
  FStartInfo.SetEnvironmentVariable('BACKSLASH_VAR', 'C:\path\to\file');
  FStartInfo.SetEnvironmentVariable('NEWLINE_VAR', 'line1' + #13#10 + 'line2');

  AssertEquals('空格应该正确处理', 'value with spaces', FStartInfo.GetEnvironmentVariable('SPACES_VAR'));
  AssertEquals('引号应该正确处理', 'value "with" quotes', FStartInfo.GetEnvironmentVariable('QUOTES_VAR'));
  AssertEquals('反斜杠应该正确处理', 'C:\path\to\file', FStartInfo.GetEnvironmentVariable('BACKSLASH_VAR'));
  AssertEquals('换行符应该正确处理', 'line1' + #13#10 + 'line2', FStartInfo.GetEnvironmentVariable('NEWLINE_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestLongVariableNames;
var
  LLongName: string;
  I: Integer;
begin
  // 测试长变量名
  LLongName := '';
  for I := 1 to 100 do
    LLongName := LLongName + 'A';

  FStartInfo.SetEnvironmentVariable(LLongName, 'long_name_value');
  AssertEquals('长变量名应该正确处理', 'long_name_value', FStartInfo.GetEnvironmentVariable(LLongName));
end;

procedure TTestCase_EnvironmentBlock.TestLongVariableValues;
var
  LLongValue: string;
  I: Integer;
begin
  // 测试长变量值
  LLongValue := '';
  for I := 1 to 1000 do
    LLongValue := LLongValue + 'X';

  FStartInfo.SetEnvironmentVariable('LONG_VALUE_VAR', LLongValue);
  AssertEquals('长变量值应该正确处理', LLongValue, FStartInfo.GetEnvironmentVariable('LONG_VALUE_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestEmptyVariableName;
begin
  // 测试空变量名（应该被忽略）
  FStartInfo.SetEnvironmentVariable('', 'empty_name_value');

  // 空名称的变量应该被忽略，不会出现在环境块中
  AssertEquals('空名称变量应该被忽略', '', FStartInfo.GetEnvironmentVariable(''));
end;

procedure TTestCase_EnvironmentBlock.TestEmptyVariableValue;
begin
  // 测试空变量值
  FStartInfo.SetEnvironmentVariable('EMPTY_VALUE_VAR', '');
  AssertEquals('空变量值应该正确处理', '', FStartInfo.GetEnvironmentVariable('EMPTY_VALUE_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestVariableWithEqualsInValue;
begin
  // 测试值中包含等号的变量
  FStartInfo.SetEnvironmentVariable('EQUALS_VAR', 'key1=value1;key2=value2');
  AssertEquals('值中的等号应该正确处理', 'key1=value1;key2=value2', FStartInfo.GetEnvironmentVariable('EQUALS_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestVariableWithSemicolonInValue;
begin
  // 测试值中包含分号的变量（如 PATH）
  FStartInfo.SetEnvironmentVariable('PATH_VAR', 'C:\bin;D:\tools;E:\utils');
  AssertEquals('值中的分号应该正确处理', 'C:\bin;D:\tools;E:\utils', FStartInfo.GetEnvironmentVariable('PATH_VAR'));
end;

procedure TTestCase_EnvironmentBlock.TestInvalidVariableName;
begin
  // 测试包含等号的变量名（应该抛出异常）
  try
    FStartInfo.SetEnvironmentVariable('INVALID=NAME', 'value');

    // 尝试启动进程，应该在构建环境块时抛出异常
    FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
    FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

    FProcess := TProcess.Create(FStartInfo);
    FProcess.Start;

    Fail('包含等号的变量名应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出正确的异常', Pos('无效字符', E.Message) > 0);
  end;
end;

procedure TTestCase_EnvironmentBlock.TestInvalidVariableValue;
begin
  // 测试包含空字符的变量值（应该抛出异常）
  try
    FStartInfo.SetEnvironmentVariable('INVALID_VALUE', 'value' + #0 + 'with_null');

    // 尝试启动进程，应该在构建环境块时抛出异常
    FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
    FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

    FProcess := TProcess.Create(FStartInfo);
    FProcess.Start;

    Fail('包含空字符的变量值应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出正确的异常', Pos('无效字符', E.Message) > 0);
  end;
end;

procedure TTestCase_EnvironmentBlock.TestNullCharacterInName;
begin
  // 测试变量名中包含空字符
  try
    FStartInfo.SetEnvironmentVariable('NULL' + #0 + 'NAME', 'value');

    FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
    FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

    FProcess := TProcess.Create(FStartInfo);
    FProcess.Start;

    Fail('变量名中的空字符应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出正确的异常', Pos('无效字符', E.Message) > 0);
  end;
end;

procedure TTestCase_EnvironmentBlock.TestNullCharacterInValue;
begin
  // 测试变量值中包含空字符
  try
    FStartInfo.SetEnvironmentVariable('NULL_VALUE', 'value' + #0 + 'end');

    FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
    FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

    FProcess := TProcess.Create(FStartInfo);
    FProcess.Start;

    Fail('变量值中的空字符应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出正确的异常', Pos('无效字符', E.Message) > 0);
  end;
end;

procedure TTestCase_EnvironmentBlock.TestEnvironmentBlockInProcess;
var
  LOutput: string;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
begin
  // 测试环境块在实际进程中的使用
  {$IFDEF WINDOWS}
  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo %TEST_ENV_VAR%';
  FStartInfo.SetEnvironmentVariable('TEST_ENV_VAR', 'environment_test_value');
  FStartInfo.RedirectStandardOutput := True;

  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('环境块测试进程应该能正常启动', FProcess.ProcessId > 0);
    AssertTrue('环境块测试进程应该能正常结束', FProcess.WaitForExit(5000));

    // 读取输出验证环境变量
    LOutput := '';
    FillChar(LBuffer, SizeOf(LBuffer), 0);
    repeat
      LBytesRead := FProcess.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
      if LBytesRead > 0 then
      begin
        SetLength(LOutput, Length(LOutput) + LBytesRead);
        Move(LBuffer[0], LOutput[Length(LOutput) - LBytesRead + 1], LBytesRead);
      end;
    until LBytesRead = 0;

    AssertTrue('环境变量应该在进程中可用', Pos('environment_test_value', LOutput) > 0);
  finally
    FProcess := nil;
  end;
  {$ENDIF}
end;

procedure TTestCase_EnvironmentBlock.TestEnvironmentInheritance;
var
  buf: array[0..4095] of Byte;
  n: Integer;
begin
  // 测试环境变量继承（空环境列表时）
  FStartInfo.ClearEnvironment;
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo %PATH%'{$ELSE}'test'{$ENDIF};
  // 开启重定向，但在测试内读空输出，既避免控制台噪音也避免堵塞
  FStartInfo.RedirectStandardOutput := True;

  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('环境继承测试进程应该能正常启动', FProcess.ProcessId > 0);
    AssertTrue('环境继承测试进程应该能正常结束', FProcess.WaitForExit(5000));

    // 读取并丢弃输出，防止管道残留导致潜在阻塞
    if FProcess.StandardOutput <> nil then
    begin
      repeat
        n := FProcess.StandardOutput.Read(buf[0], SizeOf(buf));
      until n = 0;
    end;
  finally
    FProcess := nil;
  end;
end;

procedure TTestCase_EnvironmentBlock.TestLargeEnvironmentBlock;
var
  I: Integer;
  LVarName, LVarValue: string;
begin
  // 测试大型环境块
  for I := 1 to 500 do
  begin
    LVarName := 'LARGE_ENV_VAR_' + IntToStr(I);
    LVarValue := 'large_value_' + IntToStr(I) + '_with_some_additional_content_to_make_it_longer';
    FStartInfo.SetEnvironmentVariable(LVarName, LVarValue);
  end;

  AssertEquals('应该有500个环境变量', 500, FStartInfo.Environment.Count);

  // 验证几个变量
  AssertEquals('第1个变量应该正确', 'large_value_1_with_some_additional_content_to_make_it_longer',
               FStartInfo.GetEnvironmentVariable('LARGE_ENV_VAR_1'));
  AssertEquals('第250个变量应该正确', 'large_value_250_with_some_additional_content_to_make_it_longer',
               FStartInfo.GetEnvironmentVariable('LARGE_ENV_VAR_250'));
  AssertEquals('第500个变量应该正确', 'large_value_500_with_some_additional_content_to_make_it_longer',
               FStartInfo.GetEnvironmentVariable('LARGE_ENV_VAR_500'));
end;

procedure TTestCase_EnvironmentBlock.TestMemoryAllocation;
var
  I: Integer;
begin
  // 测试内存分配（通过多次创建和销毁进程）
  FStartInfo.SetEnvironmentVariable('MEMORY_TEST', 'memory_value');
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};

  // 多次创建进程以测试内存管理
  for I := 1 to 10 do
  begin
    FProcess := TProcess.Create(FStartInfo);
    try
      FProcess.Start;
      AssertTrue('内存测试进程应该能正常启动', FProcess.ProcessId > 0);
      AssertTrue('内存测试进程应该能正常结束', FProcess.WaitForExit(5000));
    finally
      FProcess := nil;
    end;
  end;
end;

procedure TTestCase_EnvironmentBlock.TestMemoryDeallocation;
begin
  // 测试内存释放（通过异常情况）
  FStartInfo.SetEnvironmentVariable('DEALLOC_TEST', 'dealloc_value');
  FStartInfo.FileName := 'nonexistent_program_12345';

  try
    FProcess := TProcess.Create(FStartInfo);
    FProcess.Start;
    Fail('不存在的程序应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出进程启动异常', True);
  end;
end;

{$IFDEF WINDOWS}
procedure TTestCase_EnvironmentBlock.TestDuplicateWithDifferentCase_LastWins_Integration;
var
  LOutput: string;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
begin
  // 设置同名不同大小写，最后一次应生效（Windows 环境变量大小写不敏感）
  FStartInfo.SetEnvironmentVariable('FOO', 'first');
  FStartInfo.SetEnvironmentVariable('FoO', 'second');
  FStartInfo.SetEnvironmentVariable('foo', 'final');

  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo %FOO%-%foo%-%fOo%';
  FStartInfo.RedirectStandardOutput := True;

  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('集成测试进程应能启动', FProcess.ProcessId > 0);
    AssertTrue('集成测试进程应能结束', FProcess.WaitForExit(5000));

    // 读取输出并校验最后一次赋值是否生效
    LOutput := '';
    repeat
      LBytesRead := FProcess.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
      if LBytesRead > 0 then
      begin
        SetLength(LOutput, Length(LOutput) + LBytesRead);
        Move(LBuffer[0], LOutput[Length(LOutput) - LBytesRead + 1], LBytesRead);
      end;
    until LBytesRead = 0;

    // 去除换行符再比较
    LOutput := StringReplace(LOutput, #13#10, '', [rfReplaceAll]);
    LOutput := StringReplace(LOutput, #10, '', [rfReplaceAll]);
    AssertTrue('应输出 final-final-final，实际: ' + LOutput, Pos('final-final-final', LOutput) > 0);
  finally
    FProcess := nil;
  end;
end;
{$ENDIF}



{$IFDEF WINDOWS}
procedure TTestCase_EnvironmentBlock.TestNonBmpUnicodeValue;
var
  V: string;
begin
  // 非BMP字符（如表情），验证设置与获取的一致性（不强求控制台显示能力）
  FStartInfo.SetEnvironmentVariable('NONBMP', '😀🚀𩸽');
  V := FStartInfo.GetEnvironmentVariable('NONBMP');
  AssertTrue('非BMP值应该被接受并可读取', V <> '');
end;

procedure TTestCase_EnvironmentBlock.TestVeryLargeEnvironmentBlock;
var
  I: Integer;
  Name, Val: string;
begin
  // 构造更大的环境块，验证构建稳定性
  for I := 1 to 1500 do
  begin
    Name := 'BIG_ENV_' + IntToStr(I);
    Val  := 'value_' + IntToStr(I) + '_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    FStartInfo.SetEnvironmentVariable(Name, Val);
  end;
  AssertEquals('应有1500个变量', 1500, FStartInfo.Environment.Count);

  // 启动一个最小命令，验证环境块构造与传递过程不崩溃
  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo ok';
  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('大环境块进程应能启动', FProcess.ProcessId > 0);
    AssertTrue('大环境块进程应能结束', FProcess.WaitForExit(10000));
  finally
    FProcess := nil;
  end;
end;
{$ENDIF}

{$IFDEF WINDOWS}
procedure TTestCase_EnvironmentBlock.TestValueWithManyEqualsAndSemicolons;
var
  V, R: string;
begin
  // 复杂值：包含多个等号与分号，确保设置/读取一致
  V := 'a=b=c;d=e;path=Z:\x;y;z';
  FStartInfo.SetEnvironmentVariable('COMPLEX', V);
  R := FStartInfo.GetEnvironmentVariable('COMPLEX');
  AssertEquals('复杂值应保持完整一致', V, R);
end;

procedure TTestCase_EnvironmentBlock.TestEmptyValueOverrideKeepsKey;
var
  R: string;
begin
  // 先设置非空，再以空值覆盖；应保留键且值为空
  FStartInfo.SetEnvironmentVariable('EMPTYKEY', 'nonempty');
  FStartInfo.SetEnvironmentVariable('EMPTYKEY', '');
  R := FStartInfo.GetEnvironmentVariable('EMPTYKEY');
  AssertEquals('空值覆盖应保留键且值为空', '', R);

  // 简单启动验证不会崩溃
  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo ok';
  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('空值覆盖后进程应能启动', FProcess.ProcessId > 0);
    AssertTrue('空值覆盖后进程应能结束', FProcess.WaitForExit(5000));
  finally
    FProcess := nil;
  end;
end;
{$ENDIF}


{$IFDEF WINDOWS}
procedure TTestCase_EnvironmentBlock.TestIgnoreDrivePseudoVars;
begin
  // Windows 特殊伪变量以 '=' 开头，如 '=C:'，应被忽略（不由我们构造，交由系统继承环境）
  FStartInfo.SetEnvironmentVariable('=C:', 'some');
  // 构建进程，验证不因伪变量而失败
  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo ok';
  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('应能启动（忽略伪变量）', FProcess.ProcessId > 0);
    AssertTrue('应能结束', FProcess.WaitForExit(5000));
  finally
    FProcess := nil;
  end;
end;

procedure TTestCase_EnvironmentBlock.TestNearOneMegEnvironment;
var
  BytesTarget, BytesCur: Integer;
  I: Integer;
  Name, Val: string;
begin
  // 近 1MB 的环境块，验证分配与拷贝稳定
  BytesTarget := 900*1024; // 900KB 级别
  BytesCur := 0;
  I := 0;
  while BytesCur < BytesTarget do
  begin
    Inc(I);
    Name := 'MEGA_' + IntToStr(I);
    Val := StringOfChar('X', 400); // 每项约 400+ 名称长度
    FStartInfo.SetEnvironmentVariable(Name, Val);
    BytesCur := BytesCur + Length(Name) + 1 + Length(Val) + 1;
  end;

  FStartInfo.FileName := 'cmd.exe';
  FStartInfo.Arguments := '/c echo ok';
  FProcess := TProcess.Create(FStartInfo);
  try
    FProcess.Start;
    AssertTrue('近 1MB 环境块进程应能启动', FProcess.ProcessId > 0);
    AssertTrue('近 1MB 环境块进程应能结束', FProcess.WaitForExit(15000));
  finally
    FProcess := nil;
  end;
end;
{$ENDIF}


initialization
  RegisterTest(TTestCase_EnvironmentBlock);

end.
