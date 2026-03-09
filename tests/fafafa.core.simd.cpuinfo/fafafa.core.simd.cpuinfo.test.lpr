program fafafa_core_simd_cpuinfo_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, fpcunit, consoletestrunner, testregistry,
  fafafa.core.simd.cpuinfo.testcase,
  fafafa.core.simd.cpuinfo.lazy.testcase;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.simd.cpuinfo 单元测试';
    Application.Run;
  finally
    Application.Free;
  end;
end.
