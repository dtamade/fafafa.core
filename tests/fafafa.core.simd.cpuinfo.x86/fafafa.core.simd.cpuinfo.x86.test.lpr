program fafafa.core.simd.cpuinfo.x86.test;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils, fpcunit, testreport, testregistry,
  fafafa.core.simd.cpuinfo.x86.testcase;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.simd.cpuinfo.x86 单元测试';
    Application.Run;
  finally
    Application.Free;
  end;
end.
