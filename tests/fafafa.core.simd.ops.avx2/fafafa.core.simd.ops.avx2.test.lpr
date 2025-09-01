program fafafa.core.simd.ops.avx2.test;

{$I ../../src/fafafa.core.settings.inc}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, fpcunit, testreport, testregistry,
  fafafa.core.simd.ops.avx2.testcase;

var
  App: TTestRunner;
begin
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'fafafa.core.simd.ops.avx2 单元测试';
    App.Run;
  finally
    App.Free;
  end;
end.
