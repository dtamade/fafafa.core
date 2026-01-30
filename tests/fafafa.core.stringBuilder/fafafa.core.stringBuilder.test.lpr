{$CODEPAGE UTF8}
program fafafa.core.stringBuilder.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.base,
  fafafa.core.bytes,
  fafafa.core.stringBuilder,
  fafafa.core.stringBuilder.testcase;

begin
  WriteLn('=== fafafa.core.stringBuilder 测试套件 ===');
  WriteLn('覆盖：IStringBuilder 原样追加/长度/导出（编码无关）');
  WriteLn;

  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

