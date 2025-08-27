{$CODEPAGE UTF8}
program fafafa.core.bytes.buf.test;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.bytes.buf,
  fafafa.core.bytes.buf.testcase;

begin
  WriteLn('=== fafafa.core.bytes.buf 测试套件 ===');
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

