{$CODEPAGE UTF8}
program fafafa_core_collections_vec_tests;

{$mode objfpc}{$H+}

uses
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.collections.vec.testcase;

begin
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
  // 确保 --list 模式无 heaptrc 调用栈
  testregistry.GetTestRegistry.Free;
end.

