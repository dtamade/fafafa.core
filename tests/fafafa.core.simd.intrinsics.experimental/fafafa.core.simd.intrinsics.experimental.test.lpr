program fafafa.core.simd.intrinsics.experimental.test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, consoletestrunner, testregistry,
  fafafa.core.simd.intrinsics.experimental.testcase
  {$IFDEF FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS}
  ,fafafa.core.simd.intrinsics.experimental.sse2facade.testcase
  {$ENDIF}
  ;

var
  LApplication: TTestRunner;

begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'fafafa.core.simd.intrinsics.experimental tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
