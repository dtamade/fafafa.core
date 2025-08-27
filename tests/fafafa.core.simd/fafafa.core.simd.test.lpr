{$CODEPAGE UTF8}
program fafafa_core_simd_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.simd.testcase,
  fafafa.core.simd.search.testcase,
  fafafa.core.simd.text.testcase,
  fafafa.core.simd.bit.testcase,
  fafafa.core.simd.memfindbyte.testcase;

begin
  // FPCUnit 控制台运行器
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

