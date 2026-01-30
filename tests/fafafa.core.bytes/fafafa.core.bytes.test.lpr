{$CODEPAGE UTF8}
program fafafa.core.bytes.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.base,
  fafafa.core.bytes,
  fafafa.core.bytes.testcase,
  test_peek_contract;

begin
  WriteLn('=== fafafa.core.bytes 测试套件 ===');
  WriteLn('覆盖：Hex/切片拼接/清零/端序读写/BytesBuilder');
  WriteLn;

  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

