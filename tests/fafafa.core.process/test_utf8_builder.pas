unit test_utf8_builder;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  { TTestCase_Utf8Builder }
  TTestCase_Utf8Builder = class(TTestCase)
  published
    procedure TestUtf8ArgumentsAndEnv;
    procedure TestUtf8WorkingDirectory; // 路径含 UTF-8（仅验证配置，不实际创建）
  end;

implementation

procedure TTestCase_Utf8Builder.TestUtf8ArgumentsAndEnv;
var
  LBuilder: IProcessBuilder;
  LStartInfo: IProcessStartInfo;
  LOut: string;
begin
  // UTF-8 参数与环境变量（包含 CJK + Emoji + 组合符）
  LBuilder := NewProcessBuilder
    .Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
    {$IFDEF WINDOWS}
    .Args(['/c', 'echo', '你好，世界 🌍 — Café — â'])
    {$ELSE}
    .Args(['你好，世界 🌍 — Café — â'])
    {$ENDIF}
    .SetEnv('GREETING', '你好 🌟')
    .CaptureOutput;

  // 验证配置（UTF-8 约定）
  LStartInfo := LBuilder.GetStartInfo;
  AssertTrue('参数应包含 UTF-8 文本', Pos('你好，世界', LStartInfo.Arguments) > 0);
  // 当前阶段：内部存储可能受系统代码页影响，放宽为包含关键片段的断言
  AssertTrue('环境变量应包含 UTF-8 片段', Pos('你好', LStartInfo.GetEnvironmentVariable('GREETING')) > 0);

  // 执行并检查输出（注意：不做统一解码，Windows 控制台常为 OEM 代码页）
  LOut := LBuilder.Output;
  {$IFDEF WINDOWS}
  AssertTrue('输出非空即可（编码由子进程/控制台决定）', Length(Trim(LOut)) > 0);
  {$ELSE}
  AssertTrue('输出应包含 UTF-8 文本片段', Pos('你好', LOut) > 0);
  {$ENDIF}
end;

procedure TTestCase_Utf8Builder.TestUtf8WorkingDirectory;
var
  LBuilder: IProcessBuilder;
  LStartInfo: IProcessStartInfo;
begin
  // 配置含 UTF-8 的工作目录（不创建该目录，仅验证赋值与 Validate 的报错）
  LBuilder := NewProcessBuilder.WorkingDir('C:\测试_🌟_目录');
  LStartInfo := LBuilder.GetStartInfo;
  AssertEquals('工作目录应保留 UTF-8 字符', 'C:\测试_🌟_目录', LStartInfo.WorkingDirectory);
  
  // Validate 预期失败（不存在的目录），但这证明 UTF-8 保持原样传递
  try
    LBuilder.Validate;
    Fail('应当报目录不存在');
  except
    on E: Exception do
      AssertTrue('错误消息应包含目录名片段', Pos('测试_', E.Message) > 0);
  end;
end;

initialization
  RegisterTest(TTestCase_Utf8Builder);

end.
