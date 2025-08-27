program tests_collections_base;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  consoletestrunner,
  fafafa.core.collection.base.testcase;

var
  LRunner: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.base 单元测试');
  WriteLn('========================================');
  WriteLn;

  LRunner := TTestRunner.Create(nil);
  try
    LRunner.Initialize;
    LRunner.Title := 'Collections Base Tests';
    LRunner.Run;
  finally
    LRunner.Free;
  end;
end.

