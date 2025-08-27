{$CODEPAGE UTF8}
program fafafa.core.yaml.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.base,
  fafafa.core.yaml,
  fafafa.core.yaml.testcase,
  fafafa.core.yaml.tokenizer.testcase,
  fafafa.core.yaml.diagnostics.test,
  fafafa.core.yaml.diagnostics.extras.test,
  fafafa.core.yaml.limits.test,
  fafafa.core.yaml.limits_nonstrict.test;

begin
  WriteLn('=== fafafa.core.yaml 测试套件 ===');
  WriteLn('测试 libfyaml 移植的基本功能');
  WriteLn;

  // FPCUnit 控制台运行器
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.
